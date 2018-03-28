
############################################################################

ShortestVectors_ViaJulia:= function( mat, bound )
    local llg, m, n, i, j, result;

    # Call LLLReducedGramMat in GAP.  (not yet available as julia code ...)
    llg:= LLLReducedGramMat( mat );

    # Prepare the arguments:
    # 'mue' cannot have triangular shape.
    m:= Length( llg.mue );
    n:= Length( llg.mue[m] );
    llg.mue:= List( llg.mue, ShallowCopy );
    for i in [ 1 .. m ] do
      for j in [ i .. n ] do
        llg.mue[i][j]:= 0;
      od;
    od;

    llg.mue:= Concatenation( "[ ",
      JoinStringsWithSeparator( List( llg.mue,
        r -> JoinStringsWithSeparator( List( r, String ), " " ) ), " ; " ),
      " ]" );

    llg.B:= Concatenation( "[ ",
      JoinStringsWithSeparator( List( llg.B, String ), ", " ), " ]" );

    llg.transformation:= Concatenation( "[ ",
      JoinStringsWithSeparator( List( llg.transformation,
        r -> JoinStringsWithSeparator( List( r, String ), " " ) ), " ; " ),
      " ]" );

    llg:= JuliaEvalString( Concatenation( "( ", llg.mue, ", ", llg.B, ", ",
                             llg.transformation, " )" ) );
# need a tuple not a list on the outer level

    # Call the julia function.
    result:= GetJuliaFunc( "shortestvectors" )(
                 llg,
                 JuliaBox( bound ) );

    # Return the GAP object corresp. to the result.
    return JuliaUnbox( result );
end;

