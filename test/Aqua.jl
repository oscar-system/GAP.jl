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

using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(
        GAP;
        ambiguities=false, # some from AbstractAlgebra.jl show up here
        piracies=(GAP.use_jl_reinit_foreign_type() ? true : (treat_as_own=[GapObj],))
    )
end
