@testset "basics" begin
    @test GAP.CSTR_STRING(GAP.Globals.String(GAP.Globals.PROD(2^59,2^59))) == "332306998946228968225951765070086144"

    l = GAP.to_gap([1,2,3])

    @test l[1] == 1
    @test l[end] == 3
    @test firstindex(l) == 1
    @test lastindex(l) == 3
    
    @test Symbol("Print") in propertynames(GAP.Globals,false)

    x = GAP.NewPlist(0)
    x[1] = 1
    @test x[1] == 1
    @test length(x) == 1

    @test GAP.True
    @test ! GAP.False


    xx = GAP.to_gap([1,2,3])
    @test_throws ErrorException xx[4]

    @test_throws ErrorException GAP.Globals.FOOBARQUX

    str = GAP.from_gap(GAP.ValueGlobalVariable("IdentifierLetters"), AbstractString);
    @test str == "0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"

    @test string(GAP.Globals) == "\"table of global GAP objects\""

    @test string(GAP.to_gap("x")) == "x"
end

@testset "gapcalls" begin
    f = GAP.EvalString("{x...} -> x;")[1][2]
    
    @test GAP.to_gap([]) == f()
    @test GAP.to_gap([1]) == f(1)
    @test GAP.to_gap([1,2]) == f(1,2)
    @test GAP.to_gap([1,2,3]) == f(1,2,3)
    @test GAP.to_gap([1,2,3,4]) == f(1,2,3,4)
    @test GAP.to_gap([1,2,3,4,5]) == f(1,2,3,4,5)
    @test GAP.to_gap([1,2,3,4,5,6]) == f(1,2,3,4,5,6)
    @test GAP.to_gap([1,2,3,4,5,6,7]) == f(1,2,3,4,5,6,7)

    # check to see if a non-basic object (here: a tuple) can be
    # passed and then extracted again
    @test f( (1,2,3) )[1] == (1,2,3)

end
