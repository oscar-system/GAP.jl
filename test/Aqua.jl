using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(
        GAP;
        ambiguities=false, # some from AbstractAlgebra.jl show up here
        piracies=(GAP.use_jl_reinit_foreign_type() ? true : (treat_as_own=[GapObj],))
    )
end
