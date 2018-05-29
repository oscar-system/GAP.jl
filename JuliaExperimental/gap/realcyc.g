##############################################################################
##
##  realcyc.g
##
##  The Julia utilities are implemented in 'julia/realcyc.jl'.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "realcyc.jl" ) );

ImportJuliaModuleIntoGAP( "GAPRealCycModule" );


BindGlobal( "IsPositiveRealPartCyclotomic", function( cyc )
    local denom, coeffs;

    coeffs:= COEFFS_CYC( cyc );
    denom:= DenominatorCyc( cyc );
    if denom <> 1 then
      coeffs:= coeffs * denom;
    fi;

    if ForAll( coeffs, IsSmallIntRep ) then
      coeffs:= ConvertedToJulia( coeffs );
    else
      coeffs:= JuliaArrayOfFmpz( coeffs );
    fi;
    
    return JuliaUnbox(
               Julia.GAPRealCycModule.isPositiveRealPartCyc( coeffs ) );
end );


##############################################################################
##
#E

