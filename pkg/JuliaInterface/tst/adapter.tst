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

#
gap> -N;
<Julia: -1267650600228229401496703205376>

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
gap> STOP_TEST( "adapter.tst", 1 );
