@testset "conversion from GAP" begin

    ## Defaults
    @test GAP.gap_to_julia(GAP.GAPInputType, true )
    @test GAP.gap_to_julia(Any, "foo" ) == "foo"
    
    ## Integers
    @test GAP.gap_to_julia(Int128,1) == Int128(1)
    @test GAP.gap_to_julia(Int64 ,1) == Int64(1)
    @test GAP.gap_to_julia(Int32 ,1) == Int32(1)
    @test GAP.gap_to_julia(Int16 ,1) == Int16(1)
    @test GAP.gap_to_julia(Int8  ,1) == Int8(1)

    ## Unsigned integers
    @test GAP.gap_to_julia(UInt128,1) == UInt128(1)
    @test GAP.gap_to_julia(UInt64 ,1) == UInt64(1)
    @test GAP.gap_to_julia(UInt32 ,1) == UInt32(1)
    @test GAP.gap_to_julia(UInt16 ,1) == UInt16(1)
    @test GAP.gap_to_julia(UInt8  ,1) == UInt8(1)

    ## BigInts
    @test GAP.gap_to_julia(BigInt,1) == BigInt(1)
    x = GAP.EvalString("2^100;")[1][2]
    @test GAP.gap_to_julia(BigInt,x) == BigInt(2)^100
    @test GAP.gap_to_julia(x) == BigInt(2)^100
    x = GAP.EvalString("1/2;")[1][2]
    @test_throws ArgumentError GAP.gap_to_julia(BigInt,x)

    ## Rationals
    @test GAP.gap_to_julia(Rational{Int64},1) == 1//1
    x = GAP.EvalString("2^100;")[1][2]
    @test GAP.gap_to_julia(Rational{BigInt},x) == BigInt(2)^100 // 1
    x = GAP.EvalString("2^100/3;")[1][2]
    @test GAP.gap_to_julia(Rational{BigInt},x) == BigInt(2)^100 // 3
    @test GAP.gap_to_julia(x) == BigInt(2)^100 // 3
    x = GAP.EvalString("(1,2,3);")[1][2]
    @test_throws ArgumentError GAP.gap_to_julia(Rational{BigInt},x)

    ## Floats
    x = GAP.EvalString("2.;")[1][2]
    @test GAP.gap_to_julia(Float64,x) == 2.
    @test GAP.gap_to_julia(x) == 2.
    @test GAP.gap_to_julia(Float32,x) == Float32(2.)
    @test GAP.gap_to_julia(Float16,x) == Float16(2.)
    @test GAP.gap_to_julia(BigFloat,x) == BigFloat(2.)
    x = GAP.EvalString("(1,2,3);")[1][2]
    @test_throws ArgumentError GAP.gap_to_julia(Float64,x)

    ## Chars
    x = GAP.EvalString("'x';")[1][2]
    @test GAP.gap_to_julia(Cuchar,x) == Cuchar('x')
    @test GAP.gap_to_julia(x) == Cuchar('x')
    x = GAP.EvalString("(1,2,3);")[1][2]
    @test_throws ArgumentError GAP.gap_to_julia(Cuchar,x)

    ## Strings & Symbols
    x = GAP.EvalString("\"foo\";")[1][2]
    @test GAP.gap_to_julia(AbstractString,x) == "foo"
    @test GAP.gap_to_julia(x) == "foo"
    @test GAP.gap_to_julia(Symbol,x) == :foo
    x = GAP.EvalString("(1,2,3);")[1][2]
    @test_throws ArgumentError GAP.gap_to_julia(AbstractString,x)
    x = GAP.EvalString("\"foo\";")[1][2]
    @test GAP.gap_to_julia(Array{UInt8,1},x) == UInt8[0x66,0x6f,0x6f]
    x = GAP.EvalString("[1,2,3];")[1][2]
    @test GAP.gap_to_julia(Array{UInt8,1},x) == UInt8[1,2,3]

    ## Arrays
    x = GAP.julia_to_gap([1,2,3])
    @test GAP.gap_to_julia(Array{Any,1},x) == Array{Any,1}([1,2,3])
    @test GAP.gap_to_julia(x) == Array{Any,1}([1,2,3])
    @test GAP.gap_to_julia(Array{Int64,1},x) == [1,2,3]
    
    ## Tuples
    @test GAP.gap_to_julia(Tuple{Int64,Any,Int32},x) == Tuple{Int64,Any,Int32}([1,2,3])
    
    ## Dictionaries
    x = GAP.EvalString(" rec( foo := 1, bar := \"foo\" );" )[1][2]
    y = Dict{Symbol,Any}( :foo => 1, :bar => "foo" )
    @test GAP.gap_to_julia(Dict{Symbol,Any},x) == y
    @test GAP.gap_to_julia(x) == y

    ## Default
    x = GAP.EvalString("(1,2,3);")[1][2]
    @test GAP.gap_to_julia(x) == x

    ## Recursive conversions
    xx = GAP.EvalString("l:=[1];x:=[l,l];")[2][2]
    conv = GAP.gap_to_julia(xx)
    @test conv[1] === conv[2]
    conv = GAP.gap_to_julia(Tuple{Tuple{Int64},Tuple{Int64}},xx)
    @test conv[1] === conv[2]

end

@testset "conversion to GAP" begin

    ## Defaults
    @test GAP.julia_to_gap( true )
    
    ## Integers
    @test GAP.julia_to_gap(Int128(1)) == 1
    @test GAP.julia_to_gap(Int64(1))  == 1
    @test GAP.julia_to_gap(Int32(1))  == 1
    @test GAP.julia_to_gap(Int16(1))  == 1
    @test GAP.julia_to_gap(Int8(1))   == 1

    ## Unsigned integers
    @test GAP.julia_to_gap(UInt128(1)) == 1
    @test GAP.julia_to_gap(UInt64(1))  == 1
    @test GAP.julia_to_gap(UInt32(1))  == 1
    @test GAP.julia_to_gap(UInt16(1))  == 1
    @test GAP.julia_to_gap(UInt8(1))   == 1

    ## BigInts
    @test GAP.julia_to_gap(BigInt(1)) == 1
    x = GAP.EvalString("2^100;")[1][2]
    @test GAP.julia_to_gap(BigInt(2)^100) == x

    ## Rationals
    x = GAP.EvalString("2^100;")[1][2]
    @test GAP.julia_to_gap(Rational{BigInt}(2)^100 // 1) == x
    x = GAP.EvalString("2^100/3;")[1][2]
    @test GAP.julia_to_gap(Rational{BigInt}(2)^100 // 3) == x
    @test GAP.julia_to_gap(Rational{Int64}(1) // 0) == GAP.Globals.infinity

    ## Floats
    x = GAP.EvalString("2.;")[1][2]
    @test GAP.julia_to_gap(2.) == x
    @test GAP.julia_to_gap(Float32(2.)) == x
    @test GAP.julia_to_gap(Float16(2.)) == x

    ## Chars
    x = GAP.EvalString("'x';")[1][2]
    @test GAP.julia_to_gap('x') == x

    ## Strings & Symbols
    x = GAP.EvalString("\"foo\";")[1][2]
    @test GAP.julia_to_gap("foo") == x
    @test GAP.julia_to_gap(:foo) == x

    ## Arrays
    x = GAP.EvalString("[1,\"foo\",2];")[1][2]
    @test GAP.julia_to_gap([1,"foo",BigInt(2)],Val(true)) == x
    x = GAP.EvalString("[1,JuliaEvalString(\"\\\"foo\\\"\"),2];")[1][2]
    @test GAP.julia_to_gap([1,"foo",BigInt(2)]) == x
    
    ## Tuples
    x = GAP.EvalString("[1,\"foo\",2];")[1][2]
    @test GAP.julia_to_gap((1,"foo",2),Val(true)) == x
    x = GAP.EvalString("[1,JuliaEvalString(\"\\\"foo\\\"\"),2];")[1][2]
    @test GAP.julia_to_gap((1,"foo",2)) == x
    
    ## Dictionaries
    x = GAP.EvalString(" rec( foo := 1, bar := \"foo\" );" )[1][2]
    y = Dict{Symbol,Any}( :foo => 1, :bar => "foo" )
    @test GAP.julia_to_gap(y,Val(true)) == x
    x = GAP.EvalString(" rec( foo := 1, bar := JuliaEvalString(\"\\\"foo\\\"\") );" )[1][2]
    @test GAP.julia_to_gap(y) == x

    ## Recursive conversions
    l = [1]
    yy = [l,l]
    xx = GAP.EvalString("l:=[1];x:=[l,l];")[2][2]
    conv = GAP.julia_to_gap(xx)
    @test GAP.Globals.IsIdenticalObj(conv[1],conv[2])

end
