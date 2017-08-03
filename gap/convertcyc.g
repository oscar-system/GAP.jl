
##  convert (lists of) cyclotomics from GAP to julia

JuliaBoxCyc:= function( cycs, N )
    local coeffs, mode, d, pol, phi, c, i;

    # Get the coefficients lists w. r. t. the 'N'-th cyclotomic field.
    if IsCyc( cycs ) then
      coeffs:= [ CoeffsCyc( cycs, N ) ];
      if coeffs = fail then
        return fail;
      fi;
      mode:= 0;
    elif IsList( cycs ) and ForAll( cycs, IsCyc ) then
      coeffs:= List( cycs, x -> CoeffsCyc( x, N ) );
      mode:= 1;
    else
      Error( "not yet" );
    fi;

    # Extract the common denominator.
    d:= Lcm( List( Concatenation( coeffs ), DenominatorCyc ) );
    coeffs:= d * coeffs;

    # Rewrite the coeff. lists w. r. t. the 'N'-th cyclotomic polynomial.
    pol:= CyclotomicPol( N );
    phi:= Length( pol ) - 1;
    Perform( coeffs, x -> ReduceCoeffs( x, pol ) );
    for c in coeffs do
      for i in [ phi + 1 .. Length( c ) ] do
        Unbind( c[i] );
      od;
    od;
#T fill up coeffs up to length phi?

    return JuliaCallFuncXArg( GetJuliaFunc( "juliabox_cycs" ),
                              [ JuliaBox( coeffs ),
                                JuliaBox( d ),
                                JuliaBox( N ),
                                JuliaBox( mode ) ] );
end;

