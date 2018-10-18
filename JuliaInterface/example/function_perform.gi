LoadPackage( "JuliaInterface" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "example" );

JuliaIncludeFile( Filename( dirs, "function_perform.jl" ) );

typed_func := JuliaFunction("typed_func", "GapFunctionPerform");
typed_funcNoConv := _JuliaFunctionByModule("typed_func", "GapFunctionPerform", false);
typed_funcC := JuliaBindCFunction( "GapFunctionPerform.typed_func", ["a", "b"] );

untyped_func := JuliaFunction("untyped_func");
untyped_funcNoConv := _JuliaFunction("untyped_func", false);
untyped_funcC := JuliaBindCFunction( "untyped_func", ["a", "b"] );

GASMAN("collect"); ListX([1..10^5], [1..10], {i,j} -> i);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], ReturnFirst);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], typed_func);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], untyped_func);; time;
# GASMAN("collect"); ListX([1..10^5], [1..10], typed_funcC);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], untyped_funcC);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], typed_funcNoConv);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], untyped_funcNoConv);; time;


GASMAN("collect"); ListX("0123456789", [1..10^5], {i,j} -> i);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], ReturnFirst);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], typed_func);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], untyped_func);; time;
# GASMAN("collect"); ListX("0123456789", [1..10^5], typed_funcC);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], untyped_funcC);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], typed_funcNoConv);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], untyped_funcNoConv);; time;


input:=ListWithIdenticalEntries(10^5,fail);;
GASMAN("collect"); ListX("0123456789", input, {i,j} -> i);; time;
GASMAN("collect"); ListX("0123456789", input, ReturnFirst);; time;
GASMAN("collect"); ListX("0123456789", input, typed_func);; time;
GASMAN("collect"); ListX("0123456789", input, untyped_func);; time;
# GASMAN("collect"); ListX("0123456789", input, typed_funcC);; time;
GASMAN("collect"); ListX("0123456789", input, untyped_funcC);; time;
GASMAN("collect"); ListX("0123456789", input, typed_funcNoConv);; time;
GASMAN("collect"); ListX("0123456789", input, untyped_funcNoConv);; time;