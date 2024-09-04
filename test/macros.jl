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

    doc = string(@doc has_isevenint_GAP)
    @test !occursin("No documentation found", string(doc))
    @test occursin("has already been computed", string(doc))

    doc = string(@doc set_isevenint_GAP)
    @test !occursin("No documentation found", string(doc))
    @test occursin("Set the value", string(doc))

    # Do tester and setter refer to the right objects?
    # (Choose a group `G` whose center is different from the center
    # of its derived subgroup.)
    @gapattribute cendersub(G::GapObj) = GAP.Globals.Centre(dersub(G))
    G = GAP.Globals.SymmetricGroup(3)
    @test GAP.Globals.Size(GAP.Globals.Centre(G)) == 1
    G = GAP.Globals.SymmetricGroup(3)  # create the group anew
    @test ! GAP.Globals.HasCentre(G)
    @test ! has_dersub(G)
    @test ! has_cendersub(G)
    @test has_dersub(G)  # the previous call has set the value
    ggens = GAP.Globals.GeneratorsOfGroup(G)
    set_cendersub(G, GAP.Globals.Subgroup(G, GAP.GapObj([ggens[1]])))
    @test has_cendersub(G)
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
    @test_throws ErrorException @gap (1,2)(3,4)

    x = GAP.g"foo"
    @test x == GAP.julia_to_gap("foo")
    x = GAP.g"1:\n, 2:\", 3:\\, 4:\b, 5:\r, 6:\c, 7:\001"
    @test x == GAP.julia_to_gap("1:\n, 2:\", 3:\\, 4:\b, 5:\r, 6:\003, 7:\001")
    @test_throws ErrorException g"\\"

end

@testset "@install GapObj" begin
    a = GAP.evalstr("(1,2)")

    struct TestType1 X::GapObj end
    GAP.@install GapObj(x::TestType1) = x.X
    @test GapObj(TestType1(a)) === a

    struct TestType2 X::GapObj end
    GAP.@install function GAP.GapObj(x::TestType2) return x.X; end
    @test GapObj(TestType2(a)) === a

    @test_throws ErrorException @macroexpand GAP.@install Obj(x::Bool)
    @test_throws ErrorException @macroexpand GAP.@install Obj(x::Bool) = x
    @test_throws ErrorException @macroexpand GAP.@install GapObj(x::Bool, y::Bool) = x
end
