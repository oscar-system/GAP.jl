#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

module Setup

using Pkg: GitTools
using ..GAP: GAP
import GAP_jll
import GAP_pkg_juliainterface_jll
import FileWatching: Pidfile

export create_gap_sh

#############################################################################
#
# Set up a GAP root that is only used for building GAP packages
#
# For this we read the sysinfo.gap bundled with GAP_jll and then modify it
# to be usable on this computer
#
#############################################################################

const _gaproot_for_building = Ref{String}()

function gaproot_for_building()
    if !isassigned(_gaproot_for_building)
        # first time we call this in a session
        _gaproot_for_building[] = mktempdir()
    end
    assure_gaproot_for_building(_gaproot_for_building[])
    return _gaproot_for_building[]
end

function assure_gaproot_for_building(gaproot::String)
    is_already_setup = Pidfile.mkpidlock("$gaproot.lock"; stale_age=10) do
        isdir(gaproot) && isfile(joinpath(gaproot, "sysinfo.gap")) && isfile(joinpath(gaproot, "gac"))
    end # mkpidlock

    is_already_setup && return

    @debug "Set up sysinfo.gap and gac at $(gaproot)"
    create_sysinfo_gap_and_gac(gaproot)
end

function read_sysinfo_gap(fname::String)
    d = Dict{String,String}()
    open(fname) do file
        for ln in eachline(file)
            if length(ln) == 0 || ln[1] == '#'
                continue
            end
            s = split(ln, "="; limit=2)
            length(s) == 2 || continue
            d[s[1]] = strip(s[2], ['"'])
        end
    end
    return d
end

function write_sysinfo_gap(fname::String, sysinfo::Dict{String,String})
    unquoted = Set(["GAParch", "GAP_ABI", "GAP_HPCGAP", "GAP_KERNEL_MAJOR_VERSION", "GAP_KERNEL_MINOR_VERSION", "GAP_OBJEXT"])
    open(fname, "w") do file
        write(file, """
        # This file has been generated by the GAP build system,
        # do not edit manually!
        """)
        for key in sort(collect(keys(sysinfo)))
            if key in unquoted
                str = "$(key)=$(sysinfo[key])"
            else
                str = "$(key)=\"$(sysinfo[key])\""
            end
            write(file, str, "\n")
        end
    end
end


function select_compiler(lang::String, candidates::Vector{String}, extension::String)
    mktempdir() do tmpdir
        cd(tmpdir) do
            tmpfilename = "gapcomptest"
            srcfilename = tmpfilename * extension
            open(srcfilename, "w") do file
                write(file, """
                #include <stdio.h>
                int main(int argc, char **argv) {
                  return 0;
                }
                """)
            end
            for compiler in candidates
                try
                    run(`$(compiler) -o $(tmpfilename) $(srcfilename)`)
                    run(`$(tmpfilename)`)
                    @debug "selected $(compiler) as $(lang) compiler"
                    return compiler
                catch
                    @debug "$(lang) compiler candidate '$(compiler)' not working"
                end
            end
            @debug "Could not locate a working $(lang) compiler"
            return first(candidates)
        end
    end
end

include("julia-config.jl")

function create_sysinfo_gap_and_gac(dir::String)
    mkpath(dir)

    gap_prefix = GAP_jll.find_artifact_dir()

    # load the existing sysinfo.gap
    sysinfo = deepcopy(GAP.sysinfo)

    #
    # now we modify sysinfo for our needs
    #

    # Locate C compiler (for use by GAP packages)
    cc_candidates = [ "cc", "gcc", "clang" ]
    haskey(ENV, "CC") && pushfirst!(cc_candidates, ENV["CC"])
    haskey(ENV, "GAP_CC") && pushfirst!(cc_candidates, ENV["GAP_CC"])
    CC = sysinfo["GAP_CC"] = select_compiler("C", cc_candidates, ".c")

    # Locate  C++ compiler (for use by GAP packages)
    cxx_candidates = [ "c++", "g++", "clang++" ]
    haskey(ENV, "CXX") && pushfirst!(cxx_candidates, ENV["CXX"])
    haskey(ENV, "GAP_CXX") && pushfirst!(cxx_candidates, ENV["GAP_CXX"])
    CXX = sysinfo["GAP_CXX"] = select_compiler("C++", cxx_candidates, ".cc")

    # set include flags
    gap_include = joinpath(gap_prefix, "include", "gap")
    sysinfo["GAP_CPPFLAGS"] = "-I$(gap_include) -DUSE_JULIA_GC=1"

    # set linker flags; since these are meant for use for GAP packages,
    # add the necessary flags to link against libgap
    gap_lib = joinpath(gap_prefix, "lib")
    sysinfo["GAP_LDFLAGS"] = "-L$(gap_lib) -lgap"

    # path to gap & gac (used by some package build systems)
    sysinfo["GAP"] = joinpath(dir, "bin", "gap.sh")
    sysinfo["GAC"] = joinpath(dir, "gac")

    # the following sysinfo entries are intentional left as they are:
    # - GAParch
    # - GAC_CFLAGS
    # - GAC_LDFLAGS
    # - GAP_ABI
    # - GAP_BUILD_VERSION
    # - GAP_CFLAGS
    # - GAP_CXXFLAGS
    # - GAP_HPCGAP
    # - GAP_KERNEL_MAJOR_VERSION
    # - GAP_KERNEL_MINOR_VERSION
    # - GAP_OBJEXT

    # TODO: add a check for any additional entries so we notice when GAP adds
    # stuff and can then decide whether we need to adjust it... E.g.
    # GMP_PREFIX was added in 4.13.0.
    #sysinfo["GMP_PREFIX"] = TODO

    Pidfile.mkpidlock("$dir.lock"; stale_age=10) do
        # create fake sysinfo.gap
        write_sysinfo_gap(joinpath(dir, "sysinfo.gap"), sysinfo)

        # patch gac to load correct sysinfo.gap
        gac = read(joinpath(gap_prefix, "bin", "gac"), String)
        gac = replace(gac, r"^\. \"[^\"]+\"$"m => ". \"$(dir)/sysinfo.gap\"")
        write("$dir/gac", gac)
        chmod("$dir/gac", 0o755)

        # create bin/gap.sh
        create_gap_sh(joinpath(dir, "bin"); use_active_project=true)
    end # mkpidlock

    return sysinfo
end

function build_JuliaInterface()
    @info "Compiling JuliaInterface ..."

    # run code in julia-config.jl to determine compiler and linker flags for Julia;
    # remove apostrophes, they mess up quoting when used in shell code(although
    # they are fine inside of Makefiles); this could cause problems if any
    # paths involve spaces, but then we likely will haves problem in other
    # places; in any case, if anybody ever cares about this, we can work on
    # finding a better solution.
    JULIA_CFLAGS = filter(c -> c != '\'', cflags())
    JULIA_LDFLAGS = filter(c -> c != '\'', ldflags())
    JULIA_LIBS = filter(c -> c != '\'', ldlibs())

    jipath = joinpath(@__DIR__, "..", "pkg", "JuliaInterface")
    gaproot = gaproot_for_building()
    cd(jipath) do
        withenv("CFLAGS" => JULIA_CFLAGS,
                "LDFLAGS" => JULIA_LDFLAGS * " " * JULIA_LIBS) do
            run(pipeline(`./configure $(gaproot)`, stdout="build.log"))
            run(pipeline(`make V=1 -j$(Sys.CPU_THREADS)`, stdout="build.log", append=true))
        end
    end

    return normpath(joinpath(jipath, "bin", GAP.sysinfo["GAParch"]))
end

function locate_JuliaInterface_so()
    # compare the C sources used to build GAP_pkg_juliainterface_jll with bundled copies
    # by comparing tree hashes
    jll = GAP_pkg_juliainterface_jll.find_artifact_dir()
    jll_hash = GitTools.tree_hash(joinpath(jll, "src"))
    bundled = joinpath(@__DIR__, "..", "pkg", "JuliaInterface")
    bundled_hash = GitTools.tree_hash(joinpath(bundled, "src"))
    if jll_hash == bundled_hash && get(ENV, "FORCE_JULIAINTERFACE_COMPILATION", "false") != "true"
        # if the tree hashes match then we can use JuliaInterface.so from the JLL
        @debug "Use JuliaInterface.so from GAP_pkg_juliainterface_jll"
        path = joinpath(jll, "lib", "gap")
    else
        # tree hashes differ: we must compile the bundled sources (or requested re-compilation via ENV)
        path = build_JuliaInterface()
        @debug "Use JuliaInterface.so from $(path)"
    end
    return joinpath(path, "JuliaInterface.so")
end

"""
    create_gap_sh(dstdir::String)

Given a directory path, create three files in that directory:
- a shell script named `gap.sh` which acts like the `gap.sh` shipped with a
  regular GAP installation, but which behind the scenes launches GAP via Julia.
- two TOML files, `Manifest.toml` and `Project.toml`, which are required by
  `gap.sh` to function (they record the precise versions of GAP.jl and other
  Julia packages involved)
"""
function create_gap_sh(dstdir::String; use_active_project::Bool=false)

    mkpath(dstdir)

    if use_active_project
        projectdir = dirname(Base.active_project())

        @debug "Generating gap.sh for active project ..."
    else
        projectdir = dstdir

        @info "Generating custom Julia project ..."
        gaproot_gapjl = abspath(@__DIR__, "..")
        run(`$(Base.julia_cmd()) --startup-file=no --project=$(projectdir) -e "using Pkg; Pkg.develop(PackageSpec(path=\"$(gaproot_gapjl)\"))"`)
        
        @info "Generating gap.sh ..."
    end


    gap_sh_path = joinpath(dstdir, "gap.sh")
    write(gap_sh_path,
        """
        #!/bin/sh
        # This is a a Julia script which also is a valid bash script; if executed by
        # bash, it will execute itself by invoking `julia`. Of course this only works
        # right if `julia` exists in the PATH and is the "correct" julia executable.
        # But you can always instead load this file as if it was a .jl file via any
        # other Julia executable.
        #=
        if [ "\$JULIA_STARTUP_FILE_IN_GAP" = "yes" ]
        then
            READ_STARTUP_FILE="yes"
        else
            READ_STARTUP_FILE="no"
        fi
        exec $(join(Base.julia_cmd().exec, " ")) --startup-file=\$READ_STARTUP_FILE --project=$(projectdir) -i -- "$(gap_sh_path)" "\$@"
        =#

        # pass command line arguments to GAP.jl via a small hack
        ENV["GAP_PRINT_BANNER"] = "true"
        __GAP_ARGS__ = ARGS
        using GAP
        exit(GAP.run_session())
        """,
        )
    chmod(gap_sh_path, 0o755)

end # function

end # module

using .Setup
