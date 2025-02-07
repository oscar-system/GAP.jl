module Setup

using Pkg: GitTools
import GAP_jll
import GAP_lib_jll
import GAP_pkg_juliainterface_jll
import Scratch: @get_scratch!
import Pidfile

# to separate the scratchspaces of different GAP.jl copies and Julia versions
# put the Julia version and the hash of the path to this file into the key
const scratch_key = "gap_$(hash(@__FILE__))-nopkg-$(VERSION.major).$(VERSION.minor)"

gaproot() = @get_scratch!(scratch_key)

#############################################################################
#
# Set up the primary, mutable GAP root
#
# For this we read the sysinfo.gap bundled with GAP_jll and then modify it
# to be usable on this computer
#
#############################################################################

# ensure `link` is a symlink pointing to `target` in a way that is hopefully
# safe against races with other Julia processes doing the exact same thing
function force_symlink(target::AbstractString, link::AbstractString)
    # Do nothing if the symlink already exists and points at the right
    # target
    if Base.islink(link) && Base.readlink(link) == target
      return nothing
    end

    # Otherwise we create the symlink with a temporary name, and then use
    # an atomic `rename` to rename it to the `link` name. The latter
    # unfortunately requires invoking an undocumented function.
    # But all of this together helps avoid a race condition if multiple
    # Julia instances try to create the symlink concurrently
    tmpfile = tempname(dirname(abspath(link)); cleanup=false)
    symlink(target, tmpfile)
    Base.Filesystem.rename(tmpfile, link)
    return nothing
end

function read_sysinfo_gap(dir::String)
    d = Dict{String,String}()
    open(joinpath(dir, "sysinfo.gap")) do file
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

function select_compiler(lang::String, candidates::Vector{String}, extension::String)
    tmpfilename = tempname()
    open(tmpfilename * extension, "w") do file
        write(file, """
        #include <stdio.h>
        int main(int argc, char **argv) {
          return 0;
        }
        """)
    end
    for compiler in candidates
        try
            rm(tmpfilename; force = true)
            run(`$(compiler) -o $(tmpfilename) $(tmpfilename)$(extension)`)
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

include("julia-config.jl")

function regenerate_gaproot()
    gaproot_mutable = gaproot()

    gaproot_gapjl = abspath(@__DIR__, "..")
    @debug "Set up gaproot at $(gaproot_mutable)"

    gap_prefix = GAP_jll.find_artifact_dir()

    # load the existing sysinfo.gap
    sysinfo = read_sysinfo_gap(joinpath(gap_prefix, "lib", "gap"))

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
    gap_include2 = joinpath(gaproot_mutable) # for code doing `#include "src/compiled.h"`
    sysinfo["GAP_CPPFLAGS"] = "-I$(gap_include) -I$(gap_include2) -DUSE_JULIA_GC=1"

    # set linker flags; since these are meant for use for GAP packages,
    # add the necessary flags to link against libgap
    gap_lib = joinpath(gap_prefix, "lib")
    sysinfo["GAP_LDFLAGS"] = "-L$(gap_lib) -lgap"

    GAP_VERSION = VersionNumber(sysinfo["GAP_VERSION"])
    gaproot_packages = joinpath(Base.DEPOT_PATH[1], "gaproot", "v$(GAP_VERSION.major).$(GAP_VERSION.minor)")
    sysinfo["DEFAULT_PKGDIR"] = joinpath(gaproot_packages, "pkg")
    mkpath(sysinfo["DEFAULT_PKGDIR"])
    gap_lib_dir = abspath(GAP_lib_jll.find_artifact_dir(), "share", "gap")
    roots = [
            gaproot_gapjl,          # for JuliaInterface and JuliaExperimental
            gaproot_packages,       # default installation dir for PackageManager
            gaproot_mutable,
            gap_lib_dir, # the actual GAP library, from GAP_lib_jll
            ]
    sysinfo["GAPROOTS"] = join(roots, ";")

    # path to gap & gac (used by some package build systems)
    sysinfo["GAP"] = joinpath(gaproot_mutable, "bin", "gap.sh")
    sysinfo["GAC"] = joinpath(gaproot_mutable, "gac")

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

    # create the mutable gaproot
    mkpath(gaproot_mutable)
    Pidfile.mkpidlock("$gaproot_mutable.lock"; stale_age=10) do
        # create fake sysinfo.gap
        unquoted = Set(["GAParch", "GAP_ABI", "GAP_HPCGAP", "GAP_KERNEL_MAJOR_VERSION", "GAP_KERNEL_MINOR_VERSION", "GAP_OBJEXT"])
        open("$gaproot_mutable/sysinfo.gap", "w") do file
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

        # patch gac to load correct sysinfo.gap
        gac = read(joinpath(gap_prefix, "bin", "gac"), String)
        gac = replace(gac, r"^\. \"[^\"]+\"$"m => ". \"$(gaproot_mutable)/sysinfo.gap\"")
        write("$gaproot_mutable/gac", gac)
        chmod("$gaproot_mutable/gac", 0o755)
    end # mkpidlock

    return sysinfo
end

function build_JuliaInterface(sysinfo::Dict{String, String})
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
    cd(jipath) do
        withenv("CFLAGS" => JULIA_CFLAGS,
                "LDFLAGS" => JULIA_LDFLAGS * " " * JULIA_LIBS) do
            run(pipeline(`./configure $(gaproot())`, stdout="build.log"))
            run(pipeline(`make V=1 -j$(Sys.CPU_THREADS)`, stdout="build.log", append=true))
        end
    end

    return normpath(joinpath(jipath, "bin", sysinfo["GAParch"]))
end

function locate_JuliaInterface_so(sysinfo::Dict{String, String})
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
        path = build_JuliaInterface(sysinfo)
        @debug "Use JuliaInterface.so from $(path)"
    end
    return joinpath(path, "JuliaInterface.so")
end

end # module

"""
    create_gap_sh(dstdir::String)

Given a directory path, create three files in that directory:
- a shell script named `gap.sh` which acts like the `gap.sh` shipped with a
  regular GAP installation, but which behind the scenes launches GAP via Julia.
- two TOML files, `Manifest.toml` and `Project.toml`, which are required by
  `gap.sh` to function (they record the precise versions of GAP.jl and other
  Julia packages involved)
"""
function create_gap_sh(dstdir::String)

    mkpath(dstdir)

    gaproot_gapjl = abspath(@__DIR__, "..")

    ##
    ## Create Project.toml & Manifest.toml for use by gap.sh
    ##
    @info "Generating custom Julia project ..."
    run(`$(Base.julia_cmd()) --startup-file=no --project=$(dstdir) -e "using Pkg; Pkg.develop(PackageSpec(path=\"$(gaproot_gapjl)\"))"`)

    ##
    ## Create custom gap.sh
    ##
    @info "Generating gap.sh ..."

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
        exec $(joinpath(Sys.BINDIR, Base.julia_exename())) --startup-file=\$READ_STARTUP_FILE --project=$(dstdir) -i -- "$(gap_sh_path)" "\$@"
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
