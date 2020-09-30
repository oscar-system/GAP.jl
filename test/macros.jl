@testset "compat" begin

    x = @gap (1, 2, 3)
    @test x == GAP.evalstr("(1,2,3)")
    x = @gap((1, 2, 3))
    @test x == GAP.evalstr("(1,2,3)")
    x = @gap [1, 2, 3]
    @test x == GAP.evalstr("[1,2,3]")
    x = @gap(SymmetricGroup)(3)
    @test GAP.Globals.Size(x) == 6
    x = GAP.g"foo"
    @test x == GAP.julia_to_gap("foo")
    x = GAP.g"1:\n, 2:\", 3:\\, 4:\b, 5:\r, 6:\c, 7:\001"
    @test x == GAP.julia_to_gap("1:\n, 2:\", 3:\\, 4:\b, 5:\r, 6:\003, 7:\001")
#TODO: Can the following error not be tested?
#    @test_throws LoadError GAP.g"\\"

end
