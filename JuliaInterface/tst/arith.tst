#
gap> START_TEST( "arith.tst" );

#
gap> large_int := JuliaEvalString("big(2)^100");
<Julia: 1267650600228229401496703205376>
gap> large_int_p1 := JuliaEvalString("big(2)^100 + 1");
<Julia: 1267650600228229401496703205377>
gap> large_int_m1 := JuliaEvalString("big(2)^100 - 1");
<Julia: 1267650600228229401496703205375>
gap> large_int_squared := JuliaEvalString("big(2)^200");
<Julia: 1606938044258990275541962092341162602522202993782792835301376>
gap> large_int_t2 := JuliaEvalString("big(2)^101");
<Julia: 2535301200456458802993406410752>

#
gap> zero := Zero(large_int);
<Julia: 0>
gap> one := One(large_int);
<Julia: 1>

#
gap> large_int + 1 = large_int_p1;
true
gap> 1 + large_int = large_int_p1;
true

#
gap> large_int + (-large_int) = zero;
true

#
gap> large_int - 1 = large_int_m1;
true

#
gap> large_int * 2 = large_int_t2;
true
gap> 2 * large_int = large_int_t2;
true
gap> large_int * large_int = large_int_squared;
true

#
gap> large_int^0 = one;
true
gap> large_int^1 = large_int;
true
gap> large_int^2 = large_int_squared;
true

#
#gap> large_int / large_int = 1;
#true
#gap> large_int / 2^50 = 2^50;
#true

#
#gap> large_int \ large_int = 1;
#true
#gap> 2^50 \ large_int = 2^50;
#true

#
gap> large_int < large_int_p1;
true
gap> large_int <= large_int_p1;
true
gap> large_int > large_int_m1;
true
gap> large_int >= large_int_m1;
true
gap> large_int = large_int;
true

#
#gap> mod(large_int,2) = 0;
#gap> mod(large_int_p1,2) = 1;

#
gap> STOP_TEST( "arith.tst", 1 );
