@testset "compat" begin

    x = @gap (1,2,3)
    @test x == GAP.EvalString("(1,2,3)")
    x = @gap((1,2,3))
    @test x == GAP.EvalString("(1,2,3)")
    x = @gap [1,2,3]
    @test x == GAP.EvalString("[1,2,3]")
    x = @gap(SymmetricGroup)(3)
    @test GAP.Globals.Size(x) == 6
    x = GAP.g"foo"
    @test x == GAP.julia_to_gap("foo")
end
