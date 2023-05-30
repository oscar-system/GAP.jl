using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(
        GAP;
        ambiguities=false,      # TODO: fix ambiguities
        unbound_args=true,
        undefined_exports=true,
        project_extras=true,
        stale_deps=false,       # some weird error with GAP_lib_jll
        deps_compat=true,
        project_toml_formatting=true,
        piracy=false            # TODO: fix
    )
end
