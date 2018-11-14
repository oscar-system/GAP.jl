@testset "conversion to GAP" begin
    
    @test GAP.julia_to_gap(1) == 1
    
    x = GAP.Globals.Z(3)
    @test GAP.julia_to_gap(x) == x
    
    x = GAP.EvalString("\"foo\";")[1][2]
    @test GAP.julia_to_gap("foo") == x

    @test GAP.julia_to_gap(true)
    @test ! GAP.julia_to_gap(false)

    x = GAP.EvalString("[1,2,3];")[1][2]
    @test GAP.julia_to_gap([1,2,3]) == x

    @test GAP.julia_to_gap(:x) == GAP.julia_to_gap("x")

    @test GAP.julia_to_gap(BigInt(2)) == 2
    @test GAP.julia_to_gap(BigInt(2)^100) == GAP.EvalString("2^100;")[1][2]

end

@testset "conversion from GAP" begin

    @test GAP.from_gap(1,Any) == 1
    @test GAP.from_gap(1) == 1

    x = GAP.julia_to_gap("foo")
    @test GAP.julia_to_gap(x) == x
    @test GAP.from_gap(x,AbstractString) == "foo"
    @test GAP.from_gap(x,Symbol) == :foo

    x = GAP.julia_to_gap([1,2,3])
    @test GAP.from_gap(x,Array{Any,1}) == Array{Any,1}([1,2,3])
    @test GAP.from_gap(x,Array{Int64,1}) == [1,2,3]
    
    x = GAP.julia_to_gap(["foo"])
    @test GAP.from_gap(x,Array{Any,1}) == Array{Any,1}( [ GAP.julia_to_gap("foo") ] )
    @test GAP.from_gap(x,Array{AbstractString,1}) == [ "foo" ]
    @test GAP.from_gap(x,Array{Symbol,1}) == [ :foo ]

end
