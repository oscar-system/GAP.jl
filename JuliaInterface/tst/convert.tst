##
gap> START_TEST( "convert.tst" );

##
gap> typeof := JuliaFunction("typeof");;

###
### Integers
###

#
gap> x := JuliaEvalString("Int64(123)");;
gap> typeof(x);
<Julia: Int64>
gap> ConvertedFromJulia(x);
123

#
gap> x := JuliaEvalString("Int32(123)");;
gap> typeof(x);
<Julia: Int32>
gap> ConvertedFromJulia(x);
123

#
gap> x := JuliaEvalString("Int16(123)");;
gap> typeof(x);
<Julia: Int16>
gap> ConvertedFromJulia(x);
123

#
gap> x := JuliaEvalString("Int8(123)");;
gap> typeof(x);
<Julia: Int8>
gap> ConvertedFromJulia(x);
123

#
gap> x := JuliaEvalString("UInt64(123)");;
gap> typeof(x);
<Julia: UInt64>
gap> ConvertedFromJulia(x);
123

#
gap> x := JuliaEvalString("UInt32(123)");;
gap> typeof(x);
<Julia: UInt32>
gap> ConvertedFromJulia(x);
123

#
gap> x := JuliaEvalString("UInt16(123)");;
gap> typeof(x);
<Julia: UInt16>
gap> ConvertedFromJulia(x);
123

#
gap> x := JuliaEvalString("UInt8(123)");;
gap> typeof(x);
<Julia: UInt8>
gap> ConvertedFromJulia(x);
123

#
gap> int := ConvertedToJulia( 11 );
<Julia: 11>
gap> ConvertedFromJulia( int );
11

# TODO: Int128
# TODO: UInt128

###
### Floats
###

#
gap> x := JuliaEvalString("Float64(1.0)");;
gap> typeof(x);
<Julia: Float64>
gap> ConvertedFromJulia(x);
1.

#
gap> x := JuliaEvalString("Float32(1.0)");;
gap> typeof(x);
<Julia: Float32>
gap> ConvertedFromJulia(x);
1.

# TODO: Float16

###
###
###

#
gap> string := ConvertedToJulia( "bla" );
<Julia: "bla">
gap> ConvertedFromJulia( string );
"bla"
gap> bool := ConvertedToJulia( true );
<Julia: true>
gap> ConvertedFromJulia( bool );
true
gap> bool := ConvertedToJulia( false );
<Julia: false>
gap> ConvertedFromJulia( bool );
false

##
gap> list:= ConvertedToJulia( [ 1, ConvertedToJulia( 2 ), 3 ] );
<Julia: Any[1, 2, 3]>
gap> ConvertedFromJulia( list );
[ <Julia: 1>, <Julia: 2>, <Julia: 3> ]
gap> List( ConvertedFromJulia( list ), ConvertedFromJulia );
[ 1, 2, 3 ]

##  empty list vs. empty string
gap> emptylist:= ConvertedToJulia( [] );
<Julia: Any[]>
gap> emptystring:= ConvertedToJulia( "" );
<Julia: "">
gap> ConvertedFromJulia( emptylist );
[  ]
gap> ConvertedFromJulia( emptystring );
""

##  'ConvertedToJulia' for Julia functions (inside arrays)
gap> parse:= JuliaFunction( "parse", "Base" );;
gap> IsIdenticalObj( parse, ConvertedToJulia( parse ) );
true
gap> list:= ConvertedToJulia( [ 1, parse, 3 ] );
<Julia: Any[1, parse, 3]>
gap> list2:= ConvertedFromJulia( list );
[ <Julia: 1>, <Julia: parse>, <Julia: 3> ]
gap> List( list2, ConvertedFromJulia );
[ 1, fail, 3 ]

##
gap> JuliaEvalString("GAP.GAPFuncs.PROD(2^59,2^59)");
332306998946228968225951765070086144

##
gap> STOP_TEST( "convert.tst", 1 );
