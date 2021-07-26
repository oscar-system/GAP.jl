@testset "conversion from GAP using convert" begin

    ## Analogous tests for conversion using constructors are in constructors.jl.

    ## Conversion to GAP.Obj and GAP.GapObj.
    x = GAP.evalstr("2^100")
    @test convert(GAP.GapObj, x) == x
    @test convert(GAP.Obj, true) == true
    x = GAP.evalstr("Z(3)")
    @test convert(GAP.Obj, x) == x
    @test convert(GAP.Obj, 0) == 0

    ## Border cases
    x = GAP.evalstr("2^100")
    @test_throws InexactError convert(Int64, x)
    @test convert(Int128, x) == BigInt(2)^100
    @test convert(BigInt, x) == BigInt(2)^100
    x = GAP.evalstr("2^62")  # not an immediate integer
    @test convert(Int64, x) == 2^62

    ## BigInts
    x = GAP.evalstr("2^100")
    @test convert(BigInt, x) == BigInt(2)^100
    x = GAP.evalstr("1/2")
    @test_throws GAP.ConversionError convert(BigInt, x)

    ## Rationals
    x = GAP.evalstr("2^100")
    @test convert(Rational{BigInt}, x) == BigInt(2)^100 // 1
    x = GAP.evalstr("2^100/3")
    @test convert(Rational{BigInt}, x) == BigInt(2)^100 // 3
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError convert(Rational{BigInt}, x)

    ## Floats
    x = GAP.evalstr("2.")
    @test convert(Float64, x) == 2.0
    @test convert(Float32, x) == Float32(2.0)
    @test convert(Float16, x) == Float16(2.0)
    @test convert(BigFloat, x) == BigFloat(2.0)
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError convert(Float64, x)

    ## Chars
    x = GAP.evalstr("'x'")
    @test convert(Cuchar, x) == Cuchar('x')
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError convert(Cuchar, x)

    ## Strings
    x = GAP.evalstr("[]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test convert(String, x) == ""
    x = GAP.evalstr("[ 'a', 'b', 'c' ]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test convert(String, x) == "abc"
    x = GAP.evalstr("\"foo\"")
    @test convert(String, x) == "foo"
    @test convert(AbstractString, x) == "foo"

    ## Symbols
    @test convert(Symbol, x) == :foo
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError convert(AbstractString, x)

    # Convert GAP string to Vector{UInt8} (==Vector{UInt8})
    x = GAP.evalstr("\"foo\"")
    @test convert(Vector{UInt8}, x) == UInt8[0x66, 0x6f, 0x6f]
    x = GAP.evalstr("[1,2,3]")
    @test convert(Vector{UInt8}, x) == UInt8[1, 2, 3]

    ## BitArrays
    x = GAP.evalstr("[ true, false, false, true ]")
    @test convert(BitArray{1}, x) == [true, false, false, true]
    x = GAP.evalstr("[ 1, 0, 0, 1 ]")
    @test_throws GAP.ConversionError convert(BitArray{1}, x)

    ## Vectors
    x = GAP.julia_to_gap([1, 2, 3])
    @test convert(Vector{Any}, x) == Vector{Any}([1, 2, 3])
    @test convert(Vector{Int64}, x) == [1, 2, 3]
    @test convert(Vector{BigInt}, x) == [1, 2, 3]
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError convert(Vector{Int64}, n)
    @test_throws GAP.ConversionError convert(Vector{BigInt}, n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, 4 ] ]")
    nonrec1 = convert(Vector{GAP.GapObj}, x)
    nonrec2 = convert(Vector{Any}, x; recursive = false)
    rec = convert(Vector{Any}, x; recursive = true)
    @test all(x -> isa(x, GAP.GapObj), nonrec1)
    @test nonrec1 == nonrec2
    @test nonrec1 != rec
    @test all(x -> isa(x, Array), rec)
    x = [1, 2]
    y = GAP.julia_to_gap([x, x]; recursive = true)
    z = convert(Vector{Any}, y)
    @test z[1] === z[2]

    ## Matrices
    n = GAP.evalstr("[[1,2],[3,4]]")
    @test convert(Matrix{Int64}, n) == [1 2; 3 4]
    xt = [(1,) (2,); (3,) (4,)]
    n = GAP.julia_to_gap(xt; recursive = false)
    @test convert(Matrix{Tuple{Int64}}, n) == xt
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError convert(Matrix{Int64}, n)
    n = GAP.evalstr("[[1,2],[,4]]")
    #@test convert(Matrix{Union{Int64,Nothing}}, n) == [1 2; nothing 4]
    x = [1, 2]
    m = Any[1 2; 3 4]
    m[1, 1] = x
    m[2, 2] = x
    x = GAP.julia_to_gap(m; recursive = true)
    y = convert(Matrix{Any}, x)
    @test !isa(y[1, 1], GAP.GapObj)
    @test y[1, 1] === y[2, 2]
    z = convert(Matrix{Any}, x; recursive = false)
    @test isa(z[1, 1], GAP.GapObj)
    @test z[1, 1] === z[2, 2]

    ## Tuples
    x = GAP.julia_to_gap([1, 2, 3])
    @test convert(Tuple{Int64,Any,Int32}, x) == Tuple{Int64,Any,Int32}([1, 2, 3])
    @test_throws ArgumentError convert(Tuple{Any,Any}, x)
    @test_throws ArgumentError convert(Tuple{Any,Any,Any,Any}, x)
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError convert(Tuple{Int64,Any,Int32}, n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, [ 4, 5 ] ] ]")
    y = convert(Tuple{GAP.Obj,Any}, x)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], Array)
    @test isa(y[2][2], Array)
    y = convert(Tuple{GAP.Obj,Any}, x; recursive = false)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], Array)
    @test isa(y[2][2], GAP.Obj)

    ## Ranges
    r = GAP.evalstr("[]")
    @test convert(UnitRange{Int64}, r) == 1:0
    @test convert(StepRange{Int64,Int64}, r) == 1:1:0
    r = GAP.evalstr("[ 1 ]")
    @test convert(UnitRange{Int64}, r) == 1:1
    @test convert(StepRange{Int64,Int64}, r) == 1:1:1
    r = GAP.evalstr("[ 4 .. 13 ]")
    @test convert(UnitRange{Int64}, r) == 4:13
    @test convert(StepRange{Int64,Int64}, r) == 4:1:13
    r = GAP.evalstr("[ 1, 4 .. 10 ]")
    @test_throws ArgumentError convert(UnitRange{Int64}, r)
    @test convert(StepRange{Int64,Int64}, r) == 1:3:10
    r = GAP.evalstr("[ 1, 2, 4 ]")
    @test_throws GAP.ConversionError convert(UnitRange{Int64}, r)
    @test_throws GAP.ConversionError convert(StepRange{Int64,Int64}, r)
    r = GAP.evalstr("rec()")
    @test_throws GAP.ConversionError convert(UnitRange{Int64}, r)
    @test_throws GAP.ConversionError convert(StepRange{Int64,Int64}, r)

    ## Dictionaries
    x = GAP.evalstr("rec( foo := 1, bar := \"foo\" )")
    y = Dict{Symbol,Any}(:foo => 1, :bar => "foo")
    @test convert(Dict{Symbol,Any}, x) == y
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError convert(Dict{Symbol,Any}, n)
    x = GAP.evalstr("rec( a:= [ 1, 2 ], b:= [ 3, [ 4, 5 ] ] )")
    y = convert(Dict{Symbol,Any}, x)
    @test isa(y, Dict)
    @test isa(y[:a], Array)
    @test isa(y[:b], Array)
    @test isa(y[:b][2], Array)
    y = convert(Dict{Symbol,Any}, x; recursive = false)
    @test isa(y[:a], GAP.Obj)
    @test isa(y[:b], GAP.Obj)

    ## Conversions involving circular references
    xx = GAP.evalstr("l:=[1];x:=[l,l];")
    conv = convert(Tuple{Tuple{Int64},Tuple{Int64}}, xx)
    @test conv[1] === conv[2]

    ## Test converting GAP lists with holes in them
    xx = GAP.evalstr("[1,,1]")
    @test convert(Vector{Any}, xx) == Any[1, nothing, 1]
    @test_throws MethodError convert(Vector{Int64}, xx)
    @test convert(Vector{Union{Nothing,Int64}}, xx) == Union{Nothing,Int64}[1, nothing, 1]
    @test convert(Vector{Union{Int64,Nothing}}, xx) == Union{Nothing,Int64}[1, nothing, 1]

    ## GAP lists with Julia objects
    xx = GAP.julia_to_gap([(1,)])
    yy = convert(Vector{Tuple{Int64}}, xx)
    @test [(1,)] == yy
    @test typeof(yy) == Vector{Tuple{Int64}}

end
