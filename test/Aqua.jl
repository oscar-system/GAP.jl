using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(
        GAP;
        piracies=(GAP.use_jl_reinit_foreign_type() ? true : (treat_as_own=[GapObj],))
    )
end
