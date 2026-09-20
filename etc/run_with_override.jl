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
@info "Using existing package environment at $(Base.active_project())"
using Pkg
Pkg.instantiate()
import GAP_lib_jll

#
#
#
function add_jll_override(depot, pkgname, newdir)
    pkgid = Base.identify_package("$(pkgname)_jll")
    pkguuid = string(pkgid.uuid)
    mkpath(joinpath(depot, "artifacts"))
    open(joinpath(depot, "artifacts", "Overrides.toml"), "a") do f
        write(f, """
        [$(pkguuid)]
        $(pkgname) = "$(newdir)"
        """)
    end
end

tmpdepot = mktempdir(; cleanup=true)
@info "Created temporary depot at $(tmpdepot)"

# create override file for GAP_jll
add_jll_override(tmpdepot, "GAP", gapoverride)
add_jll_override(tmpdepot, "GAP_lib", gapoverride)

# HACK: use the documentation from GAP_lib_jll instead of rebuilding it
run(`ln -sf $(abspath(GAP_lib_jll.find_artifact_dir(), "share", "gap", "doc")) $(abspath(gapoverride, "share", "gap", "doc"))`)

# Use the temporary depot alone: a trailing separator appends only the system
# depots, not ~/.julia. Nothing precompiled against the unoverridden JLLs is
# visible, so everything below is built with the override in place. This matters
# because an artifact override by itself does not invalidate a package image.
withenv("JULIA_DEPOT_PATH"=>tmpdepot*":", "FORCE_JULIAINTERFACE_COMPILATION" => "true") do

    # ... make sure all dependencies are installed ...
    run(`$(Base.julia_cmd()) --project=$(Base.active_project()) -e "using Pkg; Pkg.instantiate()"`)
    # ... and start Julia, by default with the same project environment
    run(`$(Base.julia_cmd()) --project=$(Base.active_project()) $(ARGS)`)
end
