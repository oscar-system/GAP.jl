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


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "realcyc.jl" ) );


BindGlobal( "IsPositiveRealPartCyclotomic", function( cyc )
    local coeffs, denom, res;

    if not IsCyc( cyc ) then
      Error( "<cyc> must be a cyclotomic number" );
    elif cyc = 0 then
      # Arb would not return 'true' for a positivity or negativity test.
      return false;
    elif IsRat( cyc ) then
      # GAP can answer the question.
      return IsPosRat( cyc );
    fi;

    coeffs:= COEFFS_CYC( cyc );
    denom:= DenominatorCyc( cyc );
    if denom <> 1 then
      coeffs:= coeffs * denom;
    fi;

    if ForAll( coeffs, IsSmallIntRep ) then
      coeffs:= GAPToJulia( coeffs );
    else
      coeffs:= JuliaArrayOfFmpz( coeffs );
    fi;
    
    res:= Julia.GAPRealCycModule.isPositiveRealPartCyc( coeffs );
    if ValueOption( "ShowPrecision" ) = true then
      Print( "#I  precision needed: ", JuliaToGAP( IsInt, res[2] ), "\n" );
    fi;

    return res[1];
end );

