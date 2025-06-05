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
gap> START_TEST( "utils.tst" );

##
gap> CallJuliaFunctionWithCatch( Julia.Base.sqrt, [ 4 ] );
rec( ok := true, value := <Julia: 2.0> )
gap> res:= CallJuliaFunctionWithCatch( Julia.Base.sqrt, [ -1 ] );;
gap> res.ok;
false
gap> StartsWith( res.value, "DomainError" );
true
gap> CallJuliaFunctionWithCatch( Julia.Base.sqrt, [ 4 ], rec() );
rec( ok := true, value := <Julia: 2.0> )

##
gap> JuliaEvalString(fail);
Error, JuliaEvalString: <string> must be a string (not the value 'fail')

##
gap> Julia.Core.Tuple( GAPToJulia( JuliaEvalString( "Vector{Any}" ), [] ) );
<Julia: ()>
gap> Julia.Core.Tuple( GAPToJulia( JuliaEvalString( "Vector{Any}" ), [1] ) );
<Julia: (1,)>
gap> Julia.Core.Tuple( GAPToJulia( JuliaEvalString( "Vector{GAP.Obj}" ), [1,true,fail] ));
<Julia: (1, true, GAP: fail)>
gap> Julia.Core.Tuple(1);
<Julia: (1,)>

##
gap> Julia.Symbol("someSymbol");
<Julia: :someSymbol>
gap> Julia.Symbol("");
<Julia: Symbol("")>

##
gap> _JuliaGetGlobalVariableByModule(0, 0);
Error, _JuliaGetGlobalVariableByModule: <name> must be a string (not the integ\
er 0)
gap> _JuliaGetGlobalVariableByModule("sqrt", 0);
Error, _JuliaGetGlobalVariableByModule: <module> must be a Julia module
gap> _JuliaGetGlobalVariableByModule("sqrt", Julia.Base);
<Julia: sqrt>

##
gap> NameFunction(Julia.Base.parse);
"parse"
gap> Display(Julia.Base.parse);
# Julia:parse
function ( arg... )
    <<kernel code>> from Julia:parse
end

##
gap> IsBound(Julia.Main.f00bar);
false
gap> Julia.Main.f00bar := 1;
1
gap> IsBound(Julia.Main.f00bar);
true
gap> Unbind(Julia.Main.f00bar);
Error, cannot unbind Julia variables

##
gap> GetJuliaScratchspace( true);
Error, GetJuliaScratchspace: <key> must be a string
gap> path:= GetJuliaScratchspace( "test_scratch" );;
gap> IsDirectoryPath( path );
true

# Julia modules should not get cached, see #1044
gap> JuliaEvalString("module foo  x = 1 end");
<Julia module Main.foo>
gap> Julia.foo.x;
1
gap> JuliaEvalString("module foo  x = 2 end");
<Julia module Main.foo>
gap> Julia.foo.x;
2

##
gap> STOP_TEST( "utils.tst" );
