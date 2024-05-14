##
gap> START_TEST( "calls.tst" );

#
# calls without function wrapping
#

# variadic function
gap> f := JuliaEvalString("function f(x...) return x end");;

#
gap> f();
<Julia: ()>

#
gap> f(true);
<Julia: (true,)>

#
gap> f(true,2);
<Julia: (true, 2)>

#
gap> f(true,2,3);
<Julia: (true, 2, 3)>

#
gap> f(true,2,3,4);
<Julia: (true, 2, 3, 4)>

#
gap> f(true,2,3,4,5);
<Julia: (true, 2, 3, 4, 5)>

#
gap> f(true,2,3,4,5,6);
<Julia: (true, 2, 3, 4, 5, 6)>

#
gap> f(true,2,3,4,5,6,7);
<Julia: (true, 2, 3, 4, 5, 6, 7)>

# non-variadic functions
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
gap> f1(true);
<Julia: (true,)>

#
gap> f2(true,2);
<Julia: (true, 2)>

#
gap> f3(true,2,3);
<Julia: (true, 2, 3)>

#
gap> f4(true,2,3,4);
<Julia: (true, 2, 3, 4)>

#
gap> f5(true,2,3,4,5);
<Julia: (true, 2, 3, 4, 5)>

#
gap> f6(true,2,3,4,5,6);
<Julia: (true, 2, 3, 4, 5, 6)>

#
gap> f7(true,2,3,4,5,6,7);
<Julia: (true, 2, 3, 4, 5, 6, 7)>

#
# calls via function wrappers
#

# variadic function
gap> fw := JuliaFunction("f");;

#
gap> fw();
<Julia: ()>

#
gap> fw(true);
<Julia: (true,)>

#
gap> fw(true,2);
<Julia: (true, 2)>

#
gap> fw(true,2,3);
<Julia: (true, 2, 3)>

#
gap> fw(true,2,3,4);
<Julia: (true, 2, 3, 4)>

#
gap> fw(true,2,3,4,5);
<Julia: (true, 2, 3, 4, 5)>

#
gap> fw(true,2,3,4,5,6);
<Julia: (true, 2, 3, 4, 5, 6)>

#
gap> fw(true,2,3,4,5,6,7);
<Julia: (true, 2, 3, 4, 5, 6, 7)>

# non-variadic functions
gap> f0w := JuliaFunction("f0");;
gap> f1w := JuliaFunction("f1");;
gap> f2w := JuliaFunction("f2");;
gap> f3w := JuliaFunction("f3");;
gap> f4w := JuliaFunction("f4");;
gap> f5w := JuliaFunction("f5");;
gap> f6w := JuliaFunction("f6");;
gap> f7w := JuliaFunction("f7");;

#
gap> f0w();
<Julia: nothing>

#
gap> f1w(true);
<Julia: (true,)>

#
gap> f2w(true,2);
<Julia: (true, 2)>

#
gap> f3w(true,2,3);
<Julia: (true, 2, 3)>

#
gap> f4w(true,2,3,4);
<Julia: (true, 2, 3, 4)>

#
gap> f5w(true,2,3,4,5);
<Julia: (true, 2, 3, 4, 5)>

#
gap> f6w(true,2,3,4,5,6);
<Julia: (true, 2, 3, 4, 5, 6)>

#
gap> f7w(true,2,3,4,5,6,7);
<Julia: (true, 2, 3, 4, 5, 6, 7)>

#
# calls via wrapped C function pointers
#

#
gap> g0 := JuliaEvalString("function g0() return C_NULL end");;
gap> g1 := JuliaEvalString("function g1(a) return a end");;
gap> g2 := JuliaEvalString("function g2(a,b) return b end");;
gap> g3 := JuliaEvalString("function g3(a,b,c) return c end");;
gap> g4 := JuliaEvalString("function g4(a,b,c,d) return d end");;
gap> g5 := JuliaEvalString("function g5(a,b,c,d,e) return e end");;
gap> g6 := JuliaEvalString("function g6(a,b,c,d,e,f) return f end");;
gap> g7 := JuliaEvalString("function g7(a,b,c,d,e,f,g) return g end");;

#
gap> Julia.typeof( g0() );
<Julia: Ptr{Nothing}>
gap> g1(true);
true
gap> g2(true,2);
2
gap> g3(true,2,3);
3
gap> g4(true,2,3,4);
4
gap> g5(true,2,3,4,5);
5
gap> g6(true,2,3,4,5,6);
6

#
gap> h0 := JuliaEvalString("function h0() end");;
gap> h1 := JuliaEvalString("function h1(a) end");;
gap> h2 := JuliaEvalString("function h2(a,b) end");;
gap> h3 := JuliaEvalString("function h3(a,b,c) end");;
gap> h4 := JuliaEvalString("function h4(a,b,c,d) end");;
gap> h5 := JuliaEvalString("function h5(a,b,c,d,e) end");;
gap> h6 := JuliaEvalString("function h6(a,b,c,d,e,f) end");;

#
# handling invalid inputs
#

#
gap> JuliaFunction();
Error, arguments must be strings function_name[,module_name]
gap> JuliaFunction(fail);
Error, arguments must be strings function_name[,module_name]
gap> JuliaFunction("foo_bar_quux_not_defined");
Error, Function is not defined in julia

#
gap> _JuliaFunction(fail);
Error, argument is not a julia object or string
gap> _JuliaFunction("foo_bar_quux_not_defined");
Error, Function is not defined in julia

#
gap> _JuliaFunctionByModule(fail, fail);
Error, _JuliaFunctionByModule: <funcName> must be a string (not the value 'fai\
l')
gap> _JuliaFunctionByModule("foo", fail);
Error, _JuliaFunctionByModule: <moduleName> must be a string (not the value 'f\
ail')
gap> _JuliaFunctionByModule("foo", "bar");
Error, bar not defined
gap> _JuliaFunctionByModule("foo", "Int");
Error, Int is not a module
gap> _JuliaFunctionByModule("foo", "Base");
Error, Function Base.foo is not defined in julia
gap> _JuliaFunctionByModule("parse", "Base");
<Julia: parse>

#
gap> STOP_TEST( "calls.tst" );
