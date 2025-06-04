#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
##

@testset "conversion from GAP using constructors" begin

  ## Analogous tests for conversion using convert are in conversion.jl.

  @testset "Conversion to GAP.Obj and GAP.GapObj" begin
    x = GAP.evalstr("2^100")
    @test (@inferred GapObj(x)) == x
    @test GAP.Obj(true) == true
    x = GAP.evalstr("Z(3)")
    @test GAP.Obj(x) == x
    @test GAP.Obj(0) == 0

    # recursive conversion of nested objects
    m = [[1, 2], [3, 4]]
    c = GAP.Obj(m)
    @test c[1] isa Vector
    @test c == GAP.Obj(m, false)
    c = GAP.Obj(m, true)
    @test c[1] isa GAP.Obj
    c = GapObj(m)
    @test c[1] isa Vector
    @test c == GapObj(m, false)
    c = GapObj(m, true)
    @test c[1] isa GapObj
  end

  @testset "Border cases" begin
    x = GAP.evalstr("2^100")
    @test_throws InexactError Int64(x)
    @test (@inferred Int128(x)) == BigInt(2)^100
    @test (@inferred BigInt(x)) == BigInt(2)^100
    x = GAP.evalstr("2^62")  # not an immediate integer
    @test Int64(x) == 2^62
  end

  @testset "BigInts" begin
    x = GAP.evalstr("2^100")
    @test (@inferred BigInt(x)) == BigInt(2)^100
    x = GAP.evalstr("1/2")
    @test_throws GAP.ConversionError BigInt(x)
  end

  @testset "Rationals" begin
    x = GAP.evalstr("2^100")
    @test (@inferred Rational{BigInt}(x)) == BigInt(2)^100 // 1
    x = GAP.evalstr("2^100/3")
    @test (@inferred Rational{BigInt}(x)) == BigInt(2)^100 // 3
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError Rational{BigInt}(x)
  end

  @testset "Floats" begin
    x = GAP.evalstr("2.")
    @test (@inferred Float64(x)) == 2.0
    @test (@inferred Float32(x)) == Float32(2.0)
    @test (@inferred Float16(x)) == Float16(2.0)
    @test (@inferred BigFloat(x)) == BigFloat(2.0)
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError Float64(x)
  end

  @testset "Chars" begin
    x = GAP.evalstr("'x'")
    @test (@inferred Cuchar(x)) == Cuchar('x')
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError Cuchar(x)
  end

  @testset "Strings" begin
    x = GAP.evalstr("[]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test (@inferred String(x)) == ""
    x = GAP.evalstr("[ 'a', 'b', 'c' ]")
    @test GAP.Globals.IsString(x) == true
    @test GAP.Globals.IsStringRep(x) == false
    @test (@inferred String(x)) == "abc"
    x = GAP.evalstr("\"foo\"")
    @test (@inferred String(x)) == "foo"
  end

  @testset "Symbols" begin
    x = GAP.evalstr("\"foo\"")
    @test (@inferred Symbol(x)) == :foo
    x = GAP.evalstr("(1,2,3)")
    @test_throws GAP.ConversionError String(x)

    # Convert GAP string to Vector{UInt8} (==Vector{UInt8})
    x = GAP.evalstr("\"foo\"")
    @test (@inferred Vector{UInt8}(x)) == UInt8[0x66, 0x6f, 0x6f]
    x = GAP.evalstr("[1,2,3]")
    @test (@inferred Vector{UInt8}(x)) == UInt8[1, 2, 3]
  end

  @testset "BitVectors" begin
    x = GAP.evalstr("[ true, false, false, true ]")
    @test (@inferred BitVector(x)) == [true, false, false, true]
    x = GAP.evalstr("[ 1, 0, 0, 1 ]")
    @test_throws GAP.ConversionError BitVector(x)
  end

  @testset "Vectors" begin
    x = GapObj([1, 2, 3])
    @test (@inferred Vector{Any}(x)) == [1, 2, 3]
    @test (@inferred Vector{Int64}(x)) == [1, 2, 3]
    @test (@inferred Vector{BigInt}(x)) == [1, 2, 3]
    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError Vector{Int64}(n)
    @test_throws GAP.ConversionError Vector{BigInt}(n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, 4 ] ]")
    nonrec1 = @inferred Vector{GapObj}(x)
    nonrec2 = @inferred Vector{Any}(x; recursive = false)
    rec = @inferred Vector{Any}(x; recursive = true)
    @test all(x -> isa(x, GapObj), nonrec1)
    @test nonrec1 == nonrec2
    @test nonrec1 != rec
    @test all(x -> isa(x, Array), rec)
    x = [1, 2]
    y = GapObj([x, x]; recursive = true)
    z = Vector{Any}(y)
    @test z[1] === z[2]
  end

  @testset "Matrices" begin
    n = GAP.evalstr("[[1,2],[3,4]]")
    @test (@inferred Matrix{Int64}(n)) == [1 2; 3 4]
    xt = [(1,) (2,); (3,) (4,)]
    n = GapObj(xt; recursive = false)
    @test (@inferred Matrix{Tuple{Int64}}(n)) == xt
    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError Matrix{Int64}(n)
    n = GAP.evalstr("[[1,2],[,4]]")
    #@test Matrix{Union{Int64,Nothing}}(n) == [1 2; nothing 4]
    x = [1, 2]
    m = Any[1 2; 3 4]
    m[1, 1] = x
    m[2, 2] = x
    x = GapObj(m; recursive = true)
    y = @inferred Matrix{Any}(x)
    @test !isa(y[1, 1], GapObj)
    @test y[1, 1] === y[2, 2]
    z = @inferred Matrix{Any}(x; recursive = false)
    @test isa(z[1, 1], GapObj)
    @test z[1, 1] === z[2, 2]
  end

  @testset "Sets" begin
    @test (@inferred Set{Int}(GAP.evalstr("[1, 3, 1]"))) == Set{Int}([1, 3, 1])
    @test (@inferred Set{Vector{Int}}(GAP.evalstr("[[1,2],[2,3,4]]"))) == Set([[1, 2], [2, 3, 4]])
    @test (@inferred Set{String}(GAP.evalstr("[\"b\", \"a\", \"b\"]"))) == Set(["b", "a", "b"])
    x = GAP.evalstr("SymmetricGroup(3)")
    #@test (@inferred Set{GapObj}(x)) == Set{GapObj}(GAP.Globals.AsSet(x))
  end

  @testset "Tuples" begin
    x = GapObj([1, 2, 3])
    @test (@inferred Tuple{Int64,Int16,Int32}(x)) == (1, 2, 3)
    @test Tuple{Int64,Any,Int32}(x) == (1, 2, 3)
    @test_throws ArgumentError Tuple{Any,Any}(x)
    @test_throws ArgumentError Tuple{Any,Any,Any,Any}(x)
    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError Tuple{Int64,Any,Int32}(n)
    x = GAP.evalstr("[ [ 1, 2 ], [ 3, [ 4, 5 ] ] ]")
    y = Tuple{GAP.Obj,Any}(x)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], Array)
    @test isa(y[2][2], Array)
    y = Tuple{GAP.Obj,Any}(x; recursive = false)
    @test isa(y, Tuple)
    @test isa(y[1], GAP.Obj)
    @test isa(y[2], Array)
    @test isa(y[2][2], GAP.Obj)
  end

  @testset "Ranges" begin
    r = GAP.evalstr("[]")
    @test (@inferred UnitRange{Int64}(r)) == 1:0
    @test (@inferred StepRange{Int64,Int64}(r)) == 1:1:0
    r = GAP.evalstr("[ 1 ]")
    @test (@inferred UnitRange{Int64}(r)) == 1:1
    @test (@inferred StepRange{Int64,Int64}(r)) == 1:1:1
    r = GAP.evalstr("[ 4 .. 13 ]")
    @test (@inferred UnitRange{Int64}(r)) == 4:13
    @test (@inferred StepRange{Int64,Int64}(r)) == 4:1:13
    r = GAP.evalstr("[ 1, 4 .. 10 ]")
    @test_throws ArgumentError UnitRange{Int64}(r)
    @test (@inferred StepRange{Int64,Int64}(r)) == 1:3:10
    r = GAP.evalstr("[ 1, 2, 4 ]")
    @test_throws GAP.ConversionError UnitRange{Int64}(r)
    @test_throws GAP.ConversionError StepRange{Int64,Int64}(r)
    r = GAP.evalstr("rec()")
    @test_throws GAP.ConversionError UnitRange{Int64}(r)
    @test_throws GAP.ConversionError StepRange{Int64,Int64}(r)
  end

  @testset "Dictionaries" begin
    x = GAP.evalstr("rec( foo := 1, bar := \"foo\" )")
    y = Dict{Symbol,Any}(:foo => 1, :bar => "foo")
    @test (@inferred Dict{Symbol,Any}(x)) == y
    n = GapObj(big(2)^100)
    @test_throws GAP.ConversionError Dict{Symbol,Any}(n)
    x = GAP.evalstr("rec( a:= [ 1, 2 ], b:= [ 3, [ 4, 5 ] ] )")
    y = @inferred Dict{Symbol,Any}(x)
    @test isa(y, Dict)
    @test isa(y[:a], Array)
    @test isa(y[:b], Array)
    @test isa(y[:b][2], Array)
    y = @inferred Dict{Symbol,Any}(x; recursive = false)
    @test isa(y[:a], GAP.Obj)
    @test isa(y[:b], GAP.Obj)
  end

  @testset "Conversions involving circular references" begin
    xx = GAP.evalstr("l:=[1];x:=[l,l];")
    conv = @inferred Tuple{Tuple{Int64},Tuple{Int64}}(xx)
    @test conv[1] === conv[2]
  end

  @testset "Test converting GAP lists with holes in them" begin
    xx = GAP.evalstr("[1,,1]")
    @test (@inferred Vector{Any}(xx)) == Any[1, nothing, 1]
    @test_throws MethodError Vector{Int64}(xx)
    @test (@inferred Vector{Union{Nothing,Int64}}(xx)) == Union{Nothing,Int64}[1, nothing, 1]
    @test (@inferred Vector{Union{Int64,Nothing}}(xx)) == Union{Nothing,Int64}[1, nothing, 1]
  end

  @testset "GAP lists with Julia objects" begin
    xx = GapObj([(1,)])
    yy = @inferred Vector{Tuple{Int64}}(xx)
    @test [(1,)] == yy
    @test typeof(yy) == Vector{Tuple{Int64}}
  end

end
