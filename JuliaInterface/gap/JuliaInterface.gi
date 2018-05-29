#
# JuliaInterface: Test interface to julia
#
# Implementations
#

InstallGlobalFunction( JuliaFunction,
  function( arglist... )
    if Length( arglist ) = 1 and IsString( arglist[ 1 ] ) then
        return __JuliaFunction( arglist[ 1 ] );
    elif Length( arglist ) = 2 and ForAll( arglist, IsString ) then
        return CallFuncList( __JuliaFunctionByModule, arglist );
    fi;
    Error( "arguments must be strings function_name[,module_name]" );
end );

InstallGlobalFunction( JuliaGetGlobalVariable,
  function( arglist... )
    if Length( arglist ) = 1 and IsString( arglist[ 1 ] ) then
        return __JuliaGetGlobalVariable( arglist[ 1 ] );
    elif Length( arglist ) = 2 and ForAll( arglist, IsString ) then
        return CallFuncList( __JuliaGetGlobalVariableByModule, arglist );
    fi;
    Error( "arguments must be strings function_name[,module_name]" );
end );

InstallMethod( ConvertedFromJulia,
               [ IsJuliaObject ],
    __ConvertedFromJulia );

InstallMethod( ConvertedToJulia,
                [ IsObject ],
  function( obj )
    local result;
    
    result := __ConvertedToJulia( obj );
    if result = fail then
        TryNextMethod();
    fi;
    return result;
end );

InstallMethod( CallFuncList,
               [ IsJuliaFunction, IsList ],

  function( julia_func, argument_list )

    if Length( argument_list ) = 0 then

        return __JuliaCallFunc0Arg( julia_func );

    elif Length( argument_list ) = 1 then

        return __JuliaCallFunc1Arg( julia_func, ConvertedToJulia( argument_list[ 1 ] ) );

    elif Length( argument_list ) = 2 then

        return __JuliaCallFunc2Arg( julia_func, ConvertedToJulia( argument_list[ 1 ] ), ConvertedToJulia( argument_list[ 2 ] ) );

    elif Length( argument_list ) = 3 then

        return __JuliaCallFunc3Arg( julia_func, ConvertedToJulia( argument_list[ 1 ] ), ConvertedToJulia( argument_list[ 2 ] ), ConvertedToJulia( argument_list[ 3 ] ) );

    fi;

    return __JuliaCallFuncXArg( julia_func, List( argument_list, ConvertedToJulia ) );

end );


##
##  We want to use &GAP's function call syntax also for certain Julia objects
##  that are <E>not</E> functions, for example for types such as <C>fmpz</C>.
##  Note that also Julia supports this.
##
InstallMethod( CallFuncList,
    [ "IsJuliaObject", "IsList" ],
    function( julia_obj, argument_list )
        local apply;

        # We do not get our hands on Julia's built-in function '_apply'
        # via 'BindJuliaFunc', and we do not find it in 'Julia.Core' ...
        apply:= JuliaFunction( "_apply", "Core" );
        return apply( julia_obj, argument_list );
    end );


BindJuliaFunc( "string", "Base" );

BindJuliaFunc( "include", "Base" );

BindGlobal( "JuliaKnownFiles", [] );

BindGlobal( "JuliaIncludeFile", function( filename )
    if not filename in JuliaKnownFiles then
      Julia.Base.include( filename );
      AddSet( JuliaKnownFiles, filename );
    fi;
end );

InstallMethod( ViewString,
               [ IsJuliaObject ],

  function( julia_obj )

    return Concatenation( "<Julia: ", String( julia_obj ), ">" );

end );

InstallMethod( ViewString,
    [ IsJuliaFunction ],
    julia_func -> Concatenation( "<Julia: ",
                      ConvertedFromJulia( Julia.Base.string( julia_func ) ),
                      ">" ) );

InstallMethod( String,
               [ IsJuliaObject ],

  function( julia_obj )

    return ConvertedFromJulia( Julia.Base.string( julia_obj ) );

end );


InstallGlobalFunction( ImportJuliaModuleIntoGAP,
  function( name )
    local julia_list_func, function_list, variable_list, i, current_module_rec;

    # Do nothing if the module has already been imported.
    if IsBound( Julia.( name ) ) and not IsBound( Julia.( name ).__JULIAINTERFACE_NOT_IMPORTED_YET ) then
      return;
    fi;

    if name = "Main" then
        Print( "WARNING: Do not import Main module into GAP\n" );
    fi;
    JuliaEvalString( Concatenation( "import ", name ) );
    __JULIAINTERFACE_PREPARE_RECORD( name );
    current_module_rec := Julia.(name);
    Unbind( current_module_rec.__JULIAINTERFACE_NOT_IMPORTED_YET );
    julia_list_func := JuliaFunction( "get_function_symbols_in_module", "GAPUtils" );
    function_list := StructuralConvertedFromJulia( julia_list_func( JuliaModule( name ) ) );
    for i in function_list do
        current_module_rec.(i) := JuliaFunction( i, name );
    od;
    julia_list_func := JuliaFunction( "get_variable_symbols_in_module", "GAPUtils" );
    variable_list := StructuralConvertedFromJulia( julia_list_func( JuliaModule( name ) ) );
    for i in variable_list do
        current_module_rec.(i) := JuliaGetGlobalVariable( i, name );
    od;
end );

InstallGlobalFunction( StructuralConvertedFromJulia,
  function( object ) 
    local unboxed_obj;
    unboxed_obj := ConvertedFromJulia( object );
    if IsList( unboxed_obj ) and not IsString( unboxed_obj ) then
        return List( unboxed_obj, StructuralConvertedFromJulia );
    fi;
    return unboxed_obj;
end );

