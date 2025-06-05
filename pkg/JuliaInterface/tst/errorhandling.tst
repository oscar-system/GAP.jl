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
##  Test handling of Julia errors.
gap> START_TEST( "errorhandling.tst" );

# don't interpret percent signs etc. in Julia error strings
gap> JuliaEvalString( "error( \"abc %, 1\" )" );
Error, abc %, 1

#
gap> STOP_TEST( "errorhandling.tst", 1 );
