LoadPackage( "JuliaInterface" );

julia_print := JuliaFunction( "print" );

int := JuliaBox( 11 );
JuliaUnbox( int );

string := JuliaBox( "bla" );
julia_print( string );
JuliaUnbox( string );

bool := JuliaBox( true );
julia_print( bool );
JuliaUnbox( bool );

bool := JuliaBox( false );
julia_print( bool );
JuliaUnbox( bool );
