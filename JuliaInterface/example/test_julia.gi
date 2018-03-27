LoadPackage( "JuliaInterface" );
y := JuliaBox( 2 );
julia_exp := JuliaFunction( "exp10" );
z := JuliaCallFunc1Arg( julia_exp, y );
JuliaUnbox( z );
julia_int := JuliaFunction( "Int" );
z_int := JuliaCallFunc1Arg( julia_int, z );
JuliaUnbox( z_int );

