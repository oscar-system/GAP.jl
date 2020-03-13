@testset "basics" begin
    @test GAP.CSTR_STRING(GAP.Globals.String(GAP.Globals.PROD(2^59,2^59))) == "332306998946228968225951765070086144"

    l = GAP.julia_to_gap([1,2,3])

    @test l[1] == 1
    @test l[end] == 3
    @test firstindex(l) == 1
    @test lastindex(l) == 3
    
    x = GAP.NewPlist(0)
    x[1] = 1
    @test x[1] == 1
    @test length(x) == 1

    xx = GAP.julia_to_gap([1,2,3])
    @test_throws ErrorException xx[4]

    @test string(GAP.julia_to_gap("x")) == "x"
end

@testset "globals" begin

    @test Symbol("Print") in propertynames(GAP.Globals,false)
    @test hasproperty(GAP.Globals, :Print)
    @test !hasproperty(GAP.Globals, :foobar)

    @test_throws ErrorException GAP.Globals.FOOBARQUX

    str = GAP.gap_to_julia(AbstractString, GAP.ValueGlobalVariable("IdentifierLetters"));
    @test str == "0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"

    @test GAP.CanAssignGlobalVariable("Read") == false
    @test GAP.CanAssignGlobalVariable("foobar")

    GAP.AssignGlobalVariable("foobar", 42)

    @test GAP.ValueGlobalVariable("foobar") == 42
    @test GAP.Globals.foobar == 42

    GAP.AssignGlobalVariable("foobar", false)
    @test GAP.ValueGlobalVariable("foobar") == false
    @test GAP.Globals.foobar == false

    GAP.AssignGlobalVariable("foobar", "julia_string")
    @test GAP.ValueGlobalVariable("foobar") == "julia_string"
    @test GAP.Globals.foobar == "julia_string"

    @test hasproperty(GAP.Globals, :foobar)
    GAP.Globals.foobar = nothing
    @test !hasproperty(GAP.Globals, :foobar)

    @test string(GAP.Globals) == "\"table of global GAP objects\""
end

@testset "gapcalls" begin
    f = GAP.EvalString("{x...} -> x")
    
    @test GAP.julia_to_gap([]) == f()
    @test GAP.julia_to_gap([1]) == f(1)
    @test GAP.julia_to_gap([1,2]) == f(1,2)
    @test GAP.julia_to_gap([1,2,3]) == f(1,2,3)
    @test GAP.julia_to_gap([1,2,3,4]) == f(1,2,3,4)
    @test GAP.julia_to_gap([1,2,3,4,5]) == f(1,2,3,4,5)
    @test GAP.julia_to_gap([1,2,3,4,5,6]) == f(1,2,3,4,5,6)
    @test GAP.julia_to_gap([1,2,3,4,5,6,7]) == f(1,2,3,4,5,6,7)

    # check to see if a non-basic object (here: a tuple) can be
    # passed and then extracted again
    @test f( (1,2,3) )[1] == (1,2,3)

    @test !(GAP.Globals.IdFunc(2^62) isa Int64)

    x = GAP.Globals.Indeterminate(GAP.Globals.Rationals)
    f = x^4+1
    i1 = GAP.Globals.IdealDecompositionsOfPolynomial(f)
    i2 = GAP.Globals.IdealDecompositionsOfPolynomial(f, onlyone = true)
    @test i1 != i2
    @test GAP.Globals.Length(GAP.Globals.OptionsStack) == 0
    @test_throws ErrorException GAP.Globals.Error(onlyone = true)
    @test GAP.Globals.Length(GAP.Globals.OptionsStack) == 0

end

@testset "bugfixes" begin
    # from issue #324:
    l = GAP.EvalString("[1,~,3]")
    @test l[2] === l
    @test GAP.gap_to_julia(GAP.Globals.StringViewObj(l)) == "[ 1, ~, 3 ]"
end
