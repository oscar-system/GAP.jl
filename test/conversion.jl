#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

@testset "conversion from GAP" begin

  @testset "Defaults" begin
    @test GAP.gap_to_julia(true) == true
    @test GAP.gap_to_julia(1) == 1
    @test GAP.gap_to_julia(GAP.Globals.Z(3)) == GAP.Globals.Z(3)
    @test GAP.gap_to_julia(Any, true) == true
    @test GAP.gap_to_julia(GAP.Obj, true) == true
    @test GAP.gap_to_julia(Any, "foo") == "foo"
  end

  @testset "Conversion to GAP.Obj and GapObj" begin
    x = GAP.evalstr("2^100")
    @test GAP.gap_to_julia(GapObj, x) == x
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
    @test (@inferred GAP.gap_to_julia(Char, x)) == Char('x')
    @test (@inferred GAP.gap_to_julia(Cuchar, x)) == Cuchar('x')
    @test GAP.gap_to_julia(x) == Cuchar('x')

    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Char, x)
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
    @test GAP.gap_to_julia(GapObj(x)) == x
    x = "jμΛIα"
    @test GAP.gap_to_julia(GapObj(x)) == x
  end

  @testset "Symbols" begin
    x = GAP.evalstr("\"foo\"")
    @test (@inferred GAP.gap_to_julia(Symbol, x)) == :foo
    x = GAP.evalstr("['f','o','o']")
    @test (@inferred GAP.gap_to_julia(Symbol, x)) == :foo
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Symbol, x)
  end

  @testset "Vector{UInt8}" begin
    # Convert GAP string to Vector{UInt8} (==Vector{UInt8})
    x = GAP.evalstr("\"foo\"")
    @test (@inferred GAP.gap_to_julia(Vector{UInt8}, x)) == UInt8[0x66, 0x6f, 0x6f]
    x = GAP.evalstr("['f','o','o']")
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
    x = GapObj([1, 2, 3])

    # unspecified target type
    @test GAP.gap_to_julia(x) == Vector{Any}([1, 2, 3])
    @test (@inferred GAP.gap_to_julia(Vector, x)) == Vector{Any}([1, 2, 3])
    @test (@inferred GAP.gap_to_julia(Vector{Any}, x)) == Vector{Any}([1, 2, 3])

    # specified target type
    @test (@inferred GAP.gap_to_julia(Vector{Int64}, x)) == [1, 2, 3]
    @test (@inferred GAP.gap_to_julia(Vector{BigInt}, x)) == [1, 2, 3]

    # specified target type and recursion
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, 4 ] ]")
    nonrec1 = @inferred GAP.gap_to_julia(Vector{GapObj}, x)
    nonrec2 = @inferred GAP.gap_to_julia(Vector{Any}, x)
    nonrec3 = @inferred GAP.gap_to_julia(Vector{Vector{Int}}, x)
    rec1 = @inferred GAP.gap_to_julia(Vector{GapObj}, x; recursive = true)
    rec2 = @inferred GAP.gap_to_julia(Vector{Any}, x; recursive = true)
    rec3 = @inferred GAP.gap_to_julia(Vector{Vector{Int}}, x; recursive = true)
    @test all(x -> isa(x, GapObj), nonrec1)
    @test all(x -> isa(x, GapObj), nonrec2)
    @test all(x -> isa(x, GapObj), rec1)
    @test all(x -> isa(x, Array), nonrec3)
    @test all(x -> isa(x, Array), rec2)
    @test all(x -> isa(x, Array), rec3)
    @test nonrec1 == nonrec2 == rec1
    @test nonrec3 == rec2 == rec3
    @test nonrec1 != rec2

    x = GAP.evalstr("[ [ 1, 2 ], ~[1] ]")
    rec = @inferred GAP.gap_to_julia(Vector{Vector{Int}}, x; recursive = true)
    nonrec = @inferred GAP.gap_to_julia(Vector{Vector{Int}}, x)
    @test rec == nonrec
    @test rec[1] === rec[2]
    @test nonrec[1] !== nonrec[2]

    rec1 = GAP.gap_to_julia(Vector{Any}, x; recursive = true)
    nonrec1 = GAP.gap_to_julia(Vector{Any}, x)
    @test rec1[1] === rec1[2]
    @test nonrec1[1] === nonrec1[2]

    x = GAP.evalstr( "NewVector( IsPlistVectorRep, Integers, [ 0, 2, 5 ] )" )
    @test GAP.gap_to_julia(x) == Vector{Any}([0, 2, 5])
    @test GAP.gap_to_julia(Vector{Int}, x) == Vector{Int}([0, 2, 5])

    x = GAP.evalstr( "[ [ 1, 2 ], ~[1] ]" )
    y = GAP.gap_to_julia(Vector{Set{Int}}, x; recursive = true)
    @test y[1] === y[2]

    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Vector{Int64}, n)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Vector{BigInt}, n)
  end

  @testset "Matrices" begin
    n = GAP.evalstr("[[1,2],[3,4]]")
    @test GAP.gap_to_julia(n; recursive = true) == Vector{Any}([[1, 2], [3, 4]])
    @test (@inferred GAP.gap_to_julia(Matrix, n)) == Matrix{Any}([1 2; 3 4])
    @test (@inferred GAP.gap_to_julia(Matrix{Any}, n)) == Matrix{Any}([1 2; 3 4])
    @test (@inferred GAP.gap_to_julia(Matrix{Int64}, n)) == [1 2; 3 4]
    xt = [(1,) (2,); (3,) (4,)]
    n = GapObj(xt)
    @test (@inferred GAP.gap_to_julia(Matrix{Tuple{Int64}}, n)) == xt
    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Matrix{Int64}, n)
    #n = GAP.evalstr("[[1,2],[,4]]")
    #@test GAP.gap_to_julia(Matrix{Union{Int64,Nothing}}, n) == [1 2; nothing 4]
    x = [1, 2]
    m = Any[1 2; 3 4]
    m[1, 1] = x
    m[2, 2] = x
    x = GapObj(m; recursive = true)
    y = GAP.gap_to_julia(Matrix{Any}, x; recursive = true)
    @test !isa(y[1, 1], GapObj)
    @test y[1, 1] === y[2, 2]
    z = GAP.gap_to_julia(Matrix{Any}, x)
    @test isa(z[1, 1], GapObj)
    @test z[1, 1] === z[2, 2]
    m = GAP.evalstr( "NewMatrix( IsPlistMatrixRep, Integers, 2, [ 0, 1, 2, 3 ] )" )
    @test GAP.gap_to_julia(m) == Matrix([0 1; 2 3])
    @test GAP.gap_to_julia(m) == Matrix{Any}([0 1; 2 3])
    @test GAP.gap_to_julia(Matrix{Int}, m) == Matrix{Int}([0 1; 2 3])
  end

  @testset "Sets" begin
    x = GAP.evalstr("[ [ 1 ], [ 2 ], [ 1 ] ]")
    y = [GAP.evalstr("[ 1 ]"), GAP.evalstr("[ 2 ]")]
    @test GAP.gap_to_julia(Set, x; recursive = true) == Set([[1], [2]])
    @test (@inferred GAP.gap_to_julia(Set{Any}, x; recursive = true)) == Set([[1], [2]])
    @test (@inferred GAP.gap_to_julia(Set{Vector}, x)) == Set([[1], [2]])
    @test (@inferred GAP.gap_to_julia(Set{Vector{Any}}, x)) == Set([[1], [2]])
    @test (@inferred GAP.gap_to_julia(Set{Vector{Int}}, x)) == Set([[1], [2], [1]])

    # `Set`s of `GapObj`s are not possible, due to missing hash values.
    @test_throws ErrorException GAP.gap_to_julia(Set{GapObj}, x)
    @test_throws ErrorException GAP.gap_to_julia(Set{GapObj}, x, recursive = true)
    @test_throws ErrorException Set(y)
    @test_throws ErrorException GAP.gap_to_julia(Set{Any}, x)
    x = GAP.evalstr("[ Z(2), Z(3) ]")
    y = [GAP.evalstr("Z(2)"), GAP.evalstr("Z(3)")]
    @test_throws ErrorException GAP.gap_to_julia(Set{GAP.FFE}, x)
    @test_throws ErrorException Set(y)
    @test GAP.gap_to_julia(Set{Int}, GAP.evalstr("[ 1, true ]")) == Set([1, true])
    @test_throws GAP.ConversionError GAP.gap_to_julia(Set{Int}, GAP.evalstr("rec( 1:= 1 )"))
  end

  @testset "Tuples" begin
    @test GAP.gap_to_julia(Tuple, GapObj([])) == ()
    x = GapObj([1, 2, 3])
    @test GAP.gap_to_julia(Tuple, x) == (1, 2, 3)
    @test GAP.gap_to_julia(Tuple{Vararg{Any}}, x) == (1, 2, 3)
    @test GAP.gap_to_julia(Tuple{Vararg{Int}}, x) == (1, 2, 3)
    @test GAP.gap_to_julia(Tuple{Int16,Vararg{Any}}, x) == (1, 2, 3)
    @test GAP.gap_to_julia(Tuple{Int16,Vararg{Int}}, x) == (1, 2, 3)
    @test (@inferred GAP.gap_to_julia(Tuple{Int64,Int16,Int32}, x)) == (1, 2, 3)
    @test GAP.gap_to_julia(Tuple{Int64,Vararg{Int16}}, x) == (1, 2, 3)
    @test (@inferred GAP.gap_to_julia(Tuple{Int64,Vararg{Int16,2}}, x)) == (1, 2, 3)
    @test_throws ArgumentError GAP.gap_to_julia(Tuple{Int64,Vararg{Int16,1}}, x)
    @test_throws ArgumentError GAP.gap_to_julia(Tuple{Any,Any}, x)
    @test_throws ArgumentError GAP.gap_to_julia(Tuple{Any,Any,Any,Any}, x)
    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Tuple{Int64,Any,Int32}, n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, [ 4, 5 ] ] ]")
    y = GAP.gap_to_julia(Tuple{GAP.Obj,Any}, x; recursive = true)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], Array)
    @test isa(y[2][2], Array)
    y = GAP.gap_to_julia(Tuple{GAP.Obj,Any}, x)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], GapObj)
    @test isa(y[2][2], GAP.Obj)

    l = GAP.evalstr("[\"test\", ~[1]]")
    @test GAP.gap_to_julia(Tuple{Vector{Char}, NTuple{4,Char}}, l) ==
    (['t', 'e', 's', 't'], ('t', 'e', 's', 't'))
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
    r = GAP.evalstr("[ 1, 3, 5 ]")
    @test_throws ArgumentError GAP.gap_to_julia(UnitRange{Int64}, r)
    @test (@inferred GAP.gap_to_julia(StepRange{Int64,Int64}, r)) == 1:2:5
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
    @test GAP.gap_to_julia(x; recursive = true) == y
    @test (@inferred GAP.gap_to_julia(Dict, x; recursive = true)) == y
    @test (@inferred GAP.gap_to_julia(Dict{Symbol,Any}, x; recursive = true)) == y
    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Dict{Symbol,Any}, n)
    x = GAP.evalstr("rec( a:= [ 1, 2 ], b:= [ 3, [ 4, 5 ] ], c:= ~.a )")
    y = GAP.gap_to_julia(Dict{Symbol,Any}, x; recursive = true)
    @test isa(y, Dict)
    @test isa(y[:a], Array)
    @test isa(y[:b], Array)
    @test isa(y[:b][2], Array)
    @test y[:a] === y[:c]
    y = GAP.gap_to_julia(Dict{Symbol,Any}, x)
    @test isa(y[:a], GAP.Obj)
    @test isa(y[:b], GAP.Obj)
    @test y[:a] == y[:c]
  end

  @testset "Julia Functions" begin
    @test GAP.gap_to_julia(GAP.Globals.Julia.sqrt) === sqrt
    @test_throws GAP.ConversionError GAP.gap_to_julia(Function, 1)
  end

  @testset "Default" begin
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError GAP.gap_to_julia(x)
    @test_throws GAP.ConversionError GAP.gap_to_julia(Int, (1, 2))
    @test GAP.gap_to_julia(Nothing, nothing) == nothing
    @test GAP.gap_to_julia(Any, nothing) == nothing
  end

  @testset "Conversions involving circular references" begin
    xx = GAP.evalstr("l:=[1];x:=[l,l];")
    conv = GAP.gap_to_julia(xx)
    @test conv[1] === conv[2]
    conv = GAP.gap_to_julia(Tuple{Tuple{Int64},Tuple{Int64}}, xx)
    @test conv[1] === conv[2]

    xx = GAP.evalstr("[~]")
    conv = GAP.gap_to_julia(xx; recursive = true)
    @test conv === conv[1]

    xx = GAP.evalstr("rec(a := 1, b := ~)")
    conv = GAP.gap_to_julia(xx; recursive = true)
    @test conv === conv[:b]

    xx = GAP.evalstr("[\"a\", \"a\"]")
    conv = GAP.gap_to_julia(Vector{Symbol}, xx)  # non-recursive conversion!
    @test xx[1] !== xx[2]
    @test conv[1] === conv[2]
  end

  @testset "Conversion to GapObj and Union types containing it" begin
    v = [GapObj("a")]
    xx = GapObj(v)

    yy = GAP.gap_to_julia(Vector{GapObj}, xx)
    @test v == yy
    @test yy isa Vector{GapObj}

    yy = GAP.gap_to_julia(Vector{Union{Nothing,GapObj}}, xx)
    @test v == yy
    @test yy isa Vector{Union{Nothing,GapObj}}
  end

  @testset "Catch conversions to types that are not supported" begin
    xx = GapObj("a")
    @test_throws GAP.ConversionError GAP.gap_to_julia(Dict{Int64,Int64}, xx)
  end

  @testset "Test converting GAP lists with holes in them" begin
    xx = GAP.evalstr("[1,,1]")
    @test GAP.gap_to_julia(xx) == Any[1, nothing, 1]
    @test GAP.gap_to_julia(Vector{Any}, xx) == Any[1, nothing, 1]
    @test_throws MethodError GAP.gap_to_julia(Vector{Int64}, xx)
    conv = GAP.gap_to_julia(Vector{Union{Nothing,Int64}}, xx)
    @test conv == Union{Nothing,Int64}[1, nothing, 1]
    @test conv == GAP.gap_to_julia(Vector, xx)
  end

  @testset "GAP lists with Julia objects" begin
    xx = GapObj([(1,)])
    yy = GAP.gap_to_julia(Vector{Tuple{Int64}}, xx)
    @test [(1,)] == yy
    @test typeof(yy) == Vector{Tuple{Int64}}
  end
end

@testset "conversion to GAP" begin

  @testset "Defaults" begin
    @test GapObj(true)
  end

  @testset "Integers" begin
    for i in -2:2
        @test GapObj(Int128(i)) == i
        @test GapObj(Int64(i)) == i
        @test GapObj(Int32(i)) == i
        @test GapObj(Int16(i)) == i
        @test GapObj(Int8(i)) == i
    end
  end

  @testset "Int64 corner cases" begin
    @test GapObj(-2^60) === -2^60
    @test GapObj(2^60 - 1) === 2^60 - 1

    @test GAP.Globals.IsInt(GapObj(-2^60 - 1))
    @test GAP.Globals.IsInt(GapObj(2^60))

    @test GAP.Globals.IsInt(GapObj(-2^63 - 1))
    @test GAP.Globals.IsInt(GapObj(-2^63))
    @test GAP.Globals.IsInt(GapObj(2^63 - 1))
    @test GAP.Globals.IsInt(GapObj(2^63))

    # see issue https://github.com/oscar-system/GAP.jl/issues/332
    @test 2^60 * GAP.Globals.Factorial(20) == GAP.evalstr("2^60 * Factorial(20)")
  end

  @testset "Unsigned integers" begin
    @test GapObj(UInt128(1)) == 1
    @test GapObj(UInt64(1)) == 1
    @test GapObj(UInt32(1)) == 1
    @test GapObj(UInt16(1)) == 1
    @test GapObj(UInt8(1)) == 1
  end

  @testset "BigInts" begin
    for i = -2:2
        @test GapObj(BigInt(i)) == i
    end
    x = GAP.evalstr("2^100")
    @test GapObj(BigInt(2)^100) == x
    @test GapObj(-BigInt(2)^100) == -x
  end

  @testset "Rationals" begin
    x = GAP.evalstr("2^100")
    @test GapObj(Rational{BigInt}(2)^100 // 1) == x
    x = GAP.evalstr("2^100/3")
    @test GapObj(Rational{BigInt}(2)^100 // 3) == x
    @test GapObj(1 // 0) == GAP.Globals.infinity
    @test GapObj(-1 // 0) == -GAP.Globals.infinity
  end

  @testset "Floats" begin
    x = GAP.evalstr("2.")
    @test GapObj(2.0) == x
    @test GapObj(Float32(2.0)) == x
    @test GapObj(Float16(2.0)) == x
  end

  @testset "Chars" begin
    x = GAP.evalstr("'x'")
    @test GapObj('x') == x
  end

  @testset "Strings & Symbols" begin
    x = GAP.evalstr("\"foo\"")
    @test GapObj("foo") == x
    @test GapObj(:foo) == x
    substr = match(r"a(.*)c", "abc").match  # type is `SubString{String}`
    @test GapObj(substr) == GapObj("abc")
    @test length(GapObj("abc\000def")) == 7  # contains a null character
    x = GAP.evalstr("\"jμΛIα\"")
    @test length(x) == 8  # in GAP, the number of bytes
    @test GapObj("jμΛIα") == x
    @test length("jμΛIα") == 5
    @test sizeof("jμΛIα") == 8
  end

  @testset "Arrays" begin
    x = GAP.evalstr("[1,\"foo\",2]")
    @test GapObj([1, "foo", BigInt(2)]; recursive = true) == x
    x = GAP.evalstr("[1,JuliaEvalString(\"\\\"foo\\\"\"),2]")
    @test GapObj([1, "foo", BigInt(2)]) == x
    x = GAP.evalstr("[[1,2],[3,4]]")
    @test GapObj([1 2; 3 4]) == x
  end

  @testset "Sets" begin
    x = GAP.evalstr("[1, 3, 4]")
    @test GapObj(Set([4, 3, 1])) == x
    x = GAP.evalstr("[\"a\", \"b\", \"c\"]")
    @test GapObj(Set(["c", "b", "a"]); recursive = true) == x

    for coll in [
      [7, 1, 5, 3, 10],
      [:c, :b, :a, :b],
      [(1, :a), (1, :b), (2, :a), (2, :b)],
    ]
      # create a set
      s = Set(coll)
      # create sort duplicate free list (this is how GAP represents sets)
      l = sort(unique(coll))

      x = GapObj(s)
      @test x == GapObj(l)

      x = GapObj(s; recursive = true)
      @test x == GapObj(l; recursive = true)
    end
  end

  @testset "BitVectors" begin
    x = GAP.evalstr("BlistList([1,2],[1])")
    y = GapObj([true, false])
    @test y == x
    @test String(GAP.Globals.TNAM_OBJ(y)) == "list (boolean)"

    v = BitVector([true, false])
    gap_v = GapObj(v)
    @test gap_v == x
    @test String(GAP.Globals.TNAM_OBJ(gap_v)) == "list (boolean)"
  end

  @testset "Tuples" begin
    x = GAP.evalstr("[1,\"foo\",2]")
    @test GapObj((1, "foo", 2); recursive = true) == x
    x = GAP.evalstr("[1,JuliaEvalString(\"\\\"foo\\\"\"),2]")
    @test GapObj((1, "foo", 2)) == x
  end

  @testset "Ranges" begin
    r = GAP.evalstr("[]")
    @test GapObj(1:0) == r
    @test GapObj(1:1:0) == r
    r = GAP.evalstr("[ 1 ]")
    @test GapObj(1:1) == r
    @test GapObj(1:1:1) == r
    r = GAP.evalstr("[ 4 .. 13 ]")
    @test GapObj(4:13) == r
    @test GapObj(4:1:13) == r
    r = GAP.evalstr("[ 1, 4 .. 10 ]")
    @test GapObj(1:3:10) == r
    @test_throws GAP.ConversionError GapObj(1:2^62)

    r == GapObj(1:2:11)
    @test String(GAP.Globals.TNAM_OBJ(r)) == "list (range,ssort)"
    r = GAP.Obj(1:10)
    @test String(GAP.Globals.TNAM_OBJ(r)) == "list (range,ssort)"
  end

  @testset "Dictionaries" begin
    x = GAP.evalstr("rec( foo := 1, bar := \"foo\" )")
    y = Dict{Symbol,Any}(:foo => 1, :bar => "foo")
    z = GAP.evalstr("rec( foo := 1, bar := JuliaEvalString(\"\\\"foo\\\"\") )")
    # ... recursive conversion
    @test GapObj(y; recursive = true) == x
    # ... non-recursive conversion
    @test GapObj(y) == z

    # also test the case were the top level is a GapObj but inside
    # there are Julia objects
    @test GapObj(z; recursive=true) == x
    @test GapObj(z) == z  # nothing happens without recursion
  end

  @testset "Conversions with identical sub-objects" begin
    l = [1]
    yy = [l, l]
    # ... recursive conversion
    conv = GapObj(yy; recursive = true)
    @test conv[1] isa GapObj
    @test conv[1] === conv[2]
    # ... non-recursive conversion
    conv = GapObj(yy)
    @test isa(conv[1], Vector{Int64})
    @test conv[1] === conv[2]

    # a GAP list with identical Julia subobjects
    l = GapObj([])
    x = BigInt(2)^100
    y = [1]
    l[1] = x
    l[2] = x
    l[3] = y
    l[4] = y
    res = GapObj(l)
    @test res[1] === res[2]
    @test res[3] === res[4]
    res = GapObj(l, recursive=true)
    @test res[1] == res[2]
    @test res[1] !== res[2]  # `BigInt` wants no identity tracking
    @test res[3] === res[4]  # `Array` wants identity tracking

    # a Julia array containing GAP lists containing Julia subobjects
    v = GapObj([1, 2, 3])
    l = [v, v]
    ll = GapObj(l)
    @test ll[1] === ll[2]
    @test ll[1] === l[1]

    v[1] = [1,2]
    ll = GapObj(l)
    @test ll[1][1] === ll[2][1]
    ll = GapObj(l; recursive = true)
    @test ll[1][1] === ll[2][1]
    @test ll[1] === ll[2]

    l[2] = GapObj([1, 2, 3])
    l[2][1] = l[1][1]
    ll = GapObj(l)
    @test ll[1][1] === ll[2][1]  # two Julia vectors
    ll = GapObj(l; recursive = true)
    @test ll[1][1] === ll[2][1]  # two GAP lists
    @test ll[1] !== ll[2]

    # a GAP record with identical Julia subobjects
    r = GapObj(Dict{String, String}())
    setproperty!(r, :a, x)
    setproperty!(r, :b, x)
    setproperty!(r, :c, y)
    setproperty!(r, :d, y)
    res = GapObj(r)
    @test res.a === res.b
    @test res.c === res.d
    res = GapObj(r, recursive=true)
    @test res.a == res.b
    @test res.a !== res.b  # `BigInt` wants no identity tracking
    @test res.c === res.d
  end

  @testset "converting a list with circular refs" begin
    yy = Vector{Any}(undef, 2)
    yy[1] = yy
    yy[2] = yy
    # ... recursive conversion
    conv = GapObj(yy; recursive = true)
    @test conv[1] === conv
    @test conv[1] === conv[2]
    # ... non-recursive conversion
    conv = GapObj(yy)
    @test conv[1] !== conv
    @test conv[1] === conv[2]
  end

  @testset "converting a dictionary with circular refs" begin
    d = Dict{String,Any}("a" => 1)
    d["b"] = d
    conv = GapObj(d; recursive = true)
    @test conv === conv.b
  end

  @testset "Test converting lists with 'nothing' in them -> should be converted to a hole in the list" begin
    xx = GAP.evalstr("[1,,1]")
    @test GapObj([1, nothing, 1]) == xx
  end

  @testset "Convert GAP objects recursively" begin
    val = GapObj([])
    val[1] = [1, 2]
    val[2] = [3, 4]
    nonrec = GapObj(val)
    @test nonrec[1] == [1, 2]
    rec = GapObj(val, recursive = true)
    @test rec[1] == GapObj([1, 2])
    @test GapObj(1) == 1
  end

  @testset "Test function conversion" begin
    return_first(args...) = args[1]
    return_first_gap = GapObj(return_first)
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
