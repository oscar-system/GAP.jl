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

@testset "conversion from GAP to Nemo" begin
  @testset "ZZRingElem" begin
    # small (GAP) integer
    x = ZZRingElem(17)
    val = 17
    @test ZZRingElem(val) == x
    @test ZZ(val) == x

    # large positive GAP integer
    x = ZZRingElem(2)^65
    val = GAP.evalstr("2^65")
    @test ZZRingElem(val) == x
    @test ZZ(val) == x

    # large negative GAP integer
    x = -ZZRingElem(2)^65
    val = GAP.evalstr("-2^65")
    @test ZZRingElem(val) == x
    @test ZZ(val) == x

    # non-integer
    val = GAP.evalstr("1/2")
    @test_throws GAP.ConversionError ZZRingElem(val)
    @test_throws GAP.ConversionError ZZ(val)
  end

  @testset "QQFieldElem" begin
    # small (GAP) integer
    x = QQFieldElem(17)
    val = 17
    @test QQFieldElem(val) == x
    @test QQ(val) == x

    # large positive GAP integer
    x = QQFieldElem(2)^65
    val = GAP.evalstr("2^65")
    @test QQFieldElem(val) == x
    @test QQ(val) == x

    # large negative GAP integer
    x = -QQFieldElem(2)^65
    val = GAP.evalstr("-2^65")
    @test QQFieldElem(val) == x
    @test QQ(val) == x

    # "proper" rationals with large and small numerators and denominators
    @testset "QQFieldElem $a / $b" for a in [2, -2, ZZRingElem(2^65), -ZZRingElem(2^65)], b in [3, -3, ZZRingElem(3^40), -ZZRingElem(3^50)]
        x = QQFieldElem(a, b)
        val = GAP.evalstr("$a/$b")
        @test QQFieldElem(val) == x
        @test QQ(val) == x
    end

    # non-rational
    val = GAP.evalstr("E(4)")
    @test_throws GAP.ConversionError QQFieldElem(val)
    @test_throws GAP.ConversionError QQ(val)
  end

  @testset "ZZMatrix" begin
    # matrix of small (GAP) integers
    x = Nemo.ZZ[1 2; 3 4]
    val = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" )
    @test ZZMatrix(val) == x
    @test matrix(ZZ, val) == x

    # matrix containing small and large integers
    x = Nemo.ZZ[1 BigInt(2)^65; 3 4]
    val = GAP.evalstr( "[ [ 1, 2^65 ], [ 3, 4 ] ]" )
    @test ZZMatrix(val) == x
    @test matrix(ZZ, val) == x

    # matrix containing non-integers
    val = GAP.evalstr( "[ [ 1/2, 2 ], [ 3, 4 ] ]" )
    @test_throws GAP.ConversionError ZZMatrix(val)
    @test_throws GAP.ConversionError matrix(ZZ, val)
  end

  @testset "QQMatrix" begin
    # matrix of small (GAP) integers
    x = Nemo.QQ[1 2; 3 4]
    val = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" )
    @test QQMatrix(val) == x
    @test matrix(QQ, val) == x

    # matrix containing small and large integers
    x = Nemo.QQ[1 BigInt(2)^65; 3 4]
    val = GAP.evalstr( "[ [ 1, 2^65 ], [ 3, 4 ] ]" )
    @test QQMatrix(val) == x
    @test matrix(QQ, val) == x

    # matrix containing non-integer rationals, small numerator and denominator
    x = Nemo.QQ[QQFieldElem(1, 2) 2; 3 4]
    val = GAP.evalstr( "[ [ 1/2, 2 ], [ 3, 4 ] ]" )
    @test QQMatrix(val) == x
    @test matrix(QQ, val) == x

    # matrix containing non-integer rationals, large numerator and denominator
    x = Nemo.QQ[QQFieldElem(ZZRingElem(2)^65, ZZRingElem(3)^40) 2; 3 4]
    val = GAP.evalstr( "[ [ 2^65/3^40, 2 ], [ 3, 4 ] ]" )
    @test QQMatrix(val) == x
    @test matrix(QQ, val) == x

    # matrix containing non-rationals
    val = GAP.evalstr( "[ [ E(4), 2 ], [ 3, 4 ] ]" )
    @test_throws GAP.ConversionError QQMatrix(val)
    @test_throws GAP.ConversionError matrix(QQ, val)
  end
end
