@testset "conversion from GAP" begin

    ## Defaults
    @test GAP.gap_to_julia(Any, true) == true
    @test GAP.gap_to_julia(GAP.Obj, true) == true
    @test GAP.gap_to_julia(Any, "foo") == "foo"

    ## Conversion to GAP.Obj and GAP.GapObj.
    x = GAP.evalstr("2^100")
    @test GAP.gap_to_julia(GAP.GapObj, x) == x
    @test GAP.gap_to_julia(GAP.Obj, true) == true
    x = GAP.evalstr("Z(3)")
    @test GAP.gap_to_julia(GAP.Obj, x) == x
    @test GAP.gap_to_julia(GAP.Obj, 0) == 0

    ## Integers
    @test GAP.gap_to_julia(Int128, 1) == Int128(1)
    @test GAP.gap_to_julia(Int64, 1) == Int64(1)
    @test GAP.gap_to_julia(Int32, 1) == Int32(1)
    @test GAP.gap_to_julia(Int16, 1) == Int16(1)
    @test GAP.gap_to_julia(Int8, 1) == Int8(1)

    ## Unsigned integers
    @test GAP.gap_to_julia(UInt128, 1) == UInt128(1)
    @test GAP.gap_to_julia(UInt64, 1) == UInt64(1)
    @test GAP.gap_to_julia(UInt32, 1) == UInt32(1)
    @test GAP.gap_to_julia(UInt16, 1) == UInt16(1)
    @test GAP.gap_to_julia(UInt8, 1) == UInt8(1)

    ## Border cases
    x = GAP.evalstr("2^100")
    @test_throws InexactError GAP.gap_to_julia(Int64, x)
    @test GAP.gap_to_julia(Int128, x) == BigInt(2)^100
    @test GAP.gap_to_julia(BigInt, x) == BigInt(2)^100
    x = GAP.evalstr("2^62")  # not an immediate integer
    @test GAP.gap_to_julia(Int64, x) == 2^62

    ## BigInts
    @test GAP.gap_to_julia(BigInt, 1) == BigInt(1)
    x = GAP.evalstr("2^100")
    @test GAP.gap_to_julia(BigInt, x) == BigInt(2)^100
    @test GAP.gap_to_julia(x) == BigInt(2)^100
    x = GAP.evalstr("1/2")
    @test_throws GAP.ConversionError GAP.gap_to_julia(BigInt, x)

    ## Rationals
    @test GAP.gap_to_julia(Rational{Int64}, 1) == 1 // 1
    x = GAP.evalstr("2^100")
    @test GAP.gap_to_julia(Rational{BigInt}, x) == BigInt(2)^100 // 1
    x = GAP.evalstr("2^100/3")
    @test GAP.gap_to_julia(Rational{BigInt}, x) == BigInt(2)^100 // 3
    @test GAP.gap_to_julia(x) == BigInt(2)^100 // 3
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Rational{BigInt}, x)

    ## Floats
    x = GAP.evalstr("2.")
    @test GAP.gap_to_julia(Float64, x) == 2.0
    @test GAP.gap_to_julia(x) == 2.0
    @test GAP.gap_to_julia(Float32, x) == Float32(2.0)
    @test GAP.gap_to_julia(Float16, x) == Float16(2.0)
    @test GAP.gap_to_julia(BigFloat, x) == BigFloat(2.0)
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Float64, x)

    ## Chars
    x = GAP.evalstr("'x'")
    @test GAP.gap_to_julia(Cuchar, x) == Cuchar('x')
    @test GAP.gap_to_julia(x) == Cuchar('x')
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Cuchar, x)

    ## Strings
    x = GAP.evalstr("[]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test GAP.gap_to_julia(String, x) == ""
    x = GAP.evalstr("[ 'a', 'b', 'c' ]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test GAP.gap_to_julia(String, x) == "abc"
    x = GAP.evalstr("\"foo\"")
    @test GAP.gap_to_julia(String, x) == "foo"
    @test GAP.gap_to_julia(AbstractString, x) == "foo"
    @test GAP.gap_to_julia(x) == "foo"

    ## Symbols
    @test GAP.gap_to_julia(Symbol, x) == :foo
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(AbstractString, x)

    # Convert GAP string to Vector{UInt8} (==Array{UInt8,1})
    x = GAP.evalstr("\"foo\"")
    @test GAP.gap_to_julia(Array{UInt8,1}, x) == UInt8[0x66, 0x6f, 0x6f]
    x = GAP.evalstr("[1,2,3]")
    @test GAP.gap_to_julia(Array{UInt8,1}, x) == UInt8[1, 2, 3]

    ## BitArrays
    x = GAP.evalstr("[ true, false, false, true ]")
    @test GAP.gap_to_julia(BitArray{1}, x) == [true, false, false, true]
    x = GAP.evalstr("[ 1, 0, 0, 1 ]")
    @test_throws GAP.ConversionError GAP.gap_to_julia(BitArray{1}, x)

    ## Vectors
    x = GAP.julia_to_gap([1, 2, 3])
    @test GAP.gap_to_julia(Array{Any,1}, x) == Array{Any,1}([1, 2, 3])
    @test GAP.gap_to_julia(x) == Array{Any,1}([1, 2, 3])
    @test GAP.gap_to_julia(Array{Int64,1}, x) == [1, 2, 3]
    @test GAP.gap_to_julia(Array{BigInt,1}, x) == [1, 2, 3]
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Array{Int64,1}, n)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Array{BigInt,1}, n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, 4 ] ]")
    nonrec1 = GAP.gap_to_julia(Array{GAP.GapObj,1}, x)
    nonrec2 = GAP.gap_to_julia(Array{Any,1}, x; recursive = false)
    rec = GAP.gap_to_julia(Array{Any,1}, x; recursive = true)
    @test all(x -> isa(x, GAP.GapObj), nonrec1)
    @test nonrec1 == nonrec2
    @test nonrec1 != rec
    @test all(x -> isa(x, Array), rec)
    x = [1, 2]
    y = GAP.julia_to_gap([x, x], Val(true))
    z = GAP.gap_to_julia(Vector{Any}, y)
    @test z[1] === z[2]
    x = GAP.evalstr( "NewVector( IsPlistVectorRep, Integers, [ 0, 2, 5 ] )" )
    @test GAP.gap_to_julia(x) == Array{Any,1}([0, 2, 5])
    @test GAP.gap_to_julia(Array{Int,1}, x) == Array{Int,1}([0, 2, 5])

    ## Matrices
    n = GAP.evalstr("[[1,2],[3,4]]")
    @test GAP.gap_to_julia(Array{Int64,2}, n) == [1 2; 3 4]
    xt = [(1,) (2,); (3,) (4,)]
    n = GAP.julia_to_gap(xt, Val(false))
    @test GAP.gap_to_julia(Array{Tuple{Int64},2}, n) == xt
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Array{Int64,2}, n)
    n = GAP.evalstr("[[1,2],[,4]]")
    @test GAP.gap_to_julia(Array{Union{Int64,Nothing},2}, n) == [1 2; nothing 4]
    x = [1, 2]
    m = Any[1 2; 3 4]
    m[1, 1] = x
    m[2, 2] = x
    x = GAP.julia_to_gap(m, Val(true))
    y = GAP.gap_to_julia(Array{Any,2}, x)
    @test !isa(y[1, 1], GAP.GapObj)
    @test y[1, 1] === y[2, 2]
    z = GAP.gap_to_julia(Array{Any,2}, x; recursive = false)
    @test isa(z[1, 1], GAP.GapObj)
    @test z[1, 1] === z[2, 2]
    m = GAP.evalstr( "NewMatrix( IsPlistMatrixRep, Integers, 2, [ 0, 1, 2, 3 ] )" )
    @test GAP.gap_to_julia(m) == Array{Any,2}([0 1; 2 3])
    @test GAP.gap_to_julia(Array{Int,2}, m) == Array{Int,2}([0 1; 2 3])

    ## Tuples
    x = GAP.julia_to_gap([1, 2, 3])
    @test GAP.gap_to_julia(Tuple{Int64,Any,Int32}, x) == Tuple{Int64,Any,Int32}([1, 2, 3])
    @test_throws ArgumentError GAP.gap_to_julia(Tuple{Any,Any}, x)
    @test_throws ArgumentError GAP.gap_to_julia(Tuple{Any,Any,Any,Any}, x)
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Tuple{Int64,Any,Int32}, n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, [ 4, 5 ] ] ]")
    y = GAP.gap_to_julia(Tuple{GAP.Obj,Any}, x)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], Array)
    @test isa(y[2][2], Array)
    y = GAP.gap_to_julia(Tuple{GAP.Obj,Any}, x; recursive = false)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], Array)
    @test isa(y[2][2], GAP.Obj)

    ## Ranges
    r = GAP.evalstr("[]")
    @test GAP.gap_to_julia(UnitRange{Int64}, r) == 1:0
    @test GAP.gap_to_julia(StepRange{Int64,Int64}, r) == 1:1:0
    r = GAP.evalstr("[ 1 ]")
    @test GAP.gap_to_julia(UnitRange{Int64}, r) == 1:1
    @test GAP.gap_to_julia(StepRange{Int64,Int64}, r) == 1:1:1
    r = GAP.evalstr("[ 4 .. 13 ]")
    @test GAP.gap_to_julia(UnitRange{Int64}, r) == 4:13
    @test GAP.gap_to_julia(StepRange{Int64,Int64}, r) == 4:1:13
    r = GAP.evalstr("[ 1, 4 .. 10 ]")
    @test_throws ArgumentError GAP.gap_to_julia(UnitRange{Int64}, r)
    @test GAP.gap_to_julia(StepRange{Int64,Int64}, r) == 1:3:10
    r = GAP.evalstr("[ 1, 2, 4 ]")
    @test_throws GAP.ConversionError GAP.gap_to_julia(UnitRange{Int64}, r)
    @test_throws GAP.ConversionError GAP.gap_to_julia(StepRange{Int64,Int64}, r)
    r = GAP.evalstr("rec()")
    @test_throws GAP.ConversionError GAP.gap_to_julia(UnitRange{Int64}, r)
    @test_throws GAP.ConversionError GAP.gap_to_julia(StepRange{Int64,Int64}, r)

    ## Dictionaries
    x = GAP.evalstr("rec( foo := 1, bar := \"foo\" )")
    y = Dict{Symbol,Any}(:foo => 1, :bar => "foo")
    @test GAP.gap_to_julia(Dict{Symbol,Any}, x) == y
    @test GAP.gap_to_julia(x) == y
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Dict{Symbol,Any}, n)
    x = GAP.evalstr("rec( a:= [ 1, 2 ], b:= [ 3, [ 4, 5 ] ] )")
    y = GAP.gap_to_julia(Dict{Symbol,Any}, x)
    @test isa(y, Dict)
    @test isa(y[:a], Array)
    @test isa(y[:b], Array)
    @test isa(y[:b][2], Array)
    y = GAP.gap_to_julia(Dict{Symbol,Any}, x; recursive = false)
    @test isa(y[:a], GAP.Obj)
    @test isa(y[:b], GAP.Obj)

    ## Default
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(x)

    ## Conversions involving circular references
    xx = GAP.evalstr("l:=[1];x:=[l,l];")
    conv = GAP.gap_to_julia(xx)
    @test conv[1] === conv[2]
    conv = GAP.gap_to_julia(Tuple{Tuple{Int64},Tuple{Int64}}, xx)
    @test conv[1] === conv[2]

    xx = GAP.evalstr("[~]")
    conv = GAP.gap_to_julia(xx)
    @test conv === conv[1]

    xx = GAP.evalstr("rec(a := 1, b := ~)")
    conv = GAP.gap_to_julia(xx)
    @test conv === conv[:b]

    ## Catch conversions to types that are not supported
    xx = GAP.julia_to_gap("a")
    @test_throws ErrorException GAP.gap_to_julia(Dict{Int64,Int64}, xx)

    ## Test converting GAP lists with holes in them
    xx = GAP.evalstr("[1,,1]")
    @test GAP.gap_to_julia(xx) == Any[1, nothing, 1]
    @test GAP.gap_to_julia(Array{Any,1}, xx) == Any[1, nothing, 1]
    @test_throws MethodError GAP.gap_to_julia(Array{Int64,1}, xx)
    @test GAP.gap_to_julia(Array{Union{Nothing,Int64},1}, xx) ==
          Union{Nothing,Int64}[1, nothing, 1]
    @test GAP.gap_to_julia(Array{Union{Int64,Nothing},1}, xx) ==
          Union{Nothing,Int64}[1, nothing, 1]

    ## GAP lists with Julia objects
    xx = GAP.julia_to_gap([(1,)])
    yy = GAP.gap_to_julia(Array{Tuple{Int64},1}, xx)
    @test [(1,)] == yy
    @test typeof(yy) == Array{Tuple{Int64},1}

end

@testset "conversion to GAP" begin

    ## Defaults
    @test GAP.julia_to_gap(true)

    ## Integers
    @test GAP.julia_to_gap(Int128(1)) == 1
    @test GAP.julia_to_gap(Int64(1)) == 1
    @test GAP.julia_to_gap(Int32(1)) == 1
    @test GAP.julia_to_gap(Int16(1)) == 1
    @test GAP.julia_to_gap(Int8(1)) == 1

    ## Int64 corner cases
    @test GAP.julia_to_gap(-2^60) === -2^60
    @test GAP.julia_to_gap(2^60 - 1) === 2^60 - 1

    @test GAP.Globals.IsInt(GAP.julia_to_gap(-2^60 - 1))
    @test GAP.Globals.IsInt(GAP.julia_to_gap(2^60))

    @test GAP.Globals.IsInt(GAP.julia_to_gap(-2^63 - 1))
    @test GAP.Globals.IsInt(GAP.julia_to_gap(-2^63))
    @test GAP.Globals.IsInt(GAP.julia_to_gap(2^63 - 1))
    @test GAP.Globals.IsInt(GAP.julia_to_gap(2^63))

    # see issue https://github.com/oscar-system/GAP.jl/issues/332
    @test 2^60 * GAP.Globals.Factorial(20) == GAP.evalstr("2^60 * Factorial(20)")

    ## Unsigned integers
    @test GAP.julia_to_gap(UInt128(1)) == 1
    @test GAP.julia_to_gap(UInt64(1)) == 1
    @test GAP.julia_to_gap(UInt32(1)) == 1
    @test GAP.julia_to_gap(UInt16(1)) == 1
    @test GAP.julia_to_gap(UInt8(1)) == 1

    ## BigInts
    @test GAP.julia_to_gap(BigInt(1)) == 1
    x = GAP.evalstr("2^100")
    @test GAP.julia_to_gap(BigInt(2)^100) == x

    ## Rationals
    x = GAP.evalstr("2^100")
    @test GAP.julia_to_gap(Rational{BigInt}(2)^100 // 1) == x
    x = GAP.evalstr("2^100/3")
    @test GAP.julia_to_gap(Rational{BigInt}(2)^100 // 3) == x
    @test GAP.julia_to_gap(1 // 0) == GAP.Globals.infinity
    @test GAP.julia_to_gap(-1 // 0) == -GAP.Globals.infinity

    ## Floats
    x = GAP.evalstr("2.")
    @test GAP.julia_to_gap(2.0) == x
    @test GAP.julia_to_gap(Float32(2.0)) == x
    @test GAP.julia_to_gap(Float16(2.0)) == x

    ## Chars
    x = GAP.evalstr("'x'")
    @test GAP.julia_to_gap('x') == x

    ## Strings & Symbols
    x = GAP.evalstr("\"foo\"")
    @test GAP.julia_to_gap("foo") == x
    @test GAP.julia_to_gap(:foo) == x

    ## Arrays
    x = GAP.evalstr("[1,\"foo\",2]")
    @test GAP.julia_to_gap([1, "foo", BigInt(2)], Val(true)) == x
    x = GAP.evalstr("[1,JuliaEvalString(\"\\\"foo\\\"\"),2]")
    @test GAP.julia_to_gap([1, "foo", BigInt(2)]) == x
    x = GAP.evalstr("[[1,2],[3,4]]")
    @test GAP.julia_to_gap([1 2; 3 4]) == x

    ## BitArrays
    x = GAP.evalstr("BlistList([1,2],[1])")
    y = GAP.julia_to_gap([true, false])
    @test y == x
    @test GAP.gap_to_julia(GAP.Globals.TNAM_OBJ(y)) == "list (boolean)"

    ## Tuples
    x = GAP.evalstr("[1,\"foo\",2]")
    @test GAP.julia_to_gap((1, "foo", 2), Val(true)) == x
    x = GAP.evalstr("[1,JuliaEvalString(\"\\\"foo\\\"\"),2]")
    @test GAP.julia_to_gap((1, "foo", 2)) == x

    ## Ranges
    r = GAP.evalstr("[]")
    @test GAP.julia_to_gap(1:0) == r
    @test GAP.julia_to_gap(1:1:0) == r
    r = GAP.evalstr("[ 1 ]")
    @test GAP.julia_to_gap(1:1) == r
    @test GAP.julia_to_gap(1:1:1) == r
    r = GAP.evalstr("[ 4 .. 13 ]")
    @test GAP.julia_to_gap(4:13) == r
    @test GAP.julia_to_gap(4:1:13) == r
    r = GAP.evalstr("[ 1, 4 .. 10 ]")
    @test GAP.julia_to_gap(1:3:10) == r
    @test_throws ErrorException GAP.julia_to_gap(1:2^62)

    ## Dictionaries
    x = GAP.evalstr("rec( foo := 1, bar := \"foo\" )")
    # ... recursive conversion
    y = Dict{Symbol,Any}(:foo => 1, :bar => "foo")
    @test GAP.julia_to_gap(y, Val(true)) == x
    # ... non-recursive conversion
    x = GAP.evalstr("rec( foo := 1, bar := JuliaEvalString(\"\\\"foo\\\"\") )")
    @test GAP.julia_to_gap(y) == x

    ## Conversions with identical sub-objects
    l = [1]
    yy = [l, l]
    # ... recursive conversion
    conv = GAP.julia_to_gap(yy, Val(true))
    @test conv[1] isa GAP.GapObj
    @test conv[1] === conv[2]
    # ... non-recursive conversion
    conv = GAP.julia_to_gap(yy, Val(false))
    @test isa(conv[1], Array{Int64,1})
    @test conv[1] === conv[2]

    ## converting a list with circular refs
    yy = Array{Any,1}(undef, 2)
    yy[1] = yy
    yy[2] = yy
    # ... recursive conversion
    conv = GAP.julia_to_gap(yy, Val(true))
    @test conv[1] === conv
    @test conv[1] === conv[2]
    # ... non-recursive conversion
    conv = GAP.julia_to_gap(yy, Val(false))
    @test conv[1] !== conv
    @test conv[1] === conv[2]

    ## converting a dictionary with circular refs
    d = Dict{String,Any}("a" => 1)
    d["b"] = d
    conv = GAP.julia_to_gap(d, Val(true))
    @test conv === conv.b

    ## Test converting lists with 'nothing' in them -> should be converted to a hole in the list
    xx = GAP.evalstr("[1,,1]")
    @test GAP.julia_to_gap([1, nothing, 1]) == xx

    ## Test function conversion
    return_first(args...) = args[1]
    return_first_gap = GAP.julia_to_gap(return_first)
    @test GAP.Globals.IsFunction(return_first) == false
    @test GAP.Globals.IsFunction(return_first_gap) == true
    list = GAP.evalstr("[1,2,3]")
    @test GAP.Globals.List(list, return_first_gap) == list

end
