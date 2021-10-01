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
        return _JuliaFunctionByModule( arglist[1], arglist[2] );
    fi;
    Error( "arguments must be strings function_name[,module_name]" );
end );

BindGlobal( "_JULIA_MODULE_TYPE", _JuliaGetGlobalVariable( "Module" ) );
BindGlobal( "_JULIA_FUNCTION_TYPE", _JuliaGetGlobalVariable( "Function" ) );
BindGlobal( "_JULIA_ISA", JuliaFunction( "isa" ) );

BindGlobal( "_WrapJuliaModule",
  function( name, julia_pointer )
    local str;

    str:= Concatenation( "<Julia module ", name, ">" );

    return ObjectifyWithAttributes( rec( storage := rec( ) ),
                             TheTypeOfJuliaModules,
                             Name, str,
                             String, str,
                             JuliaPointer, julia_pointer );
end );

InstallMethod( ViewString,
    [ "IsFunction and IsInternalRep and HasNameFunction" ],
    1, # override GAP's default method for functions
    function( func )
    if IS_JULIA_FUNC( func ) then
      return Concatenation( "<Julia: ", NameFunction( func ), ">" );
    fi;
    TryNextMethod();
    end );

InstallMethod( \.,
              [ "IsJuliaModule", "IsPosInt" ],
  function( module, rnum )
    local rnam, global_variable;

    if IsBound\.( module!.storage, rnum ) then
        return \.(module!.storage, rnum );
    fi;

    rnam := NameRNam( rnum );

    global_variable := _JuliaGetGlobalVariableByModule( rnam, JuliaPointer( module ) );
    if global_variable = fail then
        Error( rnam, " is not bound in Julia" );
    fi;

    if _JULIA_ISA( global_variable, _JULIA_FUNCTION_TYPE ) then
        global_variable := _JuliaFunction( global_variable );
    elif _JULIA_ISA( global_variable, _JULIA_MODULE_TYPE ) then
        global_variable := _WrapJuliaModule( rnam, global_variable );
        \.\:\=( module!.storage, rnum, global_variable );
    fi;

    return global_variable;
end );

InstallMethod( \.\:\=,
               [ "IsJuliaModule", "IsPosInt", "IsObject" ],
  function( module, rnum, obj )
    Error( "Manual assignment to module is not allowed" );
end );

InstallMethod( IsBound\.,
               [ "IsJuliaModule", "IsPosInt" ],
  function( module, rnum )
    if IsBound\.( module!.storage, rnum ) then
        return true;
    fi;
    return fail <> _JuliaGetGlobalVariableByModule( NameRNam( rnum ), JuliaPointer( module ) );
end );

InstallMethod( Unbind\.,
               [ "IsJuliaModule", "IsPosInt" ],
  function( module, rnum )
    Error( "cannot unbind Julia variables" );
end );

InstallMethod(RecNames, [ "IsJuliaModule" ],
function( obj )
    return JuliaToGAP( IsList, Julia.GAP.get_symbols_in_module( JuliaPointer( obj ) ), true );
end);

InstallValue( Julia, _WrapJuliaModule( "Main", _JuliaGetGlobalVariable( "Main" ) ) );

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

InstallGlobalFunction( "JuliaIncludeFile",
function( filename, module_name... )
    if Length( module_name ) = 0 then
      module_name:= "Main";
    elif Length( module_name ) = 1 and IsString( module_name[1] ) then
      module_name:= module_name[1];
    else
      Error( "usage: JuliaIncludeFile( <filename>[, <module_name>] ) ",
             "where <module_name>, if given, must be a string" );
    fi;
    JuliaEvalString( Concatenation( "Base.include(", module_name,", \"", filename, "\")" ) );
end );

InstallMethod( ViewString,
               [ "IsJuliaObject" ],

  function( julia_obj )
    return Concatenation( "<Julia: ", String( julia_obj ), ">" );

end );

InstallMethod( String,
               [ "IsJuliaObject" ],

  function( julia_obj )
    return JuliaToGAP( IsString, Julia.Base.repr( julia_obj ) );

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
    function( juliaobj )
    if IsFunction( juliaobj ) then
      juliaobj:= Julia.GAP.UnwrapJuliaFunc( juliaobj );
    fi;
    return JuliaToGAP( IsString,
                       Julia.Base.string( Julia.Core.typeof( juliaobj ) ) );
end );


InstallGlobalFunction( JuliaModule,
  function( name )
    if not IsString( name ) then
        Error( "JuliaModule: <name> must be a string" );
    fi;
    if not IsBound( Julia.(name) ) then
        Error( "JuliaModule: Module <name> does not exist, did you import it?" );
    fi;
    if not IsJuliaModule( Julia.(name) ) then
        Error( "JuliaModule: <name> is not a module" );
    fi;
    return JuliaPointer( Julia.(name) );
end );

