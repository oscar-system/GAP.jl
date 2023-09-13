using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(
        GAP;
        ambiguities=true,
        unbound_args=true,
        undefined_exports=true,
        project_extras=true,
        stale_deps=true,
        deps_compat=true,
        project_toml_formatting=true,
        piracy=(GAP.use_jl_reinit_foreign_type() ? true : (treat_as_own=[GapObj],))
    )
end
