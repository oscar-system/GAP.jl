@testset "conversion to GAP" begin
    
    @test GAP.to_gap(1) == 1
    
    x = GAP.Globals.Z(3)
    @test GAP.to_gap(x) == x
    
    x = GAP.EvalString("\"foo\";")[1][2]
    @test GAP.to_gap("foo") == x

    @test GAP.to_gap(true)
    @test ! GAP.to_gap(false)

    x = GAP.EvalString("[1,2,3];")[1][2]
    @test GAP.to_gap([1,2,3]) == x

end

@testset "conversion from GAP" begin

    @test GAP.from_gap(1,Any) == 1

    x = GAP.to_gap("foo")
    @test GAP.to_gap(x) == x
    @test GAP.from_gap(x,AbstractString) == "foo"
    @test GAP.from_gap(x,Symbol) == :foo

    x = GAP.to_gap([1,2,3])
    @test GAP.from_gap(x,Array{Any,1}) == Array{Any,1}([1,2,3])
    @test GAP.from_gap(x,Array{Int64,1}) == [1,2,3]
    
    x = GAP.to_gap(["foo"])
    @test GAP.from_gap(x,Array{Any,1}) == Array{Any,1}( [ GAP.to_gap("foo") ] )
    @test GAP.from_gap(x,Array{AbstractString,1}) == [ "foo" ]
    @test GAP.from_gap(x,Array{Symbol,1}) == [ :foo ]

end
