# This Julia script sets up a directory with GAP compiled against the Julia
# used to run this script, then "installs" this GAP for use by the
# `run_with_override.jl` script


#
# parse arguments
#
length(ARGS) >= 1 || error("must provide path of GAP source directory as first argument")
length(ARGS) >= 2 || error("must provide path of destination directory as second argument")
gap_prefix = popfirst!(ARGS)
prefix = popfirst!(ARGS)
if length(ARGS) > 0 && ARGS[1] == "--debug"
  debugmode = true
  popfirst!(ARGS)
else
  debugmode = false
end

# TODO: should the user be allowed to provide a tmp_gap_build_dir ? that might
# be handy for incremental updates


# validate arguments
isdir(gap_prefix) || error("The given GAP prefix '$(gap_prefix)' is not a valid directory")
if ispath(prefix)
    error("installation prefix '$(prefix)' already exists, please remove it before running this script")
    # TODO: prompt the user for whether to delete the dir or abort
end

# convert into absolute paths
mkpath(prefix)
prefix = abspath(prefix)
gap_prefix = abspath(gap_prefix)

#
# Install needed packages
#
@info "Install needed packages"
using Pkg
using Artifacts
Pkg.add(["GMP_jll"])
Pkg.instantiate()

using GMP_jll

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
            Pkg.Artifacts.download_artifact(hash, dl_info["url"], dl_info["sha256"])
        end
        return artifact_path(hash)
    end

    # Otherwise, we can just use the artifact directory given to us by GMP_jll
    return GMP_jll.find_artifact_dir()
end

#
# locate GMP headers and the Julia executable for use by the GAP build system
#
gmp_prefix = gmp_artifact_dir()
juliabin = joinpath(Sys.BINDIR, Base.julia_exename())

#
# create a temporary directory for the build
#
tmp_gap_build_dir = mktempdir(; cleanup = true)
cd(tmp_gap_build_dir)

#
# configure and build GAP
#
@info "Configuring GAP in $(tmp_gap_build_dir) for $(prefix)"

if debugmode
    # compile GAP in debug mode (enables many additional assertions in the kernel)
    # and disable optimizations, so that debugging the resulting binary with gdb or lldb
    # gets easier
    @info "Debug mode is enabled"
    extraargs = ["CFLAGS=-g", "CXXFLAGS=-g", "--enable-debug"]
else
    extraargs = []
end
push!(extraargs, "CPPFLAGS=-DUSE_GAP_INSIDE_JULIA=1")

# TODO: redirect the output of configure into a log file
@show run(`$(gap_prefix)/configure
    --prefix=$(prefix)
    --with-gmp=$(gmp_prefix)
    --with-gc=julia
    --with-julia=$(juliabin)
    $(extraargs)
    $(ARGS)
    `)

@info "Building GAP in $(tmp_gap_build_dir)"

# first build the version of GAP without gac generated code
run(`make -j$(Sys.CPU_THREADS) build/gap-nocomp`)

# cheating: the following assumes that GAP in gap_prefix was already compiled...
# we copy some generated files, so that we don't have to re-generate them,
# which involves launching GAP, which requires libgmp from GMP_jll, which requires
# fiddling with DYLD_FALLBACK_LIBRARY_PATH / LD_LIBRARY_PATH ....
for f in ["c_oper1.c", "c_type1.c"]
    cp(joinpath(gap_prefix, "build", f), joinpath("build", f))
end

# complete the build
run(`make -j$(Sys.CPU_THREADS)`)

#
# "Install" GAP
#
@info "Installing GAP to $(prefix)"

# install GAP binaries, headers, libraries
run(`make install-bin install-headers install-libgap install-sysinfo install-gaproot`)


# We deliberately do NOT install the GAP library, documentation, etc. because
# they are identical across all platforms; instead, we use another platform
# independent artifact to ship them to the user.
