#
# parse arguments
#
length(ARGS) >= 1 || error("must provide path of GAP override directory as first argument")
gapoverride = popfirst!(ARGS)

isdir(gapoverride) || error("The given override path '$(gapoverride)' is not a valid directory")
gapoverride = abspath(gapoverride)

#
#
#
@info "Install needed packages"
using Pkg
Pkg.develop(path=dirname(dirname(@__FILE__)))
Pkg.add(["GAP_jll", "GAP_lib_jll"])
Pkg.instantiate()

import GAP_lib_jll

#
#
#
function add_jll_override(depot, pkgname, pkguuid, newdir)
    pkgid = Base.identify_package("$(pkgname)_jll")
    # does not work with julia 1.12-dev
    # pkguuid = string(pkgid.uuid)
    mkpath(joinpath(depot, "artifacts"))
    open(joinpath(depot, "artifacts", "Overrides.toml"), "a") do f
        write(f, """
        [$(pkguuid)]
        $(pkgname) = "$(newdir)"
        """)
    end

    # we need to make sure that precompilation is run again with the override in place
    # (just running Pkg.precompile() does not seem to suffice)
    run(`touch $(Base.locate_package(pkgid))`)
end

tmpdepot = mktempdir(; cleanup=true)
@info "Created temporary depot at $(tmpdepot)"

# create override file for GAP_jll
add_jll_override(tmpdepot, "GAP", "5cd7a574-2c56-5be2-91dc-c8bc375b9ddf", gapoverride)
add_jll_override(tmpdepot, "GAP_lib", "de1ad85e-c930-5cd4-919d-ccd3fcafd1a3", gapoverride)

# HACK: use the documentation from GAP_lib_jll instead of rebuilding it
run(`ln -sf $(abspath(GAP_lib_jll.find_artifact_dir(), "share", "gap", "doc")) $(abspath(gapoverride, "share", "gap", "doc"))`)

# prepend our temporary depot to the depot list...
withenv("JULIA_DEPOT_PATH"=>tmpdepot*":", "FORCE_JULIAINTERFACE_COMPILATION" => "true") do

    # ... and start Julia, by default with the same project environment
    run(`$(Base.julia_cmd()) --project=$(Base.active_project()) $(ARGS)`)
end
