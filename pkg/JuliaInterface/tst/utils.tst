##
gap> START_TEST( "utils.tst" );

##
gap> JuliaTypeInfo( 1 );
"Int64"
gap> JuliaTypeInfo( 0 );
"Int64"
gap> JuliaTypeInfo( GAPToJulia( JuliaEvalString( "Tuple{Int64, Int64, Int64}" ), [ 1, 2, 3 ] ) );
"Tuple{Int64, Int64, Int64}"
gap> JuliaTypeInfo( Julia.Base.parse );
"typeof(parse)"

##
gap> CallJuliaFunctionWithCatch( Julia.Base.sqrt, [ 4 ] );
rec( ok := true, value := <Julia: 2.0> )
gap> CallJuliaFunctionWithCatch( Julia.Base.sqrt, [ -1 ] );
rec( ok := false, 
  value := "DomainError(-1.0, \"sqrt will only return a complex result if call\
ed with a complex argument. Try sqrt(Complex(x)).\")" )

##
gap> JuliaEvalString(fail);
Error, JuliaEvalString: <string> must be a string (not the value 'fail')

##
gap> JuliaSetVal(fail, 1);
Error, JuliaSetVal: <name> must be a string (not the value 'fail')
gap> JuliaSetVal("foo", JuliaEvalString("1"));
gap> Julia.Main.foo;
1

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
gap> JuliaSymbol("someSymbol");
<Julia: :someSymbol>
gap> JuliaSymbol("");
<Julia: Symbol("")>
gap> JuliaSymbol(1);
Error, JuliaSymbol: <name> must be a string (not the integer 1)

##
gap> JuliaModule("Base");
<Julia: Base>
gap> JuliaModule("This_Module_Does_Not_Exist");
Error, JuliaModule: Module <name> does not exist, did you import it?
gap> JuliaModule(1);
Error, JuliaModule: <name> must be a string
gap> JuliaModule( "sqrt" );
Error, JuliaModule: <name> is not a module

##
gap> _JuliaGetGlobalVariable(0);
Error, _JuliaGetGlobalVariable: <name> must be a string (not the integer 0)
gap> _JuliaGetGlobalVariable("not-a-global-variable");
fail
gap> _JuliaGetGlobalVariable("sqrt");
<Julia: sqrt>

##
gap> _JuliaGetGlobalVariableByModule(0, 0);
Error, _JuliaGetGlobalVariableByModule: <name> must be a string (not the integ\
er 0)
gap> _JuliaGetGlobalVariableByModule("sqrt", 0);
Error, _JuliaGetGlobalVariableByModule: <module> must be a string or a Julia m\
odule
gap> _JuliaGetGlobalVariableByModule("sqrt", Julia.Base.sqrt);
Error, _JuliaGetGlobalVariableByModule: <module> must be a string or a Julia m\
odule
gap> _JuliaGetGlobalVariableByModule("Base","sqrt");
Error, sqrt is not a module
gap> _JuliaGetGlobalVariableByModule("sqrt","Base");
<Julia: sqrt>
gap> _JuliaGetGlobalVariableByModule("sqrt", JuliaModule("Base"));
<Julia: sqrt>

##
gap> NameFunction(Julia.Base.parse);
"parse"
gap> Display(Julia.Base.parse);
function ( arg... )
    <<kernel code>> from Julia:parse
end

##
gap> STOP_TEST( "utils.tst", 1 );
