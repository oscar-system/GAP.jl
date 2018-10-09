#
# JuliaInterface: Test interface to julia
#
# Implementations
#

InstallGlobalFunction( JuliaFunction,
  function( arglist... )
    if Length( arglist ) = 1 and IsString( arglist[ 1 ] ) then
        return _JuliaFunction( arglist[ 1 ] );
    elif Length( arglist ) = 2 and ForAll( arglist, IsString ) then
        return CallFuncList( _JuliaFunctionByModule, arglist );
    fi;
    Error( "arguments must be strings function_name[,module_name]" );
end );

InstallGlobalFunction( JuliaGetGlobalVariable,
  function( arglist... )
    if Length( arglist ) = 1 and IsString( arglist[ 1 ] ) then
        return _JuliaGetGlobalVariable( arglist[ 1 ] );
    elif Length( arglist ) = 2 and ForAll( arglist, IsString ) then
        return CallFuncList( _JuliaGetGlobalVariableByModule, arglist );
    fi;
    Error( "arguments must be strings function_name[,module_name]" );
end );

InstallMethod( ConvertedFromJulia,
               [ IsJuliaObject ],
    _ConvertedFromJulia );

InstallMethod( ConvertedToJulia,
                [ IsObject ],
  function( obj )
    local result;
    
    result := _ConvertedToJulia( obj );
    if result = fail then
        TryNextMethod();
    fi;
    return result;
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


##
##  We support '<juliaobj>[<i>]' and '<juliaobj>[<i>, <j>]' in general.
##  This is useful for example if <juliaobj> is a tuple.
##
BindJuliaFunc( "getindex", "Base" );

InstallOtherMethod( \[\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.getindex( obj, i );
    end );

InstallOtherMethod( \[\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep" ],
    function( obj, i, j )
      return Julia.Base.getindex( obj, i, j );
    end );

BindJuliaFunc( "string", "Base" );
BindJuliaFunc( "repr", "Base" );

BindGlobal( "JuliaKnownFiles", [] );

BindGlobal( "JuliaIncludeFile", function( filename )
    if not filename in JuliaKnownFiles then
      JuliaEvalString( Concatenation( "Base.include(@__MODULE__,\"", filename, "\")" ) );
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
                      ConvertedFromJulia( Julia.Base.repr( julia_func ) ),
                      ">" ) );

InstallMethod( String,
               [ IsJuliaObject ],

  function( julia_obj )
    return ConvertedFromJulia( Julia.Base.repr( julia_obj ) );

end );


InstallGlobalFunction( ImportJuliaModuleIntoGAP,
  function( name )
    local callstring, julia_list_func, function_list, variable_list, i,
          current_module_rec, is_module_present;

    # Do nothing if the module has already been imported.
    if IsBound( Julia.( name ) ) and not IsBound( Julia.( name )._JULIAINTERFACE_NOT_IMPORTED_YET ) then
      return;
    fi;

    if name = "Main" then
        Print( "WARNING: Do not import Main module into GAP\n" );
    fi;
    is_module_present := JuliaEvalString( Concatenation( "isdefined( Main, :", name, ")" ) );
    if not ConvertedFromJulia( is_module_present ) then
        ## Local modules cannot be imported
        callstring:= Concatenation( "try import ", name,
                        "; return true; catch e; return e; end" );
        if ConvertedFromJulia( JuliaEvalString( callstring ) ) <> true then
        Info( InfoWarning, 1,
                "The Julia module '", name, "' cannot be imported." );
        return;
        fi;
    fi;

    _JULIAINTERFACE_PREPARE_RECORD( name );
    current_module_rec := Julia.(name);
    Unbind( current_module_rec._JULIAINTERFACE_NOT_IMPORTED_YET );
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


InstallGlobalFunction( JuliaImportPackage, function( pkgname )
    local callstring;
    if not IsString( pkgname ) then
        Error( "<pkgname> must be a string, the name of a Julia package" );
    fi;
    callstring := Concatenation( "try import ", pkgname,
                     "; return true; catch e; return e; end" );
    if ConvertedFromJulia( JuliaEvalString( callstring ) ) = true then
        return true;
    else
      Info( InfoWarning, 1,
            "The Julia package '", pkgname, "' cannot be loaded." );
      return false;
    fi;
end );


BindJuliaFunc( "typeof", "Core" );

InstallGlobalFunction( JuliaTypeInfo,
    juliaobj -> ConvertedFromJulia(
                    Julia.Base.string( Julia.Core.typeof( juliaobj ) ) ) );


InstallGlobalFunction( CallJuliaFunctionWithCatch,
    function( juliafunc, arguments )
    local res;

    res:= Julia.GAPUtils.call_with_catch( juliafunc, arguments );
    if ConvertedFromJulia( res[1] ) = true then
      return rec( ok:= true, value:= res[2] );
    else
      return rec( ok:= false, value:= ConvertedFromJulia( res[2] ) );
    fi;
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

