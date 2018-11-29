##
gap> START_TEST( "utils.tst" );

##
gap> JuliaTypeInfo( 1 );
"Int64"
gap> JuliaTypeInfo( 0 );
"Int64"
gap> JuliaTypeInfo( GAPToJulia( JuliaEvalString( "Array{Any,1}" ), [ 1, 2, 3 ] ) );
"Array{Any,1}"
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
Error, JuliaEvalString: <string> must be a string

##
gap> JuliaSetVal(fail, 1);
Error, JuliaSetVal: <name> must be a string
gap> JuliaSetVal("foo", JuliaEvalString("1"));
gap> JuliaGetGlobalVariable("foo");
1
gap> JuliaGetGlobalVariable("foo_bar_quux_not_defined");
fail
gap> JuliaGetGlobalVariable();
Error, arguments must be strings function_name[,module_name]
gap> JuliaGetGlobalVariable(fail);
Error, arguments must be strings function_name[,module_name]
gap> JuliaGetGlobalVariable("foo", fail);
Error, arguments must be strings function_name[,module_name]
gap> JuliaGetGlobalVariable("parse", "Base");
<Julia: parse>

##
gap> Julia.Core.Tuple( GAPToJulia( JuliaEvalString( "Array{Any,1}" ), [] ) );
<Julia: ()>
gap> Julia.Core.Tuple( GAPToJulia( JuliaEvalString( "Array{Any,1}" ), [1] ) );
<Julia: (1,)>
gap> Julia.Core.Tuple( GAPToJulia( JuliaEvalString( "Array{GAP.Obj,1}" ), [1,true,fail] ));
<Julia: (1, true, GAP: fail)>
gap> Julia.Core.Tuple(1);
<Julia: (1,)>

##
gap> JuliaSymbol("someSymbol");
<Julia: :someSymbol>
gap> JuliaSymbol("");
<Julia: Symbol("")>
gap> JuliaSymbol(1);
Error, JuliaSymbol: <name> must be a string

##
gap> JuliaModule("Base");
<Julia: Base>
gap> JuliaModule("This_Module_Does_Not_Exist");
Error, JuliaModule: Module <name> does not exists, did you import it?
gap> JuliaModule(1);
Error, JuliaModule: <name> must be a string
gap> JuliaModule( "sqrt" );
Error, JuliaModule: <name> is not a module

##
gap> _JuliaGetGlobalVariable(0);
Error, _JuliaGetGlobalVariable: <name> must be a string
gap> _JuliaGetGlobalVariable("not-a-global-variable");
fail
gap> _JuliaGetGlobalVariable("sqrt");
<Julia: sqrt>

##
gap> _JuliaGetGlobalVariableByModule(0, 0);
Error, _JuliaGetGlobalVariableByModule: <name> must be a string
gap> _JuliaGetGlobalVariableByModule("sqrt", 0);
Error, _JuliaGetGlobalVariableByModule: <module> must be a string or a Julia m\
odule
gap> _JuliaGetGlobalVariableByModule("sqrt", Julia.Base.sqrt);
Error, _JuliaGetGlobalVariableByModule: <module> must be a string or a Julia m\
odule
gap> _JuliaGetGlobalVariableByModule("Base","sqrt");
Error, Not a module
gap> _JuliaGetGlobalVariableByModule("sqrt","Base");
<Julia: sqrt>
gap> _JuliaGetGlobalVariableByModule("sqrt", JuliaModule("Base"));
<Julia: sqrt>

##
gap> JuliaGetFieldOfObject(1, "");
Error, JuliaGetFieldOfObject: <super_obj> must be a Julia object
gap> JuliaGetFieldOfObject(JuliaModule("Base"), fail);
Error, JuliaGetFieldOfObject: <field_name> must be a string
gap> JuliaGetFieldOfObject(JuliaModule("Base"), "not-a-field");
Error, type Module has no field not-a-field

##
gap> NameFunction(Julia.Base.parse);
"parse"
gap> Display(Julia.Base.parse);
function ( arg... )
    <<kernel code>> from Julia:parse
end

##
gap> STOP_TEST( "utils.tst", 1 );
