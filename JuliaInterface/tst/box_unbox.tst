##
gap> START_TEST( "box_unbox.tst" );

##
gap> int := ConvertedToJulia( 11 );
<Julia: 11>
gap> JuliaUnbox( int );
11
gap> string := ConvertedToJulia( "bla" );
<Julia: bla>
gap> JuliaUnbox( string );
"bla"
gap> bool := ConvertedToJulia( true );
<Julia: true>
gap> JuliaUnbox( bool );
true
gap> bool := ConvertedToJulia( false );
<Julia: false>
gap> JuliaUnbox( bool );
false

##
gap> list:= ConvertedToJulia( [ 1, ConvertedToJulia( 2 ), 3 ] );
<Julia: Any[1, 2, 3]>
gap> JuliaUnbox( list );
[ <Julia: 1>, <Julia: 2>, <Julia: 3> ]
gap> List( JuliaUnbox( list ), JuliaUnbox );
[ 1, 2, 3 ]

##  empty list vs. empty string
gap> emptylist:= ConvertedToJulia( [] );
<Julia: Any[]>
gap> emptystring:= ConvertedToJulia( "" );
<Julia: >
gap> JuliaUnbox( emptylist );
[  ]
gap> JuliaUnbox( emptystring );
""

##  'ConvertedToJulia' for Julia functions (inside arrays)
gap> parse:= JuliaFunction( "parse", "Base" );;
gap> IsIdenticalObj( parse, ConvertedToJulia( parse ) );
true
gap> list:= ConvertedToJulia( [ 1, parse, 3 ] );
<Julia: Any[1, parse, 3]>
gap> list2:= JuliaUnbox( list );
[ <Julia: 1>, <Julia: parse>, <Julia: 3> ]
gap> List( list2, JuliaUnbox );
[ 1, fail, 3 ]

##
gap> STOP_TEST( "box_unbox.tst", 1 );

