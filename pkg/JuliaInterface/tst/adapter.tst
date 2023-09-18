#
gap> START_TEST( "adapter.tst" );

#
gap> N := JuliaEvalString("big(2)^100");
<Julia: 1267650600228229401496703205376>
gap> N_p1 := JuliaEvalString("big(2)^100 + 1");
<Julia: 1267650600228229401496703205377>
gap> N_m1 := JuliaEvalString("big(2)^100 - 1");
<Julia: 1267650600228229401496703205375>
gap> N_squared := JuliaEvalString("big(2)^200");
<Julia: 1606938044258990275541962092341162602522202993782792835301376>
gap> N_t2 := JuliaEvalString("big(2)^101");
<Julia: 2535301200456458802993406410752>

#
gap> zero := Zero(N);
<Julia: 0>
gap> one := One(N);
<Julia: 1>

# additive and multiplicative inverses
gap> -N;
<Julia: -1267650600228229401496703205376>
gap> N * Inverse(N);
<Julia: 1.0>

#
gap> N + 1;
<Julia: 1267650600228229401496703205377>
gap> 1 + N;
<Julia: 1267650600228229401496703205377>
gap> N + N;
<Julia: 2535301200456458802993406410752>

#
gap> N - 1;
<Julia: 1267650600228229401496703205375>
gap> 1 - N;
<Julia: -1267650600228229401496703205375>
gap> N - N;
<Julia: 0>

#
gap> N * 2;
<Julia: 2535301200456458802993406410752>
gap> 2 * N;
<Julia: 2535301200456458802993406410752>
gap> N * N = N_squared;
true

#
gap> N^0;
<Julia: 1>
gap> N^1;
<Julia: 1267650600228229401496703205376>
gap> N^2 = N_squared;
true

#
gap> N / N;
<Julia: 1.0>
gap> N / 2^50;
<Julia: 1.125899906842624e+15>

#
gap> LQUO(N, N);
<Julia: 1.0>
gap> LQUO(2^50, N);
<Julia: 1.125899906842624e+15>

#
gap> data := [ -N_p1, -N, -N_m1, -1, 0, 1, N_m1, N, N_p1 ];;
gap> TestBinOp := op -> SetX( [1..Length(data)], [1..Length(data)],
>                             {i,j} -> op(data[i], data[j]) = op(i,j) );;
gap> TestBinOp({a,b} -> a < b);
[ true ]
gap> TestBinOp({a,b} -> a <= b);
[ true ]
gap> TestBinOp({a,b} -> a > b);
[ true ]
gap> TestBinOp({a,b} -> a >= b);
[ true ]
gap> TestBinOp({a,b} -> a = b);
[ true ]

#
# lists
#
gap> l := GAPToJulia([1, 2, 3]);
<Julia: Any[1, 2, 3]>
gap> for i in l do Display(i); od;
1
2
3
gap> l[1];
1
gap> l[2] := false;
false
gap> l;
<Julia: Any[1, false, 3]>

#
# "matrices" / lists of lists
#
gap> m:=JuliaEvalString("[1 2; 3 4]");
<Julia: [1 2; 3 4]>
gap> for i in m do Display(i); od;
1
3
2
4
gap> m[3];
2
gap> m[1,2];
2
gap> m[1,2] := 42;
Error, Matrix Assignment: <mat> must be a mutable matrix (not a JuliaObject)

#
# access to fields and properties
#
gap> foo := JuliaEvalString("mutable struct Foo bar end ; Foo(\"Hello\")");
<Julia: Foo("Hello")>
gap> foo.bar;
<Julia: "Hello">
gap> foo.bar := 42;
42
gap> foo;
<Julia: Foo(42)>

#
# use Julia's random sources
#
gap> G:= SymmetricGroup( 100 );;
gap> l:= Elements( SylowSubgroup( G, 97 ) );;
gap> rs:= RandomSource( IsRandomSourceJulia );  # default rng, default seed
<RandomSource in IsRandomSourceJulia>
gap> state:= State( rs );;
gap> state = JuliaPointer( rs );
true
gap> res1:= List( [ 1 .. 10 ], i -> Random( rs, l ) );;
gap> res2:= List( [ 1 .. 10 ], i -> Random( rs, G ) );;
gap> res3:= List( [ 1 .. 10 ], i -> Random( rs, 1, 1000 ) );;
gap> res4:= List( [ 1 .. 10 ], i -> Random( rs, 2^70, 2^70 + 999 ) );;
gap> Reset( rs, state );;
gap> res1 = List( [ 1 .. 10 ], i -> Random( rs, l ) );
true
gap> res2 = List( [ 1 .. 10 ], i -> Random( rs, G ) );
true
gap> res3 = List( [ 1 .. 10 ], i -> Random( rs, 1, 1000 ) );
true
gap> res4 = List( [ 1 .. 10 ], i -> Random( rs, 2^70, 2^70 + 999 ) );
true

# re-initialize does not change the object
gap> rs2:= Init( rs, state );
<RandomSource in IsRandomSourceJulia>
gap> IsIdenticalObj( rs, rs2 );
true
gap> Julia.Base.\=\=( JuliaPointer( rs ), state );
true

# re-initialize resets the state
gap> res1 = List( [ 1 .. 10 ], i -> Random( rs, l ) );
true

# create a random source with prescribed state
gap> state2:= Reset( rs, state );;  # returns old state
gap> rs2:= RandomSource( IsRandomSourceJulia, state2 );
<RandomSource in IsRandomSourceJulia>
gap> List( [ 1 .. 10 ], i -> Random( rs, l ) );; # now both are in sync
gap> Julia.Base.\=\=( JuliaPointer( rs ), JuliaPointer( rs2 ) );
true
gap> Julia.Base.\=\=\=( JuliaPointer( rs ), JuliaPointer( rs2 ) );
false
gap> ForAll( [ 1 .. 100 ], i -> Random( rs, G ) = Random( rs2, G ) );
true

# create a random source with prescribed seed
gap> rs2:= RandomSource( IsRandomSourceJulia, 1234 );
<RandomSource in IsRandomSourceJulia>
gap> ForAny( [ 1 .. 10000 ], i -> Random( rs, G ) <> Random( rs2, G ) );
true

# create a random source by an explicit Julia rng
gap> rs3:= RandomSource( IsRandomSourceJulia, Julia.Random.default_rng() );
<RandomSource in IsRandomSourceJulia>
gap> state3:= State( rs3 );;
gap> res1:= List( [ 1 .. 10 ], i -> Random( rs3, l ) );;
gap> res2:= List( [ 1 .. 10 ], i -> Random( rs3, G ) );;
gap> res3:= List( [ 1 .. 10 ], i -> Random( rs3, 1, 1000 ) );;
gap> Reset( rs3, state3 );;
gap> res1 = List( [ 1 .. 10 ], i -> Random( rs3, l ) );
true
gap> res2 = List( [ 1 .. 10 ], i -> Random( rs3, G ) );
true
gap> res3 = List( [ 1 .. 10 ], i -> Random( rs3, 1, 1000 ) );
true

# different calls with the same seed (e.g., without prescribed seed)
# yield the same sequences of random numbers
gap> rs:= RandomSource( IsRandomSourceJulia );;
gap> rs2:= RandomSource( IsRandomSourceJulia );;
gap> ForAll( [ 1 .. 100 ], i -> Random( rs, G ) = Random( rs2, G ) );
true

# reset and re-initialize using an integer seed
gap> Reset( rs, 1 );;
gap> Init( rs2, 1 );;
gap> ForAll( [ 1 .. 100 ], i -> Random( rs, G ) = Random( rs2, G ) );
true

# possible errors
gap> RandomSource( IsRandomSourceJulia, "random" );
Error, <seed> must be a non-negative integer or a Julia random number generator
gap> Reset( rs, "random" );;
Error, <seed> must be a non-negative integer or a Julia random number generator

#
gap> STOP_TEST( "adapter.tst", 1 );
