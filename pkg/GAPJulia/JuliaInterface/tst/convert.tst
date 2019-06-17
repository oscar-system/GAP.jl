##
gap> START_TEST( "convert.tst" );

##
gap> typeof := Julia.Base.typeof;;

###
### Integers
###

#
gap> x := JuliaEvalString("Int128(123)");;
gap> typeof(x);
<Julia: Int128>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("Int64(123)");;
gap> typeof(x);
<Julia: Int64>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("Int32(123)");;
gap> typeof(x);
<Julia: Int32>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("Int16(123)");;
gap> typeof(x);
<Julia: Int16>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("Int8(123)");;
gap> typeof(x);
<Julia: Int8>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("UInt128(123)");;
gap> typeof(x);
<Julia: UInt128>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("UInt64(123)");;
gap> typeof(x);
<Julia: UInt64>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("UInt32(123)");;
gap> typeof(x);
<Julia: UInt32>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("UInt16(123)");;
gap> typeof(x);
<Julia: UInt16>
gap> JuliaToGAP(IsInt, x);
123

#
gap> x := JuliaEvalString("UInt8(123)");;
gap> typeof(x);
<Julia: UInt8>
gap> JuliaToGAP(IsInt, x);
123

#
gap> int := GAPToJulia( Julia.Base.Int64, 11 );
11
gap> JuliaToGAP(IsInt,  int );
11

#
gap> x := JuliaEvalString("BigInt(123)");;
gap> typeof(x);
<Julia: BigInt>
gap> JuliaToGAP(IsInt, x);
123

###
### Floats
###

#
gap> x := JuliaEvalString("Float64(1.0)");;
gap> typeof(x);
<Julia: Float64>
gap> JuliaToGAP(IsFloat, x);
1.

#
gap> x := JuliaEvalString("Float32(1.0)");;
gap> typeof(x);
<Julia: Float32>
gap> JuliaToGAP(IsFloat, x);
1.

#
gap> x := JuliaEvalString("Float16(1.0)");;
gap> typeof(x);
<Julia: Float16>
gap> JuliaToGAP(IsFloat, x);
1.

###
###
###

#
gap> big2 := JuliaEvalString("big(2)");
<Julia: 2>
gap> Zero(big2);
<Julia: 0>
gap> JuliaToGAP( IsInt, Zero(big2) );
0
gap> ForAll([0..64], n -> JuliaToGAP( IsInt, big2^n) = 2^n);
true
gap> ForAll([0..64], n -> JuliaToGAP( IsInt, -big2^n) = -2^n);
true

#
gap> string := GAPToJulia( Julia.Base.AbstractString, "bla" );
<Julia: "bla">
gap> JuliaToGAP( IsString, string );
"bla"
gap> GAPToJulia( true );
true
gap> GAPToJulia( false );
false

##
gap> list:= GAPToJulia( [ 1, 2, 3 ] );
<Julia: Any[1, 2, 3]>
gap> JuliaToGAP( IsList, list );
[ 1, 2, 3 ]

##  empty list vs. empty string
gap> emptylist:= GAPToJulia( JuliaEvalString( "Array{Any,1}"), [] );
<Julia: Any[]>
gap> emptystring:= GAPToJulia( Julia.Base.AbstractString, "" );
<Julia: "">
gap> JuliaToGAP( IsList, emptylist );
[  ]
gap> JuliaToGAP( IsString, emptystring );
""

##  'GAPToJulia' for Julia functions (inside arrays)
gap> parse:= JuliaFunction( "parse", "Base" );;
gap> list:= GAPToJulia( JuliaEvalString( "Array{Any,1}"), [ 1, parse, 3 ] );
<Julia: Any[1, parse, 3]>
gap> list2:= JuliaToGAP( IsList, list );
[ 1, <Julia: parse>, 3 ]

##
gap> xx := JuliaEvalString("GAP.Globals.PROD(2^59,2^59)");;
gap> JuliaToGAP( IsInt, xx );
332306998946228968225951765070086144

###
###  Records/Dictionaries
###

##  empty record
gap> dict:= GAPToJulia( rec() );
<Julia: Dict{Symbol,Any}()>
gap> JuliaToGAP( IsRecord, dict );
rec(  )

##  nested record: non-recursive vs. recursive
gap> dict:= GAPToJulia( rec( bool:= true,
>                            string:= "abc",
>                            list:= [ 1, 2, 3 ],
>                          ) );;
gap> JuliaToGAP( IsRecord, dict );
rec( bool := true, list := <Julia: Any[1, 2, 3]>, string := <Julia: "abc"> )
gap> JuliaToGAP( IsRecord, dict, true );
rec( bool := true, list := [ 1, 2, 3 ], string := "abc" )

##  something where recursive conversion would run into a Julia error
gap> dict:= GAPToJulia( rec( juliafunc:= Julia.Base.map,
>                          ) );
<Julia: Dict{Symbol,Any}(:juliafunc=>map)>
gap> JuliaToGAP( IsRecord, dict );
rec( juliafunc := <Julia: map> )

##
gap> STOP_TEST( "convert.tst", 1 );
