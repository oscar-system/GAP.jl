module Setup

using Pkg
using Pkg.Artifacts
using GAP_jll
using GAP_lib_jll
using GMP_jll

#############################################################################
#
# Set up the primary, mutable GAP root
#
# For this we read the sysinfo.gap bundled with GAP_jll and then modify it
# to be usable on this computer
#
#############################################################################

function force_symlink(p::AbstractString, np::AbstractString)
    rm(np; force = true)
    symlink(p, np)
end

function read_sysinfo_gap(dir::String)
    d = missing
    open(joinpath(dir, "sysinfo.gap")) do file
        d = Dict{String,String}()
        for ln in eachline(file)
            if length(ln) == 0 || ln[1] == '#'
                continue
            end
            s = split(ln, "=")
            if length(s) != 2
                continue
            end
            d[s[1]] = strip(s[2], ['"'])
        end
    end
    return d
end

function select_compiler(lang, candidates, extension)
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
            @info "selected $(compiler) as $(lang) compiler"
            return compiler
        catch
            @info "$(lang) compiler candidate '$(compiler)' not working"
        end
    end
    @warn "Could not locate a working $(lang) compiler"
    return nothing
end

include("julia-config.jl")

# In Julia >= 1.6, there is a "fake" GMP_jll which does not include header files;
# see <https://github.com/JuliaLang/julia/pull/38797#issuecomment-741953480>
function gmp_artifact_dir()
    artifacts_toml = joinpath(dirname(dirname(Base.pathof(GMP_jll))), "StdlibArtifacts.toml")

    # If this file exists, it's a stdlib JLL and we must download the artifact ourselves
    if isfile(artifacts_toml)
        meta = artifact_meta("GMP", artifacts_toml)
        hash = Base.SHA1(meta["git-tree-sha1"])
        if !artifact_exists(hash)
            dl_info = first(meta["download"])
            download_artifact(hash, dl_info["url"], dl_info["sha256"])
        end
        return artifact_path(hash)
    end

    # Otherwise, we can just use the artifact directory given to us by GMP_jll
    return GMP_jll.find_artifact_dir()
end

function regenerate_gaproot(gaproot_mutable)
    gaproot_gapjl = abspath(@__DIR__, "..")
    @info "Set up gaproot at $(gaproot_mutable)"

    gap_prefix = GAP_jll.find_artifact_dir()
    gmp_prefix = gmp_artifact_dir()

    # load the existing sysinfo.gap
    sysinfo = read_sysinfo_gap(joinpath(gap_prefix, "share", "gap"))

    #
    # now we modify sysinfo for our needs
    #

    # run code in julia-config.jl to determine compiler and linker flags for Julia;
    # remove apostrophes, they mess up quoting when used in shell code(although
    # they are fine inside of Makefiles); this could cause problems if any
    # paths involve spaces, but then we likely will haves problem in other
    # places; in any case, if anybody ever cares about this, we can work on
    # finding a better solution.
    sysinfo["JULIA_CPPFLAGS"] = filter(c -> c != '\'', cflags())
    sysinfo["JULIA_LDFLAGS"] = filter(c -> c != '\'', ldflags())
    sysinfo["JULIA_LIBS"] = filter(c -> c != '\'', ldlibs())

    # path to the currently used Julia executable 
    sysinfo["JULIA"] = joinpath(Sys.BINDIR, Base.julia_exename())

    #
    sysinfo["GAP_BIN_DIR"] = gaproot_mutable
    sysinfo["GAP_LIB_DIR"] = abspath(GAP_lib_jll.find_artifact_dir(), "share", "gap")

    # Locate C compiler (for use by GAP packages)
    cc_candidates = [ "gcc", "clang", "cc" ]
    haskey(ENV, "GAP_CC") && pushfirst!(cc_candidates, ENV["GAP_CC"])
    haskey(ENV, "CC") && pushfirst!(cc_candidates, ENV["CC"])
    CC = sysinfo["GAP_CC"] = select_compiler("C", cc_candidates, ".c")

    # Locate  C++ compiler (for use by GAP packages)
    cxx_candidates = [ "g++", "clang++", "c++" ]
    haskey(ENV, "GAP_CXX") && pushfirst!(GAP_CXX_candidates, ENV["CXX"])
    haskey(ENV, "CXX") && pushfirst!(cxx_candidates, ENV["CXX"])
    CXX = sysinfo["GAP_CXX"] = select_compiler("C++", cxx_candidates, ".cc")

    sysinfo["GAP_CFLAGS"] = " -g -O2"
    sysinfo["GAP_CXXFLAGS"] = " -g -O2"

    # set include flags -- since some GAP packages expect to be able to use gmp.h,
    # make sure to also add that
    gmp_include = joinpath(gmp_prefix, "include")
    gap_include = joinpath(gap_prefix, "include", "gap")
    gap_include2 = joinpath(gaproot_mutable) # for code doing `#include "src/compiled.h"`
    sysinfo["GAP_CPPFLAGS"] = "-I$(gmp_include) -I$(gap_include) -I$(gap_include2) -DHAVE_CONFIG_H"

    # set linker flags; since these are meant for use for GAP packages, add the necessary
    # flags to link against libgap
    gmp_lib = joinpath(gmp_prefix, "lib")
    gap_lib = joinpath(gap_prefix, "lib")
    sysinfo["GAP_LDFLAGS"] = "-L$(gmp_lib) -L$(gap_lib) -lgap " * sysinfo["JULIA_LDFLAGS"]
    
    # set library flags; note that for many packages (e.g. Browse) one really needs
    # additional flags.
    # We deliberately drop '-lz -lreadline' here, it should not be needed for packages
    sysinfo["GAP_LIBS"] = """-lgmp -lgap """ * sysinfo["JULIA_LIBS"]

    GAP_VERSION = VersionNumber(sysinfo["GAP_VERSION"])
    gaproot_packages = joinpath(Base.DEPOT_PATH[1], "gaproot", "v$(GAP_VERSION.major).$(GAP_VERSION.minor)")
    sysinfo["DEFAULT_PKGDIR"] = joinpath(gaproot_packages, "pkg")
    mkpath(sysinfo["DEFAULT_PKGDIR"])
    roots = [
            gaproot_gapjl,          # for JuliaInterface and JuliaExperimental
            gaproot_packages,       # default installation dir for PackageManager
            gaproot_mutable,
            sysinfo["GAP_LIB_DIR"], # the actual GAP library, from GAP_lib_jll
            ]
    sysinfo["GAPROOTS"] = join(roots, ";")

    # path to gap & gac (used by some package build systems)
    sysinfo["GAP"] = joinpath(gaproot_mutable, "bin", "gap.sh")
    sysinfo["GAC"] = joinpath(gaproot_mutable, "gac")

    # create the mutable gaproot
    rm(gaproot_mutable, recursive=true, force=true)
    mkpath(gaproot_mutable)
    cd(gaproot_mutable) do
        # create fake sysinfo.gap
        unquoted = Set(["GAParch", "GAP_ABI", "GAP_HPCGAP", "GAP_KERNEL_MAJOR_VERSION", "GAP_KERNEL_MINOR_VERSION"])
        open("sysinfo.gap", "w") do file
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

        # patch gac; for now we also use a modified copy of gac 
        # we completely get rid of libtool to simplify our life (the extra speed
        # is a nice side effect)
        # TODO: backport as many as possible of these or similar changes to GAP itself
        gac = read(joinpath(gaproot_gapjl, "etc", "gac"), String)
        #gac = read(joinpath(gap_prefix, "share", "gap", "gac"), String)

        # abs_top_builddir, abs_top_srcdir and libdir must always be reset to ensure
        # relocatability of this package
        gac = replace(gac, r"^abs_top_builddir=.+$"m => "\nabs_top_builddir=\"$(gaproot_mutable)\"")
        gac = replace(gac, r"^abs_top_srcdir=.+$"m => "\nabs_top_srcdir=\"$(gaproot_mutable)\"")
        gac = replace(gac, r"^libdir=.+$"m => "\nlibdir=\"$(gaproot_mutable)/lib\"")

        # normally GAP extensions do not use backlinking; but we need this, as GAP_jll
        # does not use RTLD_GLOBAL by default
        gac = replace(gac, r"^c_addlibs=.+$"m => "\nc_addlibs=\"-lgap\"")

        # determine compiler & linker (and ignore libtool for all this)
        if Sys.islinux() || Sys.isfreebsd()
            c_compiler = "$(CC) -fPIC -DPIC"
            cxx_compiler = "$(CXX) -fPIC -DPIC"
            c_dyn_linker = "$(CC) -shared -fPIC -DPIC"
        elseif Sys.isapple()
            c_compiler = "$(CC) -fno-common -DPIC"
            cxx_compiler = "$(CXX) -fno-common -DPIC"
            c_dyn_linker = "$(CC) -bundle"
        else
            error("OS not supported")
        end
        gac = replace(gac, r"^c_compiler=.+$"m => "c_compiler=\"$(c_compiler)\"")
        gac = replace(gac, r"^cxx_compiler=.+$"m => "cxx_compiler=\"$(cxx_compiler)\"")
        gac = replace(gac, r"^c_dyn_linker=.+$"m => "c_dyn_linker=\"$(c_dyn_linker) -lgap\"")
        gac = replace(gac, r"^c_linker=.+$"m => "c_linker=\"echo static linking not supported ; exit 1 ;\"")

        # write it all out and fix the access permissions
        write("gac", gac)
        chmod("gac", 0o755)

        # 
        mkpath("bin")
        for d in (("include/gap", "src"), ("lib", "lib"), ("bin/gap", "gap"))
            force_symlink(joinpath(gap_prefix, d[1]), d[2])
        end

        # emulate the "compat mode" of the GAP build system, to help certain
        # packages like Browse with an outdated build system
        mkpath(joinpath("bin", sysinfo["GAParch"]))
        force_symlink("sysinfo.gap", "sysinfo.gap-default64")
        force_symlink(abspath("gac"), joinpath("bin", sysinfo["GAParch"], "gac"))

        # for building GAP packages
        force_symlink(joinpath(GAP_lib_jll.find_artifact_dir(), "share", "gap", "bin", "BuildPackages.sh"),
                      joinpath("bin", "BuildPackages.sh"))

        # create a `pkg` symlink to the GAP packages artifact
        force_symlink(artifact"gap_packages", "pkg")

        ##
        ## Create Project.toml & Manifest.toml for use by gap.sh
        ##
        @info "Generating custom Julia project ..."
        relative_pkgdir = joinpath("..", "..")
        @assert abspath(gaproot_mutable, relative_pkgdir) == gaproot_gapjl
        run(pipeline(`$(Base.julia_cmd()) --startup-file=no --project=$(gaproot_mutable) -e "using Pkg; Pkg.develop(PackageSpec(path=\"$(relative_pkgdir)\")); Pkg.resolve()"`))

    end # cd

    ##
    ## Create custom gap.sh
    ##
    @info "Generating gap.sh ..."

    gap_sh_path = joinpath(gaproot_mutable, "bin", "gap.sh")
    write(gap_sh_path,
        """
        #!/bin/sh
        # This is a a Julia script which also is a valid bash script; if executed by
        # bash, it will execute itself by invoking `julia`. Of course this only works
        # right if `julia` exists in the PATH and is the "correct" julia executable.
        # But you can always instead load this file as if it was a .jl file via any
        # other Julia executable.
        #=
        exec $(joinpath(Sys.BINDIR, Base.julia_exename())) --startup-file=no --project=$(gaproot_mutable) -- "$(gap_sh_path)" "\$@"
        =#

        # pass command line arguments to GAP.jl via a small hack
        ENV["GAP_PRINT_BANNER"] = "true"
        __GAP_ARGS__ = ARGS
        using GAP

        # Read the files from the GAP command line.
        ccall((:Call0ArgsInNewReader, GAP.GAP_jll.libgap), Cvoid, (Any,), GAP.Globals.GAPInfo.LoadInitFiles_GAP_JL)

        # GAP.jl forces the norepl option, which means that init.g never
        # starts a GAP session; we now run one "manually". Note that this
        # may throw a "GAP exception", which we need to catch; thus we
        # use Call0ArgsInNewReader to perform the actual call.
        if !GAP.Globals.GAPInfo.CommandLineOptions_original.norepl
            ccall((:Call0ArgsInNewReader, GAP.GAP_jll.libgap), Cvoid, (Any,), GAP.Globals.SESSION)
        end

        # call GAP's "atexit" cleanup functions
        ccall((:Call0ArgsInNewReader, GAP.GAP_jll.libgap), Cvoid, (Any,), GAP.Globals.PROGRAM_CLEAN_UP)

        # Finally exit
        exit(GAP.exit_code())
        """,
        )
    chmod(gap_sh_path, 0o755)

    ##
    ## Finally, compile JuliaInterface
    ##
    @info "Compiling JuliaInterface ..."

    cd(joinpath(gaproot_gapjl, "pkg", "JuliaInterface")) do
        run(pipeline(`./configure $gaproot_mutable`, stdout="build.log"))
        run(pipeline(`make -j$(Sys.CPU_THREADS)`, stdout="build.log", append=true))
    end

    return gaproot_mutable
end # function

end # module
