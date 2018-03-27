LoadPackage( "JuliaInterface" );

julia_print := JuliaFunction( "print" );

int := JuliaBox( 11 );
JuliaUnbox( int );

string := JuliaBox( "bla" );
JuliaCallFunc1Arg( julia_print, string );
JuliaUnbox( string );

bool := JuliaBox( true );
JuliaCallFunc1Arg( julia_print, bool );
JuliaUnbox( bool );

bool := JuliaBox( false );
JuliaCallFunc1Arg( julia_print, bool );
JuliaUnbox( bool );
