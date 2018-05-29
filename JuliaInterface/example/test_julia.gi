LoadPackage( "JuliaInterface" );
y := ConvertedToJulia( 2 );
julia_exp := JuliaFunction( "exp10" );
z := julia_exp( y );
ConvertedFromJulia( z );
julia_int := JuliaFunction( "Int" );
z_int := julia_int( z );
ConvertedFromJulia( z_int );

