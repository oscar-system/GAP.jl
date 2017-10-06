# Let Nemo compute the Hermite normal form of a GAP matrix of integers.

# start julia
LoadPackage( "JuliaInterface" );

# get the Nemo function we want to use
JuliaEvalString( "using Nemo" );
jhnf:= GetJuliaFunc( "hnf" );

# provide the GAP function that creates the right Nemo object
# (here: a matrix of type 'Nemo.fmpz_mat') from a GAP matrix
NemoIntegerMatrix:= function( mat )
    local str, row;

    str:= "ZZ[";
    for row in mat do
      Append( str, JoinStringsWithSeparator( List( row, String ), " " ) );
      Append( str, ";" );
    od;
    str[ Length( str ) ]:= ']';
    return JuliaEvalString( str );
end;;

# provide the Julia function that unpacks the Nemo object
# into a Julia array of arrays of integers
# (Is 'BigInt' currently not supported by JuliaInterface?)
unpackNemoMatrix:= JuliaEvalString( "function ( nemomat ) \
 mat = Matrix{Int}( nemomat ); \
 return map( i -> mat[i,:], 1:size(mat,1) ); \
 end" );;

# run an example
m:= RandomMat( 10, 10, Integers );               # the GAP input
jm:= NemoIntegerMatrix( m );                     # the Nemo equivalent
mm:= JuliaCallFunc1Arg( jhnf, jm );              # Nemo's result
mm:= JuliaCallFunc1Arg( unpackNemoMatrix, mm );  # julia's array of arrays
result:= JuliaUnbox( mm );                       # the value in GAP

