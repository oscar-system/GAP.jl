#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##
#@local typeof,x,int,big2,string,list,emptylist,emptystring,parse,list2,xx
#@local dict,i
gap> START_TEST( "convert.tst" );

##
gap> typeof := Julia.Base.typeof;;

###
### Integers
###

#
gap> x := Julia.Int128(123);;
gap> typeof(x);
<Julia: Int128>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.Int64(123);;
gap> typeof(x);
<Julia: Int64>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.Int32(123);;
gap> typeof(x);
<Julia: Int32>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.Int16(123);;
gap> typeof(x);
<Julia: Int16>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.Int8(123);;
gap> typeof(x);
<Julia: Int8>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.UInt128(123);;
gap> typeof(x);
<Julia: UInt128>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.UInt64(123);;
gap> typeof(x);
<Julia: UInt64>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.UInt32(123);;
gap> typeof(x);
<Julia: UInt32>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.UInt16(123);;
gap> typeof(x);
<Julia: UInt16>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> x := Julia.UInt8(123);;
gap> typeof(x);
<Julia: UInt8>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

#
gap> int := GAPToJulia( Julia.Base.Int64, 11 );
11
gap> int = GAPToJulia( 11, true );
true
gap> JuliaToGAP(IsInt,  int );
11
gap> GAP_jl.Obj( int );
11

#
gap> GAPToJulia( Z(3) );
Z(3)
gap> GAPToJulia( Z(3), false );
Z(3)

#
gap> x := Julia.BigInt(123);;
gap> typeof(x);
<Julia: BigInt>
gap> JuliaToGAP(IsInt, x);
123
gap> GAP_jl.Obj(x);
123

###
### Floats
###

#
gap> x := Julia.Float64(1);;
gap> typeof(x);
<Julia: Float64>
gap> JuliaToGAP(IsFloat, x);
1.
gap> GAP_jl.Obj(x);
1.

#
gap> x := Julia.Float32(1);;
gap> typeof(x);
<Julia: Float32>
gap> JuliaToGAP(IsFloat, x);
1.
gap> GAP_jl.Obj(x);
1.

#
gap> x := Julia.Float16(1);;
gap> typeof(x);
<Julia: Float16>
gap> JuliaToGAP(IsFloat, x);
1.
gap> GAP_jl.Obj(x);
1.

###
###
###

#
gap> big2 := Julia.big(2);
<Julia: 2>
gap> Zero(big2);
<Julia: 0>
gap> JuliaToGAP( IsInt, Zero(big2) );
0
gap> GAP_jl.Obj( Zero(big2) );
0
gap> ForAll([0..64], n -> JuliaToGAP( IsInt, big2^n) = 2^n);
true
gap> ForAll([0..64], n -> GAP_jl.Obj( big2^n ) = 2^n);
true
gap> ForAll([0..64], n -> JuliaToGAP( IsInt, -big2^n) = -2^n);
true
gap> ForAll([0..64], n -> GAP_jl.Obj( -big2^n ) = -2^n);
true

#
gap> string := GAPToJulia( Julia.Base.String, "bla" );
<Julia: "bla">
gap> JuliaToGAP( IsString, string );
"bla"
gap> GAP_jl.Obj( string );
"bla"
gap> GAPToJulia( true );
true
gap> GAPToJulia( false );
false
gap> GAPToJulia( true, false );
true

##
gap> list:= GAPToJulia( [ 1, 2, 3 ] );
<Julia: Any[1, 2, 3]>
gap> JuliaToGAP( IsList, list );
[ 1, 2, 3 ]
gap> GAP_jl.Obj( list );
[ 1, 2, 3 ]

##  ranges
gap> GAP_jl.GapObj( JuliaEvalString( "1:3" ) );
[ 1 .. 3 ]
gap> GAP_jl.GapObj( JuliaEvalString( "1:2:5" ) );
[ 1, 3 .. 5 ]
gap> GAP_jl.GapObj( JuliaEvalString( "3:2" ) );
[  ]
gap> GAP_jl.Obj( JuliaEvalString( "1:3" ) );
[ 1 .. 3 ]
gap> GAP_jl.Obj( JuliaEvalString( "1:2:5" ) );
[ 1, 3 .. 5 ]
gap> GAP_jl.Obj( JuliaEvalString( "3:2" ) );
[  ]
gap> JuliaToGAP( IsList, JuliaEvalString( "1:3" ) );
[ 1 .. 3 ]
gap> JuliaToGAP( IsList, JuliaEvalString( "1:2:5" ) );
[ 1, 3 .. 5 ]
gap> JuliaToGAP( IsList, JuliaEvalString( "3:2" ) );
[  ]
gap> JuliaToGAP( IsRange, JuliaEvalString( "1:3" ) );
[ 1 .. 3 ]
gap> JuliaToGAP( IsRange, JuliaEvalString( "1:2:5" ) );
[ 1, 3 .. 5 ]
gap> JuliaToGAP( IsRange, JuliaEvalString( "3:2" ) );
[  ]
gap> JuliaToGAP( IsRange, JuliaEvalString( "[ 1, 2, 3 ]" ) );
Error, <obj> must be a Julia range
gap> JuliaToGAP( IsRange, JuliaEvalString( "[ 1, 2, 4 ]" ) );
Error, <obj> must be a Julia range

##  empty list vs. empty string
gap> emptylist:= GAPToJulia( JuliaType( Julia.Vector, [ Julia.Any ] ), [] );
<Julia: Any[]>
gap> emptystring:= GAPToJulia( Julia.Base.String, "" );
<Julia: "">
gap> JuliaToGAP( IsList, emptylist );
[  ]
gap> GAP_jl.Obj( emptylist );
[  ]
gap> JuliaToGAP( IsString, emptystring );
""
gap> GAP_jl.Obj( emptystring );
""

##  'GAPToJulia' for Julia functions (inside arrays)
gap> parse:= Julia.parse;
<Julia: parse>
gap> list:= GAPToJulia( JuliaType( Julia.Vector, [ Julia.Any ] ),
>             [ 1, parse, 3 ], true );
<Julia: Any[1, parse, 3]>
gap> list2:= JuliaToGAP( IsList, list );
[ 1, <Julia: parse>, 3 ]
gap> GAP_jl.Obj( list );
[ 1, <Julia: parse>, 3 ]

##
gap> xx := JuliaEvalString("GAP.Globals.PROD(2^59,2^59)");;
gap> JuliaToGAP( IsInt, xx );
332306998946228968225951765070086144
gap> GAP_jl.Obj( xx );
332306998946228968225951765070086144

###
###  Records/Dictionaries
###

##  empty record
gap> dict:= GAPToJulia( rec() );
<Julia: Dict{Symbol,Any}()>
gap> JuliaToGAP( IsRecord, dict );
rec(  )
gap> GAP_jl.Obj( dict );
rec(  )

##  nested record: non-recursive vs. recursive
gap> dict:= GAPToJulia( rec( bool:= true,
>                            string:= "abc",
>                            list:= [ 1, 2, 3 ],
>                          ), true );;
gap> JuliaToGAP( IsRecord, dict );
rec( bool := true, list := <Julia: Any[1, 2, 3]>, string := <Julia: "abc"> )
gap> GAP_jl.Obj( dict );
rec( bool := true, list := <Julia: Any[1, 2, 3]>, string := <Julia: "abc"> )
gap> JuliaToGAP( IsRecord, dict, true );
rec( bool := true, list := [ 1, 2, 3 ], string := "abc" )
gap> GAP_jl.Obj( dict, true );
rec( bool := true, list := [ 1, 2, 3 ], string := "abc" )

##  something where recursive conversion would run into a Julia error
gap> dict:= GAPToJulia( rec( juliafunc:= Julia.Base.map ), true );
<Julia: Dict{Symbol,Any}(:juliafunc=>map)>
gap> JuliaToGAP( IsRecord, dict );
rec( juliafunc := <Julia: map> )
gap> GAP_jl.Obj( dict );
rec( juliafunc := <Julia: map> )

# iterating over dict gives key-value pairs
gap> dict:= GAPToJulia( rec( a := 1, b := 2 ) );
<Julia: Dict{Symbol, Any}(:a => 1, :b => 2)>
gap> for i in dict do Display(i); od;
Pair{Symbol, Any}(:a, 1)
Pair{Symbol, Any}(:b, 2)

##
gap> STOP_TEST( "convert.tst" );
