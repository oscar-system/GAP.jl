@testset "conversion from GAP" begin

  @testset "Defaults" begin
    @test GAP.gap_to_julia(Any, true) == true
    @test GAP.gap_to_julia(GAP.Obj, true) == true
    @test GAP.gap_to_julia(Any, "foo") == "foo"
  end

  @testset "Conversion to GAP.Obj and GAP.GapObj" begin
    x = GAP.evalstr("2^100")
    @test GAP.gap_to_julia(GAP.GapObj, x) == x
    @test GAP.gap_to_julia(GAP.Obj, true) == true
    x = GAP.evalstr("Z(3)")
    @test GAP.gap_to_julia(GAP.Obj, x) == x
    @test GAP.gap_to_julia(GAP.Obj, 0) == 0
  end

  @testset "Integers" begin
    @test (@inferred GAP.gap_to_julia(Int128, 1)) == Int128(1)
    @test (@inferred GAP.gap_to_julia(Int64, 1)) == Int64(1)
    @test (@inferred GAP.gap_to_julia(Int32, 1)) == Int32(1)
    @test (@inferred GAP.gap_to_julia(Int16, 1)) == Int16(1)
    @test (@inferred GAP.gap_to_julia(Int8, 1)) == Int8(1)
  end

  @testset "Unsigned integers" begin
    @test (@inferred GAP.gap_to_julia(UInt128, 1)) == UInt128(1)
    @test (@inferred GAP.gap_to_julia(UInt64, 1)) == UInt64(1)
    @test (@inferred GAP.gap_to_julia(UInt32, 1)) == UInt32(1)
    @test (@inferred GAP.gap_to_julia(UInt16, 1)) == UInt16(1)
    @test (@inferred GAP.gap_to_julia(UInt8, 1)) == UInt8(1)
  end

  @testset "Border cases" begin
    x = GAP.evalstr("2^100")
    @test_throws InexactError GAP.gap_to_julia(Int64, x)
    @test (@inferred GAP.gap_to_julia(Int128, x)) == BigInt(2)^100
    @test (@inferred GAP.gap_to_julia(BigInt, x)) == BigInt(2)^100
    x = GAP.evalstr("2^62")  # not an immediate integer
    @test (@inferred GAP.gap_to_julia(Int64, x)) == 2^62
  end

  @testset "BigInts" begin
    @test (@inferred GAP.gap_to_julia(BigInt, 1)) == BigInt(1)
    x = GAP.evalstr("2^100")
    @test (@inferred GAP.gap_to_julia(BigInt, x)) == BigInt(2)^100
    @test GAP.gap_to_julia(x) == BigInt(2)^100
    x = GAP.evalstr("1/2")
    @test_throws GAP.ConversionError GAP.gap_to_julia(BigInt, x)
  end

  @testset "Rationals" begin
    @test (@inferred GAP.gap_to_julia(Rational{Int64}, 1)) == 1 // 1
    x = GAP.evalstr("2^100")
    @test (@inferred GAP.gap_to_julia(Rational{BigInt}, x)) == BigInt(2)^100 // 1
    x = GAP.evalstr("2^100/3")
    @test (@inferred GAP.gap_to_julia(Rational{BigInt}, x)) == BigInt(2)^100 // 3
    @test GAP.gap_to_julia(x) == BigInt(2)^100 // 3
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Rational{BigInt}, x)
  end

  @testset "Floats" begin
    x = GAP.evalstr("2.")
    @test (@inferred GAP.gap_to_julia(Float64, x)) == 2.0
    @test GAP.gap_to_julia(x) == 2.0
    @test (@inferred GAP.gap_to_julia(Float32, x)) == Float32(2.0)
    @test (@inferred GAP.gap_to_julia(Float16, x)) == Float16(2.0)
    @test (@inferred GAP.gap_to_julia(BigFloat, x)) == BigFloat(2.0)
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Float64, x)
  end

  @testset "Chars" begin
    x = GAP.evalstr("'x'")
    @test (@inferred GAP.gap_to_julia(Cuchar, x)) == Cuchar('x')
    @test GAP.gap_to_julia(x) == Cuchar('x')
    @test GAP.gap_to_julia(Char, x) == Char('x')
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Cuchar, x)
  end

  @testset "Strings" begin
    x = GAP.evalstr("[]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test (@inferred GAP.gap_to_julia(String, x)) == ""
    x = GAP.evalstr("[ 'a', 'b', 'c' ]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test (@inferred GAP.gap_to_julia(String, x)) == "abc"
    x = GAP.evalstr("\"foo\"")
    @test (@inferred GAP.gap_to_julia(String, x)) == "foo"
    @test GAP.gap_to_julia(x) == "foo"
    x = "abc\000def"
    @test GAP.gap_to_julia(GAP.julia_to_gap(x)) == x
    x = "jμΛIα"
    @test GAP.gap_to_julia(GAP.julia_to_gap(x)) == x
  end

  @testset "Symbols" begin
    x = GAP.evalstr("\"foo\"")
    @test (@inferred GAP.gap_to_julia(Symbol, x)) == :foo
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(String, x)

    # Convert GAP string to Vector{UInt8} (==Vector{UInt8})
    x = GAP.evalstr("\"foo\"")
    @test (@inferred GAP.gap_to_julia(Vector{UInt8}, x)) == UInt8[0x66, 0x6f, 0x6f]
    x = GAP.evalstr("[1,2,3]")
    @test (@inferred GAP.gap_to_julia(Vector{UInt8}, x)) == UInt8[1, 2, 3]
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Vector{UInt8}, x)
  end

  @testset "BitVectors" begin
    x = GAP.evalstr("[ true, false, false, true ]")
    @test (@inferred GAP.gap_to_julia(BitVector, x)) == [true, false, false, true]
    x = GAP.evalstr("[ 1, 0, 0, 1 ]")
    @test_throws GAP.ConversionError GAP.gap_to_julia(BitVector, x)
  end

  @testset "Vectors" begin
    x = GAP.julia_to_gap([1, 2, 3])
    @test (@inferred GAP.gap_to_julia(Vector{Any}, x)) == Vector{Any}([1, 2, 3])
    @test GAP.gap_to_julia(x) == Vector{Any}([1, 2, 3])
    @test (@inferred GAP.gap_to_julia(Vector{Int64}, x)) == [1, 2, 3]
    @test (@inferred GAP.gap_to_julia(Vector{BigInt}, x)) == [1, 2, 3]
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Vector{Int64}, n)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Vector{BigInt}, n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, 4 ] ]")
    nonrec1 = @inferred GAP.gap_to_julia(Vector{GAP.GapObj}, x)
    nonrec2 = @inferred GAP.gap_to_julia(Vector{Any}, x; recursive = false)
    rec = GAP.gap_to_julia(Vector{Any}, x; recursive = true)
    @test all(x -> isa(x, GAP.GapObj), nonrec1)
    @test nonrec1 == nonrec2
    @test nonrec1 != rec
    @test all(x -> isa(x, Array), rec)
    x = [1, 2]
    y = GAP.julia_to_gap([x, x]; recursive = true)
    z = GAP.gap_to_julia(Vector{Any}, y)
    @test z[1] === z[2]
    x = GAP.evalstr( "NewVector( IsPlistVectorRep, Integers, [ 0, 2, 5 ] )" )
    @test GAP.gap_to_julia(x) == Vector{Any}([0, 2, 5])
    @test GAP.gap_to_julia(Vector{Int}, x) == Vector{Int}([0, 2, 5])
  end

  @testset "Matrices" begin
    n = GAP.evalstr("[[1,2],[3,4]]")
    @test (@inferred GAP.gap_to_julia(Matrix{Int64}, n)) == [1 2; 3 4]
    xt = [(1,) (2,); (3,) (4,)]
    n = GAP.julia_to_gap(xt; recursive = false)
    @test (@inferred GAP.gap_to_julia(Matrix{Tuple{Int64}}, n)) == xt
    n = GAP.julia_to_gap(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Matrix{Int64}, n)
    #n = GAP.evalstr("[[1,2],[,4]]")
    #@test GAP.gap_to_julia(Matrix{Union{Int64,Nothing}}, n) == [1 2; nothing 4]
    x = [1, 2]
    m = Any[1 2; 3 4]
    m[1, 1] = x
    m[2, 2] = x
    x = GAP.julia_to_gap(m; recursive = true)
    y = GAP.gap_to_julia(Matrix{Any}, x)
    @test !isa(y[1, 1], GAP.GapObj)
    @test y[1, 1] === y[2, 2]
    z = GAP.gap_to_julia(Matrix{Any}, x; recursive = false)
    @test isa(z[1, 1], GAP.GapObj)
    @test z[1, 1] === z[2, 2]
    m = GAP.evalstr( "NewMatrix( IsPlistMatrixRep, Integers, 2, [ 0, 1, 2, 3 ] )" )
    @test GAP.gap_to_julia(m) == Matrix{Any}([0 1; 2 3])
    @test GAP.gap_to_julia(Matrix{Int}, m) == Matrix{Int}([0 1; 2 3])
  end

  @testset "Sets" begin
    x = GAP.evalstr("[ [ 1 ], [ 2 ], [ 1 ] ]")
    y = [GAP.evalstr("[ 1 ]"), GAP.evalstr("[ 2 ]")]
    @test (@inferred GAP.gap_to_julia(Set{Vector{Int}}, x)) == Set([[1], [2], [1]])
    #@test @inferred GAP.gap_to_julia(Set{GAP.GapObj}, x, recursive = false) == Set(y)
    #@test @inferred GAP.gap_to_julia(Set{Any}, x, recursive = false) == Set(y)
    @test (@inferred GAP.gap_to_julia(Set{Any}, x)) == Set([[1], [2], [1]])
    x = GAP.evalstr("[ Z(2), Z(3) ]")  # a non-collection
    y = [GAP.evalstr("Z(2)"), GAP.evalstr("Z(3)")]
    #@test GAP.gap_to_julia(Set{GAP.FFE}, x) == Set(y)
  end

  @testset "Tuples" begin
    x = GAP.julia_to_gap([1, 2, 3])
    @test (@inferred GAP.gap_to_julia(Tuple{Int64,Int16,Int32}, x)) == (1, 2, 3)
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
  end

  @testset "Ranges" begin
    r = GAP.evalstr("[]")
    @test (@inferred GAP.gap_to_julia(UnitRange{Int64}, r)) == 1:0
    @test (@inferred GAP.gap_to_julia(StepRange{Int64,Int64}, r)) == 1:1:0
    r = GAP.evalstr("[ 1 ]")
    @test (@inferred GAP.gap_to_julia(UnitRange{Int64}, r)) == 1:1
    @test (@inferred GAP.gap_to_julia(StepRange{Int64,Int64}, r)) == 1:1:1
    r = GAP.evalstr("[ 4 .. 13 ]")
    @test (@inferred GAP.gap_to_julia(UnitRange{Int64}, r)) == 4:13
    @test (@inferred GAP.gap_to_julia(StepRange{Int64,Int64}, r)) == 4:1:13
    r = GAP.evalstr("[ 1, 4 .. 10 ]")
    @test_throws ArgumentError GAP.gap_to_julia(UnitRange{Int64}, r)
    @test (@inferred GAP.gap_to_julia(StepRange{Int64,Int64}, r)) == 1:3:10
    r = GAP.evalstr("[ 1, 2, 4 ]")
    @test_throws GAP.ConversionError GAP.gap_to_julia(UnitRange{Int64}, r)
    @test_throws GAP.ConversionError GAP.gap_to_julia(StepRange{Int64,Int64}, r)
    r = GAP.evalstr("rec()")
    @test_throws GAP.ConversionError GAP.gap_to_julia(UnitRange{Int64}, r)
    @test_throws GAP.ConversionError GAP.gap_to_julia(StepRange{Int64,Int64}, r)
  end

  @testset "Dictionaries" begin
    x = GAP.evalstr("rec( foo := 1, bar := \"foo\" )")
    y = Dict{Symbol,Any}(:foo => 1, :bar => "foo")
    @test (@inferred GAP.gap_to_julia(Dict{Symbol,Any}, x)) == y
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
  end

  @testset "Default" begin
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(x)
  end

  @testset "Conversions involving circular references" begin
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
  end

  @testset "Catch conversions to types that are not supported" begin
    xx = GAP.julia_to_gap("a")
    @test_throws ErrorException GAP.gap_to_julia(Dict{Int64,Int64}, xx)
  end

  @testset "Test converting GAP lists with holes in them" begin
    xx = GAP.evalstr("[1,,1]")
    @test GAP.gap_to_julia(xx) == Any[1, nothing, 1]
    @test GAP.gap_to_julia(Vector{Any}, xx) == Any[1, nothing, 1]
    @test_throws MethodError GAP.gap_to_julia(Vector{Int64}, xx)
    @test GAP.gap_to_julia(Vector{Union{Nothing,Int64}}, xx) ==
          Union{Nothing,Int64}[1, nothing, 1]
    @test GAP.gap_to_julia(Vector{Union{Int64,Nothing}}, xx) ==
          Union{Nothing,Int64}[1, nothing, 1]
  end

  @testset "GAP lists with Julia objects" begin
    xx = GAP.julia_to_gap([(1,)])
    yy = GAP.gap_to_julia(Vector{Tuple{Int64}}, xx)
    @test [(1,)] == yy
    @test typeof(yy) == Vector{Tuple{Int64}}

end

@testset "conversion to GAP" begin
  end

  @testset "Defaults" begin
    @test GAP.julia_to_gap(true)
  end

  @testset "Integers" begin
    for i in -2:2
        @test GAP.julia_to_gap(Int128(i)) == i
        @test GAP.julia_to_gap(Int64(i)) == i
        @test GAP.julia_to_gap(Int32(i)) == i
        @test GAP.julia_to_gap(Int16(i)) == i
        @test GAP.julia_to_gap(Int8(i)) == i
    end
  end

  @testset "Int64 corner cases" begin
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
  end

  @testset "Unsigned integers" begin
    @test GAP.julia_to_gap(UInt128(1)) == 1
    @test GAP.julia_to_gap(UInt64(1)) == 1
    @test GAP.julia_to_gap(UInt32(1)) == 1
    @test GAP.julia_to_gap(UInt16(1)) == 1
    @test GAP.julia_to_gap(UInt8(1)) == 1
  end

  @testset "BigInts" begin
    for i = -2:2
        @test GAP.julia_to_gap(BigInt(i)) == i
    end
    x = GAP.evalstr("2^100")
    @test GAP.julia_to_gap(BigInt(2)^100) == x
    @test GAP.julia_to_gap(-BigInt(2)^100) == -x
  end

  @testset "Rationals" begin
    x = GAP.evalstr("2^100")
    @test GAP.julia_to_gap(Rational{BigInt}(2)^100 // 1) == x
    x = GAP.evalstr("2^100/3")
    @test GAP.julia_to_gap(Rational{BigInt}(2)^100 // 3) == x
    @test GAP.julia_to_gap(1 // 0) == GAP.Globals.infinity
    @test GAP.julia_to_gap(-1 // 0) == -GAP.Globals.infinity
  end

  @testset "Floats" begin
    x = GAP.evalstr("2.")
    @test GAP.julia_to_gap(2.0) == x
    @test GAP.julia_to_gap(Float32(2.0)) == x
    @test GAP.julia_to_gap(Float16(2.0)) == x
  end

  @testset "Chars" begin
    x = GAP.evalstr("'x'")
    @test GAP.julia_to_gap('x') == x
  end

  @testset "Strings & Symbols" begin
    x = GAP.evalstr("\"foo\"")
    @test GAP.julia_to_gap("foo") == x
    @test GAP.julia_to_gap(:foo) == x
    substr = match(r"a(.*)c", "abc").match  # type is `SubString{String}`
    @test GAP.julia_to_gap(substr) == GAP.julia_to_gap("abc")
    @test length(GAP.julia_to_gap("abc\000def")) == 7  # contains a null character
    x = GAP.evalstr("\"jμΛIα\"")
    @test length(x) == 8  # in GAP, the number of bytes
    @test GAP.julia_to_gap("jμΛIα") == x
    @test length("jμΛIα") == 5
    @test sizeof("jμΛIα") == 8
  end

  @testset "Arrays" begin
    x = GAP.evalstr("[1,\"foo\",2]")
    @test GAP.julia_to_gap([1, "foo", BigInt(2)]; recursive = true) == x
    x = GAP.evalstr("[1,JuliaEvalString(\"\\\"foo\\\"\"),2]")
    @test GAP.julia_to_gap([1, "foo", BigInt(2)]) == x
    x = GAP.evalstr("[[1,2],[3,4]]")
    @test GAP.julia_to_gap([1 2; 3 4]) == x
  end

  @testset "BitVectors" begin
    x = GAP.evalstr("BlistList([1,2],[1])")
    y = GAP.julia_to_gap([true, false])
    @test y == x
    @test GAP.gap_to_julia(GAP.Globals.TNAM_OBJ(y)) == "list (boolean)"
  end

  @testset "Tuples" begin
    x = GAP.evalstr("[1,\"foo\",2]")
    @test GAP.julia_to_gap((1, "foo", 2); recursive = true) == x
    x = GAP.evalstr("[1,JuliaEvalString(\"\\\"foo\\\"\"),2]")
    @test GAP.julia_to_gap((1, "foo", 2)) == x
  end

  @testset "Ranges" begin
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
    @test_throws GAP.ConversionError GAP.julia_to_gap(1:2^62)
  end

  @testset "Dictionaries" begin
    x = GAP.evalstr("rec( foo := 1, bar := \"foo\" )")
    y = Dict{Symbol,Any}(:foo => 1, :bar => "foo")
    z = GAP.evalstr("rec( foo := 1, bar := JuliaEvalString(\"\\\"foo\\\"\") )")
    # ... recursive conversion
    @test GAP.julia_to_gap(y; recursive = true) == x
    # ... non-recursive conversion
    @test GAP.julia_to_gap(y) == z

    # also test the case were the top level is a GapObj but inside
    # there are Julia objects
    @test GAP.julia_to_gap(z; recursive=true) == x
    @test GAP.julia_to_gap(z; recursive=false) == z  # nothing happens without recursion
  end

  @testset "Conversions with identical sub-objects" begin
    l = [1]
    yy = [l, l]
    # ... recursive conversion
    conv = GAP.julia_to_gap(yy; recursive = true)
    @test conv[1] isa GAP.GapObj
    @test conv[1] === conv[2]
    # ... non-recursive conversion
    conv = GAP.julia_to_gap(yy; recursive = false)
    @test isa(conv[1], Vector{Int64})
    @test conv[1] === conv[2]
  end

  @testset "converting a list with circular refs" begin
    yy = Vector{Any}(undef, 2)
    yy[1] = yy
    yy[2] = yy
    # ... recursive conversion
    conv = GAP.julia_to_gap(yy; recursive = true)
    @test conv[1] === conv
    @test conv[1] === conv[2]
    # ... non-recursive conversion
    conv = GAP.julia_to_gap(yy; recursive = false)
    @test conv[1] !== conv
    @test conv[1] === conv[2]
  end

  @testset "converting a dictionary with circular refs" begin
    d = Dict{String,Any}("a" => 1)
    d["b"] = d
    conv = GAP.julia_to_gap(d; recursive = true)
    @test conv === conv.b
  end

  @testset "Test converting lists with 'nothing' in them -> should be converted to a hole in the list" begin
    xx = GAP.evalstr("[1,,1]")
    @test GAP.julia_to_gap([1, nothing, 1]) == xx
  end

  @testset "Convert GAP objects recursively" begin
    val = GAP.julia_to_gap([])
    val[1] = [1, 2]
    val[2] = [3, 4]
    nonrec = GAP.julia_to_gap(val)
    @test nonrec[1] == [1, 2]
    rec = GAP.julia_to_gap(val, recursive = true)
    @test rec[1] == GAP.julia_to_gap([1, 2])
    @test GAP.julia_to_gap(1, recursive = false) == 1
  end

  @testset "Test function conversion" begin
    return_first(args...) = args[1]
    return_first_gap = GAP.julia_to_gap(return_first)
    @test GAP.Globals.IsFunction(return_first) == false
    @test GAP.Globals.IsFunction(return_first_gap) == true
    list = GAP.evalstr("[1,2,3]")
    @test GAP.Globals.List(list, return_first_gap) == list
  end

end

@testset "(Un)WrapJuliaFunc" begin
    # wrap a Julia function
    f = x -> x^2
    g = GAP.WrapJuliaFunc(f)
    @test g isa GapObj
    @test GAP.TNUM_OBJ(g) == GAP.T_FUNCTION
    @test g(2) == 4
    @test GAP.UnwrapJuliaFunc(g) === f

    # "wrap" a callable Julia object that is not a function
    struct Callable data::Int end
    (obj::Callable)() = obj.data
    x = Callable(17)
    @test x() == 17
    @test !(x isa Function)
    @test !(x isa Base.Callable)
    wx = GAP.WrapJuliaFunc(x)
    @test x === GAP.UnwrapJuliaFunc(wx)
    @test GAP.Globals.CallFuncList(wx, GAP.evalstr("[]")) == x()
end
