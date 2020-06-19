using BinaryProvider
using Pkg.Artifacts

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

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
    "https://github.com/benlorenz/ncursesBuilder/releases/download/v6.1/build_ncurses.v6.1.0.jl",
    "https://github.com/benlorenz/readlineBuilder/releases/download/v8.0/build_readline.v8.0.0.jl",
]

# Download and install binaries
for dependency in dependencies
    build_file = basename(dependency)
    if !isfile(build_file)
        download(dependency, build_file)
    end
    # Execute the build scripts for the dependencies in an isolated module to
    # avoid overwriting any variables/constants here
    @eval module $(gensym())
    include($build_file)
    end
end
deps_prefix = joinpath(@__DIR__, "usr")

@info "Compiling GAP with" gap_src_root extra_gap_root gap_bin_root

rm(gap_bin_root, force = true, recursive = true)
mkpath(gap_bin_root)
cd(gap_bin_root) do
    # initiate an out of tree build; the ARCHEXT ensures we depend on the Julia version,
    # so that e.g. Julia 1.3 and 1.4 get separate binaries
    run(`$(gap_src_root)/configure
                --with-gc=julia
                --with-julia=$(Sys.BINDIR)
                --with-gmp=$(deps_prefix)
                --with-readline=$(deps_prefix)
                --with-zlib=$(deps_prefix)
                --disable-maintainer-mode
                LIBS="-Wl,-rpath -Wl,$(deps_prefix)/lib"
                ARCHEXT=v$(julia_version)
                `)
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
