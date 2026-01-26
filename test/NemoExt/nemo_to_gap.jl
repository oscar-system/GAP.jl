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

import AbstractAlgebra

@testset "conversion from Nemo to GAP" begin
  @testset "infinity" begin
    x = Nemo.inf
    val = GAP.evalstr("infinity")
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    x = -Nemo.inf
    val = GAP.evalstr("-infinity")
    @test GapObj(x) == val
    @test GAP.Obj(x) == val
  end

  @testset "ZZRingElem" begin
    # small (GAP) integer
    x = ZZRingElem(17)
    val = 17
    @test GapObj(x) == val
    @test GAP.Obj(x) == val
    @test GapInt(x) == val

    # large GAP integer
    x = ZZRingElem(2)^65
    val = GAP.evalstr("2^65")
    @test GapObj(x) == val
    @test GAP.Obj(x) == val
    @test GapInt(x) == val
  end

  @testset "Set{ZZRingElem}" begin
    coll = ZZRingElem[7, 1, 5, 3, 10]

    # create a set
    s = Set(coll)
    # create sort duplicate free list (this is how GAP represents sets)
    l = sort(unique(coll))

    x = GapObj(s)
    @test x == GapObj(l)

    x = GapObj(s; recursive = true)
    @test x == GapObj(l; recursive = true)
  end

  @testset "QQFieldElem" begin
    # small (GAP) integer
    x = ZZRingElem(17)
    val = 17
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # large GAP integer
    x = ZZRingElem(2)^65
    val = GAP.evalstr("2^65")
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # non-integer rational, small numerator and denominator
    x = QQFieldElem(2, 3)
    val = GAP.evalstr("2/3")
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # non-integer rational, large numerator and denominator
    x = QQFieldElem(ZZRingElem(2)^65, ZZRingElem(3)^40)
    val = GAP.evalstr("2^65/3^40")
    @test GapObj(x) == val
    @test GAP.Obj(x) == val
  end

  @testset "MatElem" begin
    # matrix of Julia integers (to test general MatElem conversion)
    x = AbstractAlgebra.ZZ[1 2; 3 4]
    val = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # matrix containing small and large integers
    x = AbstractAlgebra.ZZ[1 BigInt(2)^65; 3 4]
    val = GAP.evalstr( "[ [ 1, 2^65 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val
  end

  @testset "ZZMatrix" begin
    # matrix of small (GAP) integers
    x = Nemo.ZZ[1 2; 3 4]
    val = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # matrix containing small and large integers
    x = Nemo.ZZ[1 BigInt(2)^65; 3 4]
    val = GAP.evalstr( "[ [ 1, 2^65 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val
  end

  @testset "QQMatrix" begin
    # matrix of small (GAP) integers
    x = Nemo.QQ[1 2; 3 4]
    val = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # matrix containing small and large integers
    x = Nemo.QQ[1 BigInt(2)^65; 3 4]
    val = GAP.evalstr( "[ [ 1, 2^65 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # matrix containing non-integer rationals, small numerator and denominator
    x = Nemo.QQ[QQFieldElem(1, 2) 2; 3 4]
    val = GAP.evalstr( "[ [ 1/2, 2 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val

    # matrix containing non-integer rationals, large numerator and denominator
    x = Nemo.QQ[QQFieldElem(ZZRingElem(2)^65, ZZRingElem(3)^40) 2; 3 4]
    val = GAP.evalstr( "[ [ 2^65/3^40, 2 ], [ 3, 4 ] ]" )
    @test GapObj(x) == val
    @test GAP.Obj(x) == val
  end
end
