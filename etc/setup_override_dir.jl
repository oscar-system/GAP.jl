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

if length(ARGS) > 0 && !startswith(ARGS[1], "--")
  build_dir = popfirst!(ARGS)
else
  build_dir = mktempdir(; cleanup = true)
end

run_configure = true
overwrite_allow = false
verbose = false
debugmode = false
left_ARGS = String[]
while !isempty(ARGS)
   arg = popfirst!(ARGS)
   if arg == "--no-configure"
      global run_configure = false
   elseif arg == "--yes"
      global overwrite_allow = true
   elseif arg == "--verbose"
      global verbose = true
   elseif arg == "--debug"
      global debugmode = true
   else
      push!(left_ARGS, arg)
   end
end



# validate arguments
isdir(gap_prefix) || error("The given GAP prefix '$(gap_prefix)' is not a valid directory")
if ispath(prefix)
   if !overwrite_allow
      print("The given installation prefix '$(prefix)' already exists. Overwrite? [Y/n] ")
      overwrite_allow = lowercase(readline()) in ["y", "yes", ""]
   end
   if overwrite_allow
      rm(prefix; force=true, recursive=true)
   else
      error("Aborting")
   end
end

# convert into absolute paths
mkpath(prefix)
prefix = abspath(prefix)
gap_prefix = abspath(gap_prefix)
mkpath(build_dir)
build_dir = abspath(build_dir)

#
# Install needed packages
#
@info "Install needed packages"
using Pkg
using Artifacts
Pkg.add(["JLLPrefixes"])
Pkg.instantiate()

using JLLPrefixes

cd(build_dir)


if run_configure
   @info "Configuring GAP in $(build_dir) for $(prefix)"

   deps = ["GMP_jll"]
   artifact_paths = collect_artifact_paths(deps)
   deps_path = mktempdir(; cleanup=false)
   deploy_artifact_paths(deps_path, artifact_paths) # collect all (transitive) dependencies into one tree

   juliabin = joinpath(Sys.BINDIR, Base.julia_exename())

   extraargs = ["CPPFLAGS=-DUSE_GAP_INSIDE_JULIA=1"]

   if debugmode
      # compile GAP in debug mode (enables many additional assertions in the kernel)
      # and disable optimizations, so that debugging the resulting binary with gdb or lldb
      # gets easier
      @info "Debug mode is enabled"
      append!(extraargs, ["CFLAGS=-g", "CXXFLAGS=-g", "--enable-debug"])
   end

   env = Dict(
      "CC" => "gcc",
      "CXX" => "g++",
   )

   configure_cmd = addenv(
      `$(gap_prefix)/configure
      --prefix=$(prefix)
      --with-gmp=$(deps_path)
      --with-gc=julia
      --with-julia=$(juliabin)
      $(extraargs)
      $(left_ARGS)
      `,
      env
   )

   verbose && @show configure_cmd

   # TODO: redirect the output of configure into a log file
   @show run(configure_cmd)
end

@info "Building GAP in $(build_dir)"

# first build the version of GAP without gac generated code
run(`make -j$(Sys.CPU_THREADS) build/gap-nocomp $(verbose ? "V=1" : "")`)

# cheating: the following assumes that GAP in gap_prefix was already compiled...
# we copy some generated files, so that we don't have to re-generate them,
# which involves launching GAP, which requires libgmp from GMP_jll, which requires
# fiddling with DYLD_FALLBACK_LIBRARY_PATH / LD_LIBRARY_PATH ....
for f in ["c_oper1.c", "c_type1.c"]
    cp(joinpath(gap_prefix, "build", f), joinpath("build", f))
end

# complete the build
run(`make -j$(Sys.CPU_THREADS) $(verbose ? "V=1" : "")`)


@info "Installing GAP to $(prefix)"
run(`make install-bin install-headers install-libgap install-sysinfo install-gaproot`)
# We deliberately do NOT install the GAP library, documentation, etc. because
# they are identical across all platforms; instead, we use another platform
# independent artifact to ship them to the user.
