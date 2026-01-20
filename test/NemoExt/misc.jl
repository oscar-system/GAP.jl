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

@testset "characteristic" begin
    x = GapInt(big(2)^100)
    @test typeof(x) === GapObj
    @test characteristic(x) == 0

    x = GAP.Globals.Z(2)
    @test typeof(x) === GAP.FFE
    @test characteristic(x) == 2
end

@testset "round trip conversion" begin
    v = [ZZ(3)^100, QQ(5,3)^100, matrix(ZZ, [1 2; 3 4]), matrix(QQ, [5 6; 7 8])]

    w = GapObj(v; recursive=true)
    @test w isa GapObj
    @test typeof.(w) == [GapObj, GapObj, GapObj, GapObj]

    t = Tuple{ZZRingElem, QQFieldElem, ZZMatrix, QQMatrix}(w)
    @test collect(t) == v
end
