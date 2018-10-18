##
gap> START_TEST( "calls.tst" );

#
gap> f := JuliaEvalString("function f(x...) return x end");;

#
gap> f();
<Julia: ()>

#
gap> f(1);
<Julia: (1,)>

#
gap> f(1,2);
<Julia: (1, 2)>

#
gap> f(1,2,3);
<Julia: (1, 2, 3)>

#
gap> f(1,2,3,4);
<Julia: (1, 2, 3, 4)>

#
gap> f(1,2,3,4,5);
<Julia: (1, 2, 3, 4, 5)>

#
gap> f(1,2,3,4,5,6);
<Julia: (1, 2, 3, 4, 5, 6)>

#
gap> f(1,2,3,4,5,6,7);
<Julia: (1, 2, 3, 4, 5, 6, 7)>

#
gap> f0 := JuliaEvalString("function f0() end");;
gap> f1 := JuliaEvalString("function f1(a) return (a,) end");;
gap> f2 := JuliaEvalString("function f2(a,b) return (a,b) end");;
gap> f3 := JuliaEvalString("function f3(a,b,c) return (a,b,c) end");;
gap> f4 := JuliaEvalString("function f4(a,b,c,d) return (a,b,c,d) end");;
gap> f5 := JuliaEvalString("function f5(a,b,c,d,e) return (a,b,c,d,e) end");;
gap> f6 := JuliaEvalString("function f6(a,b,c,d,e,f) return (a,b,c,d,e,f) end");;
gap> f7 := JuliaEvalString("function f7(a,b,c,d,e,f,g) return (a,b,c,d,e,f,g) end");;

#
gap> f0();
<Julia: nothing>

#
gap> f1(1);
<Julia: (1,)>

#
gap> f2(1,2);
<Julia: (1, 2)>

#
gap> f3(1,2,3);
<Julia: (1, 2, 3)>

#
gap> f4(1,2,3,4);
<Julia: (1, 2, 3, 4)>

#
gap> f5(1,2,3,4,5);
<Julia: (1, 2, 3, 4, 5)>

#
gap> f6(1,2,3,4,5,6);
<Julia: (1, 2, 3, 4, 5, 6)>

#
gap> f7(1,2,3,4,5,6,7);
<Julia: (1, 2, 3, 4, 5, 6, 7)>

#
gap> STOP_TEST( "calls.tst", 1 );
