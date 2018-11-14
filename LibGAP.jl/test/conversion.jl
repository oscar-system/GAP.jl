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

    # TODO: reimplement the following
#    @test GAP.gap_to_julia(Any,1) == 1
#    @test GAP.gap_to_julia(1) == 1

    x = GAP.julia_to_gap("foo")
    #@test GAP.julia_to_gap(x) == x
    @test GAP.gap_to_julia(AbstractString,x) == "foo"
    @test GAP.gap_to_julia(Symbol,x) == :foo

    x = GAP.julia_to_gap([1,2,3])
    #@test GAP.gap_to_julia(Array{Any,1},x) == Array{Any,1}([1,2,3])
    @test GAP.gap_to_julia(Array{Int64,1},x) == [1,2,3]
    
    x = GAP.julia_to_gap(["foo"])
    #@test GAP.gap_to_julia(Array{Any,1},x) == Array{Any,1}( [ GAP.julia_to_gap("foo") ] )
    @test GAP.gap_to_julia(Array{AbstractString,1},x) == [ "foo" ]
    @test GAP.gap_to_julia(Array{Symbol,1},x) == [ :foo ]

end
