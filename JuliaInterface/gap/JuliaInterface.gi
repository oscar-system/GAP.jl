#
# JuliaInterface: Test interface to julia
#
# Implementations
#

InstallGlobalFunction( JuliaFunction,
  function( arglist... )
    if Length( arglist ) = 1 and IsString( arglist[ 1 ] ) then
        return _JuliaFunction( arglist[ 1 ], true );
    elif Length( arglist ) = 2 and ForAll( arglist, IsString ) then
        return _JuliaFunctionByModule( arglist[1], arglist[2], true );
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

InstallMethod( ConvertedFromJulia,
               [ IsObject ],
    IdFunc );

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


BindGlobal( "_JULIA_MODULE_TYPE", JuliaEvalString( "Module" ) );
BindGlobal( "_JULIA_FUNCTION_TYPE", JuliaEvalString( "Function" ) );
BindGlobal( "_JULIA_ISA", JuliaFunction( "isa" ) );

BindGlobal( "_WrapJuliaModule",
  function( name, julia_pointer )
    local module;

    module := rec( storage := rec( ),
                   julia_pointer := julia_pointer );

    ObjectifyWithAttributes( module, TheTypeOfJuliaModules,
                             Name, Concatenation( "<Julia module ", name, ">" ) );

    return module;

end );

InstallMethod( \.,
              [ IsJuliaModule, IsPosInt ],
  function( module, rnum )
    local rnam, global_variable;

    if IsBound\.( module!.storage, rnum ) then
        return \.(module!.storage, rnum );
    fi;

    rnam := NameRNam( rnum );

    global_variable := _JuliaGetGlobalVariableByModule( rnam, module!.julia_pointer );
    if global_variable = fail then
        Error( rnam, " is not bound in Julia" );
    fi;

    if _JULIA_ISA( global_variable, _JULIA_FUNCTION_TYPE ) then
        global_variable := _JuliaFunction( global_variable, true );
    elif _JULIA_ISA( global_variable, _JULIA_MODULE_TYPE ) then
        global_variable := _WrapJuliaModule( rnam, global_variable );
    fi;

    \.\:\=( module!.storage, rnum, global_variable );
    return global_variable;

end );

InstallMethod( \.\:\=,
               [ IsJuliaModule, IsPosInt, IsObject ],
  function( module, rnum, obj )
    Error( "Manual assignment to module is not allowed" );
end );


InstallMethod( IsBound\.,
               [ IsJuliaModule, IsPosInt ],
  function( module, rnum )
    if IsBound\.( module!.storage, rnum ) then
        return true;
    fi;
    return fail <> _JuliaGetGlobalVariableByModule( NameRNam( rnum ), module!.julia_pointer );
end );


InstallMethod( Unbind\.,
               [ IsJuliaModule, IsPosInt ],
  function( module, rnum )
    Unbind\.( module!.storage, rnum );
end );


InstallGlobalFunction( JuliaSymbolsInModule,
                       [ IsJuliaModule ],
  module -> RecNames( module!.storage ) );

InstallValue( Julia, _WrapJuliaModule( "Main", JuliaEvalString( "Main" ) ) );


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

BindGlobal( "JuliaKnownFiles", [] );

InstallGlobalFunction( "JuliaIncludeFile",
function( filename )
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
    local callstring, julia_list_func, list, variable_list, i,
          current_module, is_module_present, no_import;

    no_import := ValueOption( "NoImport" );
    if no_import = fail then
        no_import := false;
    fi;

    if name = "Main" then
        Print( "WARNING: Do not import Main module into GAP\n" );
    fi;
    is_module_present := JuliaEvalString( Concatenation( "isdefined( Main, :", name, ")" ) );
    
    if no_import = false then
        if not is_module_present then
            ## Local modules cannot be imported
            callstring:= Concatenation( "import ", name );
            JuliaEvalString( callstring );
        fi;
    fi;

    current_module := Julia.(name);
    julia_list_func := JuliaFunction( "get_symbols_in_module", "GAPUtils" );
    list := StructuralConvertedFromJulia( julia_list_func( current_module!.julia_pointer ) );
    for i in list do
        \.( current_module, RNamObj( i ) );
    od;
end );


InstallGlobalFunction( JuliaImportPackage, function( pkgname )
    local callstring;
    if not IsString( pkgname ) then
        Error( "<pkgname> must be a string, the name of a Julia package" );
    fi;
    callstring := Concatenation( "try import ", pkgname,
                     "; return true; catch e; return e; end" );
    if JuliaEvalString( callstring ) = true then
        return true;
    else
      Info( InfoWarning, 1,
            "The Julia package '", pkgname, "' cannot be loaded." );
      return false;
    fi;
end );


InstallGlobalFunction( JuliaTypeInfo,
    juliaobj -> ConvertedFromJulia(
                    Julia.Base.string( Julia.Core.typeof( juliaobj ) ) ) );


InstallGlobalFunction( CallJuliaFunctionWithCatch,
    function( juliafunc, arguments )
    local res;

    res:= Julia.GAPUtils.call_with_catch( juliafunc, arguments );
    if res[1] then
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

InstallGlobalFunction( JuliaModule,
  function( name )
    if not IsString( name ) then
        Error( "JuliaModule: <name> must be a string" );
    fi;
    if not IsBound( Julia.(name) ) then
        Error( "JuliaModule: Module <name> does not exists, did you import it?" );
    fi;
    if not IsJuliaModule( Julia.(name) ) then
        Error( "JuliaModule: <name> is not a module" );
    fi;
    return Julia.(name)!.julia_pointer;
end );

