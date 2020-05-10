using BinaryProvider
using Pkg.Artifacts
using GMP_jll
using Readline_jll
using Zlib_jll

# Remove deps.jl now, so that we can recognize an aborted build by its absence
const julia_version = "$(VERSION.major).$(VERSION.minor)"
deps_jl = abspath(joinpath(@__DIR__, "deps-$(julia_version).jl"))
rm(deps_jl, force = true)

# Reference the Julia artifact containing the GAP source code
artifact_dir = abspath(artifact"gap")

# that artifact directory must contain a single subdirectory, with a name
# which looks something like `gap-4.X.Y`; get that name
content = readdir(artifact_dir)
@assert length(content) == 1
gapdirname = content[1]

# the location the GAP source code is installed
gap_src_root = abspath(joinpath(artifact_dir, "$(gapdirname)"))

# the location of the GAP.jl direction, which contains a `pkg` subdir
extra_gap_root = abspath(joinpath(@__DIR__, ".."))

# the location in which we initiate GAP's "out of tree build"
gap_bin_root = abspath(joinpath(@__DIR__, "build", "$(gapdirname)-julia-$(julia_version)"))

gmp_prefix = GMP_jll.artifact_dir
readline_prefix = Readline_jll.artifact_dir
zlib_prefix = Zlib_jll.artifact_dir


# setup LIBS with the linker paths for the three libraries above, and their
# transitive dependencies.
#
# WARNING: actually we should NOT set these here at link time. Instead we need
# to set these dynamically when loading GAP, as the _jll packages could be
# upgraded at any time to use new artifacts, and then we must link against the
# lib in the new location. So hardcoding paths into the GAP binary is not the
# best idea.
#
# On the other hand, for the configure tests for e.g. readline to pass, it needs
# to "see" all paths. TODO
#
# TODO/FIXME revise the following test
# That also means gap.sh has to be different, and set the LIBPATH_env var
# (i.e., LD_LIBRARY_PATH, DYLD_FALLBACK_LIBRARY_PATH) suitably
#LIBS="-Wl,-rpath -Wl,$(gmp_prefix)/lib -Wl,-rpath -Wl,$(readline_prefix)/lib -Wl,-rpath -Wl,$(zlib_prefix)/lib"
LIBPATH_list=[]
foreach(p -> append!(LIBPATH_list, p.LIBPATH_list), (GMP_jll,Readline_jll,Zlib_jll))
filter!(!isempty, unique!(LIBPATH_list))
# FIXME/HACK: set LIBS after all, to see if we can get Travis to pass with it;
#LIBS=join(["-Wl,-rpath -Wl,$path" for path in LIBPATH_list]," ")
#LDFLAGS=join(["-L$path" for path in LIBPATH_list]," ")
LIBPATH=join(LIBPATH_list, ":")

@info "Compiling GAP with" gap_src_root extra_gap_root gap_bin_root

rm(gap_bin_root, force = true, recursive = true)
mkpath(gap_bin_root)
cd(gap_bin_root) do
    # initiate an out of tree build; the ARCHEXT ensures we depend on the Julia version,
    # so that e.g. Julia 1.3 and 1.4 get separate binaries
  try
    withenv(Readline_jll.LIBPATH_env => LIBPATH) do
    run(`$(gap_src_root)/configure
                --with-gc=julia
                --with-julia=$(Sys.BINDIR)
                --with-gmp=$(gmp_prefix)
                --with-readline=$(readline_prefix)
                --with-zlib=$(zlib_prefix)
                --disable-maintainer-mode
                ARCHEXT=v$(julia_version)
                `)
    end
  catch
    run(`cat config.log`)
    error("configure failed")
  end
    run(`make -j$(Sys.CPU_THREADS)`)
end

# clean out some clutter
rm(joinpath(gap_bin_root, "obj"), force = true, recursive = true)

##
## Compile JuliaInterface
##
println("Compiling JuliaInterface ...")
cd(joinpath(extra_gap_root, "pkg", "JuliaInterface")) do
    run(`./configure $gap_bin_root`)
    run(`make -j$(Sys.CPU_THREADS)`)
end

##
## Write deps.jl file containing the necessary paths
##
println("Generating $(deps_jl) ...")

write(
    deps_jl,
    """
const GAPROOT = "$gap_bin_root"
""",
)

##
## Create custom gap.sh
##
println("Generating gap.sh ...")

gap_sh_path = joinpath(gap_bin_root, "bin", "gap.sh")
write(
    gap_sh_path,
    """
#!/bin/bash
# This is a a Julia script which also is a valid bash script; if executed by
# bash, it will execute itself by invoking `julia`. Of course this only works
# right if `julia` exists in the PATH and is the "correct" julia executable.
# But you can always instead load this file as if it was a .jl file via any
# other Julia executable.
#=
exec julia --startup-file=no -- "\${BASH_SOURCE[0]}" "\$@"
=#

# pass command line arguments to GAP.jl via a small hack
ENV["GAP_SHOW_BANNER"] = "true"
__GAP_ARGS__ = ARGS
using GAP

# GAP.jl passes --norepl to GAP, which means that init.g never
# starts a GAP session; we now run one "manually". Note that this
# may throw a "GAP exception", which we need to catch; thus we
# use Call0ArgsInNewReader to perform the actual call.
ccall(:Call0ArgsInNewReader, Cvoid, (Any,), GAP.Globals.SESSION)

# call GAP's "atexit" cleanup functions
ccall(:Call0ArgsInNewReader, Cvoid, (Any,), GAP.Globals.PROGRAM_CLEAN_UP)

# Finally exit by calling GAP's FORCE_QUIT_GAP(). See comments in GAP.jl for
# an explanation of why we do it this way.
GAP.Globals.FORCE_QUIT_GAP()
""",
)
chmod(gap_sh_path, 0o755)

##
## Build a few packages if requested (must happen after gap.sh was created)
##

# use our own copy of BuildPackages.sh to work around issues in the one
# shipped with GAP 4.11.0 with out-of-tree builds; we also copy it to
# our GAPROOT to help PackageManager
# FIXME: remove this once GAP 4.11.1 is out and PackageManager is improved
BuildPackages_sh = joinpath(gap_bin_root, "bin", "BuildPackages.sh")
cp(joinpath(@__DIR__, "BuildPackages.sh"), BuildPackages_sh, force = true)
