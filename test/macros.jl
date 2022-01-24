@gapattribute dersub(G::GapObj) = GAP.Globals.DerivedSubgroup(G)

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

    # Do tester and setter refer to the right objects?
    @gapattribute cendersub(G::GapObj) = GAP.Globals.Centre(dersub(G))
    G = GAP.Globals.SmallGroup(72, 15)
    @test GAP.Globals.Size(GAP.Globals.Centre(G)) == 1
    G = GAP.Globals.SmallGroup(72, 15)  # create the group anew
    @test ! GAP.Globals.HasCentre(G)
    @test ! hasdersub(G)
    @test ! hascendersub(G)
    @test hasdersub(G)  # the previous call has set the value
    ggens = GAP.Globals.GeneratorsOfGroup(G)
    setcendersub(G, GAP.Globals.Subgroup(G, GAP.GapObj([ggens[3]])))
    @test hascendersub(G)
    @test GAP.Globals.HasCentre(GAP.Globals.DerivedSubgroup(G))
    @test GAP.Globals.Size(GAP.Globals.Centre(G)) == 1

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
