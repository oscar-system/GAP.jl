LoadPackage( "JuliaInterface" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "example" );

JuliaIncludeFile( Filename( dirs, "function_perform.jl" ) );

return_first := Julia.GapFunctionPerform.return_first;
return_first_raw := JuliaEvalString("GapFunctionPerform.return_first");

GASMAN("collect"); ListX([1..10^5], [1..10], {i,j} -> i);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], ReturnFirst);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], return_first);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], Julia.GapFunctionPerform.return_first);; time;
GASMAN("collect"); ListX([1..10^5], [1..10], return_first_raw);; time;

GASMAN("collect"); ListX("0123456789", [1..10^5], {i,j} -> i);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], ReturnFirst);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], return_first);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], Julia.GapFunctionPerform.return_first);; time;
GASMAN("collect"); ListX("0123456789", [1..10^5], return_first_raw);; time;

input:=ListWithIdenticalEntries(10^5,fail);;
GASMAN("collect"); ListX("0123456789", input, {i,j} -> i);; time;
GASMAN("collect"); ListX("0123456789", input, ReturnFirst);; time;
GASMAN("collect"); ListX("0123456789", input, return_first);; time;
GASMAN("collect"); ListX("0123456789", input, Julia.GapFunctionPerform.return_first);; time;
GASMAN("collect"); ListX("0123456789", input, return_first_raw);; time;
