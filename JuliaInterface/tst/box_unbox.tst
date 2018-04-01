gap> int := JuliaBox( 11 );
<Julia: 11>
gap> JuliaUnbox( int );
11
gap> string := JuliaBox( "bla" );
<Julia: bla>
gap> JuliaUnbox( string );
"bla"
gap> bool := JuliaBox( true );
<Julia: true>
gap> JuliaUnbox( bool );
true
gap> bool := JuliaBox( false );
<Julia: false>
gap> JuliaUnbox( bool );
false