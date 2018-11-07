@testset "basics" begin
    @test GAP.CSTR_STRING(GAP.Globals.String(GAP.Globals.PROD(2^59,2^59))) == "332306998946228968225951765070086144"

    l = GAP.to_gap([1,2,3])

    @test l[1] == 1
    @test l[end] == 3
    
    @test Symbol("Print") in propertynames(GAP.Globals,false)

    x = GAP.NewPlist(0)
    x[1] = 1
    @test x[1] == 1
    @test length(x) == 1

    @test GAP.True
    @test ! GAP.False

end
