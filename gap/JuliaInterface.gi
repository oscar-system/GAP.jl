#
# JuliaInterface: Test interface to julia
#
# Implementations
#

BindJuliaFunc( "string" );

BindJuliaFunc( "include" );

BindGlobal( "JuliaKnownFiles", [] );

BindGlobal( "JuliaIncludeFile", function( filename )
    if not filename in JuliaKnownFiles then
      JuliaCallFunc1Arg( GetJuliaFunc( "include" ), JuliaBox( filename ) );
      AddSet( JuliaKnownFiles, filename );
    fi;
end );


InstallMethod( ViewString,
               [ IsJuliaObject ],

  function( julia_obj )

    return Concatenation( "<Julia: ", String( julia_obj ), ">" );

end );

InstallMethod( String,
               [ IsJuliaObject ],

  function( julia_obj )

    return JuliaUnbox( JuliaCallFunc1Arg( __JuliaFunctions.string, julia_obj ) );

end );

InstallMethod( CallFuncList,
               [ IsJuliaFunction, IsList ],

  function( julia_func, argument_list )

    if Length( argument_list ) = 0 then

        return JuliaCallFunc0Arg( julia_func );

    elif Length( argument_list ) = 1 then

        return JuliaCallFunc1Arg( julia_func, JuliaBox( argument_list[ 1 ] ) );

    elif Length( argument_list ) = 2 then

        return JuliaCallFunc2Arg( julia_func, JuliaBox( argument_list[ 1 ] ), JuliaBox( argument_list[ 2 ] ) );

    elif Length( argument_list ) = 3 then

        return JuliaCallFunc3Arg( julia_func, JuliaBox( argument_list[ 1 ] ), JuliaBox( argument_list[ 2 ] ), JuliaBox( argument_list[ 3 ] ) );

    fi;

    return JuliaCallFuncXArg( julia_func, List( argument_list, JuliaBox ) );

end );

InstallGlobalFunction( ImportJuliaModuleIntoGAP,
  function( name )
    local julia_list_func, function_list, variable_list, i, current_module_rec;

    JuliaEvalString( Concatenation( "using ", name ) );
    Julia.(name) := rec();
    current_module_rec := Julia.(name);
    julia_list_func := JuliaFunctionByModule( "get_function_symbols_in_module", "GAPUtils" );
    function_list := JuliaUnbox( julia_list_func( JuliaModule( name ) ) );
    for i in function_list do
        current_module_rec.(i) := JuliaFunctionByModule( i, name );
    od;
    julia_list_func := JuliaFunctionByModule( "get_variable_symbols_in_module", "GAPUtils" );
    variable_list := JuliaUnbox( julia_list_func( JuliaModule( name ) ) );
    for i in variable_list do
        current_module_rec.(i) := JuliaGetGlobalVariableByModule( i, name );
    od;
end );
