@testset "@gapattribute" begin

    """
        isevenint_GAP(x)
    
    Return `true` if the input integer is even.
    """
    @gapattribute isevenint_GAP(x::Int) = GAP.Globals.IsEvenInt(x)::Bool

    doc = string(@doc isevenint_GAP)
    @test !occursin("No documentation found", string(doc))
    @test occursin("if the input integer is even", string(doc))

    doc = string(@doc hasisevenint_GAP)
    @test !occursin("No documentation found", string(doc))
    @test occursin("has already been computed", string(doc))

    doc = string(@doc setisevenint_GAP)
    @test !occursin("No documentation found", string(doc))
    @test occursin("Set the value", string(doc))

end

@testset "compat" begin

    x = @gap (1, 2, 3)
    @test x == GAP.evalstr("(1,2,3)")
    x = @gap((1, 2, 3))
    @test x == GAP.evalstr("(1,2,3)")
    x = @gap [1, 2, 3]
    @test x == GAP.evalstr("[1,2,3]")
    x = @gap(SymmetricGroup)(3)
    @test GAP.Globals.Size(x) == 6
    # Errors thrown by the GAP.@gap macro cannot be tested directly,
    # the following test does not work as intended.
    # @test_throws ErrorException @gap (1,2)(3,4)

    x = GAP.g"foo"
    @test x == GAP.julia_to_gap("foo")
    x = GAP.g"1:\n, 2:\", 3:\\, 4:\b, 5:\r, 6:\c, 7:\001"
    @test x == GAP.julia_to_gap("1:\n, 2:\", 3:\\, 4:\b, 5:\r, 6:\003, 7:\001")
    # Errors thrown by the GAP.@g_str macro cannot be tested directly,
    # and the string "\\" can be handed over in the macro.
    @test_throws ErrorException GAP.gap_string_macro_helper("\\")

end
