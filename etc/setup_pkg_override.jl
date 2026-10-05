# This Julia script sets up a depot which makes GAP.jl use the copy of a GAP
# package in a given directory instead of the one bundled with GAP.jl: its
# GAP code and, if the package has a JLL, its kernel extension resp.
# executables, which get compiled against the GAP from `GAP_jll`.
#
#   julia --project etc/setup_pkg_override.jl PKGDIR DEPOT [--no-build]
#         [--configure-arg=ARG]... [--make-arg=ARG]...
#
# With `--no-build` nothing is compiled and the binaries from the JLL stay in
# use. In each ARG, `@Foo_jll@` is replaced by the artifact directory of
# `Foo_jll`, which must be a dependency of the JLL of the package.

#
# parse arguments
#
length(ARGS) >= 2 || error("must provide a GAP package directory and a depot directory as arguments")

pkgroot = abspath(popfirst!(ARGS))
depot = abspath(popfirst!(ARGS))

build = true
configure_args = String[]
make_args = String[]
for arg in ARGS
    if arg == "--no-build"
        global build = false
    elseif startswith(arg, "--configure-arg=")
        push!(configure_args, chopprefix(arg, "--configure-arg="))
    elseif startswith(arg, "--make-arg=")
        push!(make_args, chopprefix(arg, "--make-arg="))
    else
        error("unsupported argument '$arg'")
    end
end

pkginfo = joinpath(pkgroot, "PackageInfo.g")
isfile(pkginfo) || error("'$pkgroot' does not contain a PackageInfo.g file")
m = match(r"PackageName\s*:=\s*\"([^\"]+)\"", read(pkginfo, String))
m !== nothing || error("cannot determine the package name from '$pkginfo'")
pkgname = m[1]

# GAP.jl and the JLL both name their artifact for the package like this
artifact = "GAP_pkg_" * lowercase(pkgname)

using GAP
import Artifacts

artifacts_toml = joinpath(pkgdir(GAP), "Artifacts.toml")
haskey(Artifacts.load_artifacts_toml(artifacts_toml), artifact) || error("GAP.jl does not bundle a GAP package '$pkgname'")

# maps package UUIDs to the replacement for their artifact
overrides = Dict(Base.PkgId(GAP).uuid => pkgroot)

#
# compile the package and put the result into a stand-in for the JLL artifact
#
jllname = Symbol(artifact, "_jll")
if build && isdefined(GAP, jllname)
    jll = getproperty(GAP, jllname)
    jll_prefix(placeholder) = getproperty(jll, Symbol(placeholder[2:end-1])).find_artifact_dir()
    expand(args) = [replace(arg, r"@\w+_jll@" => jll_prefix) for arg in args]

    # kept inside the depot so that `make` can be rerun by hand later on
    gaproot = joinpath(depot, "gaproot")
    mkpath(depot)
    GAP.Setup.assure_gaproot_for_building(gaproot)

    cd(pkgroot) do
        if isfile("configure")
            # autoconf based build systems want `--with-gaproot`, the others a plain path
            gaproot_arg = occursin("with-gaproot", read("configure", String)) ? "--with-gaproot=$gaproot" : gaproot
            run(`./configure $gaproot_arg $(expand(configure_args))`)
        end
        run(`make $(expand(make_args))`)
    end

    bindir = joinpath(pkgroot, "bin", GAP.sysinfo["GAParch"])
    isdir(bindir) || error("the build did not create '$bindir'")

    # mimic the layout of the JLL, see `setup_overrides` in `src/GAP_pkg.jl`
    jlldir = joinpath(depot, "jll")
    subdir = isdir(joinpath(jll.find_artifact_dir(), "bin")) ? "bin" : joinpath("lib", "gap")
    link = joinpath(jlldir, subdir)
    mkpath(dirname(link))
    rm(link; force=true)
    symlink(bindir, link)

    overrides[Base.PkgId(jll).uuid] = jlldir
end

#
# write the overrides
#
mkpath(joinpath(depot, "artifacts"))
open(joinpath(depot, "artifacts", "Overrides.toml"), "w") do io
    for (uuid, dir) in overrides
        println(io, "[$uuid]\n$artifact = \"$dir\"")
    end
end

depot_path = join([depot; DEPOT_PATH], ":")
println("""

    Override for the GAP package '$pkgname' written to '$depot'.
    To use it, start Julia like this:

        JULIA_DEPOT_PATH="$depot_path" julia --project=$(dirname(Base.active_project()))
    """)
