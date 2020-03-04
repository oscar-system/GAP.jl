##
gap> START_TEST( "convert.tst" );

## convert Julia booleans to GAP booleans (automatic conversion)
gap> JuliaEvalString( "true" );
true
gap> GAPToJulia( true );
true
gap> JuliaEvalString( "false" );
false
gap> GAPToJulia( false );
false
gap> GAPToJulia( fail );  # do we really want this?
fail

## convert Julia integers to GAP integers and rationals

## - for immediate integers
gap> x:= 123;;  xstr:= String( x );;
gap> IsSmallIntRep( x );
true
gap> l:= List( Cartesian( [ [ "", "U" ],
>                           [ "Int" ],
>                           [ "8", "16", "32", "64", "128" ],
>                           [ Concatenation( "(", xstr, ")" ) ] ] ),
>              Concatenation );;
gap> Add( l, Concatenation( "BigInt(", xstr, ")" ) );
gap> ForAll( l, obj -> JuliaToGAP( IsInt, JuliaEvalString( obj ) ) = x );
true
gap> ForAll( l, obj -> JuliaToGAP( IsRat, JuliaEvalString( obj ) ) = x );
true

## - for not immediate integers (only Int64, Int128, BigInt)
gap> x:= 2^60;;  xstr:= String( x );;
gap> IsSmallIntRep( x );
false
gap> l:= List( Cartesian( [ [ "", "U" ],
>                           [ "Int" ],
>                           [ "64", "128" ],
>                           [ Concatenation( "(", xstr, ")" ) ] ] ),
>              Concatenation );;
gap> Add( l, Concatenation( "BigInt(", xstr, ")" ) );
gap> ForAll( l, obj -> JuliaToGAP( IsInt, JuliaEvalString( obj ) ) = x );
true
gap> ForAll( l, obj -> JuliaToGAP( IsRat, JuliaEvalString( obj ) ) = x );
true
gap> x:= 2^70;;  xstr:= String( x );;
gap> IsSmallIntRep( x );
false
gap> l:= List( Cartesian( [ [ "", "U" ],
>                           [ "Int" ],
>                           [ "128" ],
>                           [ Concatenation( "(", xstr, ")" ) ] ] ),
>              Concatenation );;
gap> Add( l, Concatenation( "BigInt(", xstr, ")" ) );
gap> ForAll( l, obj -> JuliaToGAP( IsInt, JuliaEvalString( obj ) ) = x );
true
gap> ForAll( l, obj -> JuliaToGAP( IsRat, JuliaEvalString( obj ) ) = x );
true

## convert Julia rationals to GAP rationals
gap> x:= 1/3;;  xstr:= "1//3";;
gap> l:= List( Cartesian( [ [ "Rational{" ],
>                           [ "", "U" ],
>                           [ "Int" ],
>                           [ "8", "16", "32", "64", "128" ],
>                           [ Concatenation( "}(", xstr, ")" ) ] ] ),
>              Concatenation );;
gap> Add( l, Concatenation( "Rational{BigInt}(", xstr, ")" ) );
gap> ForAll( l, obj -> JuliaToGAP( IsInt, JuliaEvalString( obj ) ) = x );
true
gap> ForAll( l, obj -> JuliaToGAP( IsRat, JuliaEvalString( obj ) ) = x );
true
gap> x:= 1/2^60;;  xstr:= "1//2^60";;
gap> l:= List( Cartesian( [ [ "Rational{" ],
>                           [ "", "U" ],
>                           [ "Int" ],
>                           [ "64", "128" ],
>                           [ Concatenation( "}(", xstr, ")" ) ] ] ),
>              Concatenation );;
gap> Add( l, Concatenation( "Rational{BigInt}(", xstr, ")" ) );
gap> ForAll( l, obj -> JuliaToGAP( IsInt, JuliaEvalString( obj ) ) = x );
true
gap> ForAll( l, obj -> JuliaToGAP( IsRat, JuliaEvalString( obj ) ) = x );
true
gap> x:= 1/2^70;;  xstr:= "1//2^70";;
gap> l:= List( Cartesian( [ [ "Rational{" ],
>                           [ "", "U" ],
>                           [ "Int" ],
>                           [ "128" ],
>                           [ Concatenation( "}(", xstr, ")" ) ] ] ),
>              Concatenation );;
gap> Add( l, Concatenation( "Rational{BigInt}(", xstr, ")" ) );
gap> ForAll( l, obj -> JuliaToGAP( IsInt, JuliaEvalString( obj ) ) = x );
true
gap> ForAll( l, obj -> JuliaToGAP( IsRat, JuliaEvalString( obj ) ) = x );
true

## convert Julia FFEs to GAP FFEs


## convert Julia floats to GAP floats
gap> x:= 1.;;
gap> IsFloat( x );
true
gap> l:= List( Cartesian( [ [ "Float" ],
>                           [ "16", "32", "64" ],
>                           [ Concatenation( "(", String( x ), ")" ) ] ] ),
>              Concatenation );;
gap> ForAll( l, obj -> JuliaToGAP( IsFloat, JuliaEvalString( obj ) ) = x );
true

## convert Julia chars to GAP chars
gap> ForAll( [ 0 .. 255 ],
>            i -> CharInt( i ) =
>                 JuliaToGAP( IsChar, JuliaEvalString( Concatenation(
>                   "Char(", String( i ), ")" ) ) ) );
true
gap> ForAll( [ 0 .. 255 ],
>            i -> CharInt( i ) =
>                 JuliaToGAP( IsChar, JuliaEvalString( Concatenation(
>                   "Cuchar(", String( i ), ")" ) ) ) );
true

## convert Julia strings to GAP strings

#
gap> string := GAPToJulia( Julia.Base.AbstractString, "bla" );
<Julia: "bla">
gap> JuliaToGAP( IsString, string );
"bla"


## convert Julia symbols to GAP strings


--------------------------------------


#
gap> int := GAPToJulia( Julia.Base.Int64, 11 );
11
gap> JuliaToGAP(IsInt,  int );
11

###
###
###

#
gap> ForAll([0..64], n -> JuliaToGAP( IsInt, big2^n) = 2^n);
true
gap> ForAll([0..64], n -> JuliaToGAP( IsInt, -big2^n) = -2^n);
true

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

###  -------------------------------------------------------

## convert Julia dictionaries to GAP records
## (non-recursively and recursively)

gap> dict:= JuliaEvalString( "Dict{Symbol,Any}()" );
gap> JuliaToGAP( IsRecord, dict );
rec(  )
gap> JuliaToGAP( IsRecord, dict, true );
rec(  )
gap> dict:= JuliaEvalString(
>      "Dict( :bool => true, :string => \"abc\", :list => [ 1, 2, 3 ] )" );
gap> JuliaToGAP( IsRecord, dict );
gap> JuliaToGAP( IsRecord, dict, true );
gap> dict.list[1]:= dict;;  # circular reference
gap> JuliaToGAP( IsRecord, dict );
gap> JuliaToGAP( IsRecord, dict, true );

hier!


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
gap> STOP_TEST( "convert.tst" );
