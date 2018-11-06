#
gap> START_TEST( "arith.tst" );

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
#gap> mod(N,2) = 0;
#gap> mod(N_p1,2) = 1;

#
gap> STOP_TEST( "arith.tst", 1 );
