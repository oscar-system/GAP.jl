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
