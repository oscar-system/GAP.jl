LoadPackage( "JuliaInterface" );
y := JuliaBox( 2 );
julia_exp := JuliaFunction( "exp10" );
z := julia_exp( y );
JuliaUnbox( z );
julia_int := JuliaFunction( "Int" );
z_int := julia_int( z );
JuliaUnbox( z_int );

