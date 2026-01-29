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

import Random

@testset "MersenneTwister" begin

    rng = GAP.default_rng()
    vals = 1:100
    gvals = GapObj("abcdefghijklmnopqrstuvwxzy")

    # basic sanity check on vals
    @test all(_ -> rand(rng, vals) in vals, 1:1000)
    @test all(_ -> rand(rng, gvals) in gvals, 1:1000)

    # copy
    rng2 = copy(rng)
    @test all(_ -> rand(rng, vals) == rand(rng2, vals), 1:1000)
    @test all(_ -> rand(rng, gvals) == rand(rng2, gvals), 1:1000)

    # seed
    Random.seed!(rng, 42)
    @test [rand(rng, vals) for _ in 1:10] == [53, 22, 72, 25, 84, 41, 83, 90, 54, 20]

    Random.seed!(rng, 42)
    x = [rand(rng, gvals) for _ in 1:10]
    @test String(GapObj(x)) == "uvhzltoisy"

end
