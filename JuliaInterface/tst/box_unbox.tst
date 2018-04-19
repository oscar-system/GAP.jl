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

gap> list:= JuliaBox( [ 1, JuliaBox( 2 ), 3 ] );
<Julia: Any[1, 2, 3]>
gap> JuliaUnbox( list );
[ <Julia: 1>, <Julia: 2>, <Julia: 3> ]
gap> List( JuliaUnbox( list ), JuliaUnbox );
[ 1, 2, 3 ]

gap> parse:= JuliaFunction( "parse", "Base" );;
gap> IsIdenticalObj( parse, JuliaBox( parse ) );
true
gap> list:= JuliaBox( [ 1, parse, 3 ] );
<Julia: Any[1, parse, 3]>
gap> list2:= JuliaUnbox( list );
[ <Julia: 1>, <Julia: parse>, <Julia: 3> ]
gap> List( list2, JuliaUnbox );
[ 1, fail, 3 ]

## The following should work but currently doesn't.
# gap> IsJuliaFunction( list2[2] );
# true

