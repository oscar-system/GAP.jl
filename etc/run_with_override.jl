#@info "Install needed packages"
#using Pkg
#Pkg.add(["Singular_jll", "CxxWrap", "CMake", "libsingular_julia_jll"])

#using GAP_jll
using Libdl

length(ARGS) >= 1 || error("must provide path of GAP build directory as first argument")
gaproot = popfirst!(ARGS)


# Given a path to a GAP compiled against Julia, setup
# a fake GAP_jll root dir suitable for a package override
function setup_override_dir(srcdir, dstdir)
    rm(dstdir; force = true, recursive = true)
    mkdir(dstdir)

    mkdir(joinpath(dstdir, "bin"))
    mkdir(joinpath(dstdir, "lib"))
    mkdir(joinpath(dstdir, "include"))
    mkdir(joinpath(dstdir, "share"))
    mkdir(joinpath(dstdir, "share", "gap"))

    symlink(joinpath(srcdir, "gap"), joinpath(dstdir, "bin", "gap"))
    symlink(joinpath(srcdir, "src"), joinpath(dstdir, "include", "gap"))
    symlink(joinpath(srcdir, "gac"), joinpath(dstdir, "share", "gap", "gac"))
    symlink(joinpath(srcdir, "sysinfo.gap"), joinpath(dstdir, "share", "gap", "sysinfo.gap"))

    for f in filter(endswith(Libdl.dlext), readdir(joinpath(srcdir, ".libs")))
        symlink(joinpath(srcdir, ".libs", f), joinpath(dstdir, "lib", f))
    end
end

function add_jll_override(depot, pkgname, newdir)
    uuid = string(Base.identify_package("$(pkgname)_jll").uuid)
    mkpath(joinpath(depot, "artifacts"))
    open(joinpath(depot, "artifacts", "Overrides.toml"), "a") do f
        write(f, """
        [$(uuid)]
        $(pkgname) = "$(newdir)"
        """)
    end
end

mktempdir() do tmp_gap_jll
    @info "Setup fake GAP_jll dir at $(tmp_gap_jll)"
    setup_override_dir(gaproot, tmp_gap_jll)

    mktempdir() do tmpdepot
        @info "Created temporary depot at $(tmpdepot)"

        # create override file for GAP_jll
        add_jll_override(tmpdepot, "GAP", tmp_gap_jll)

        # prepend our temporary depot to the depot list...
        withenv("JULIA_DEPOT_PATH"=>tmpdepot*":") do
            # we need to make sure that precompilation is run again with the override in place
            # (just running Pkg.precompile() does not seem to suffice)
            #un(`touch $(pathof(GAP_jll))`)
            # ... and start Julia, by default with the same project environment
            run(`$(Base.julia_cmd()) --project=$(Base.active_project()) $(ARGS)`)

            # TODO: perform some additional steps here, e.g. perhaps
            # verify that `libsingular_julia_jll.artifact_dir` is set right?
        end
    end
end
