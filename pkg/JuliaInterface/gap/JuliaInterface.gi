#
# JuliaInterface: Test interface to julia
#
# Implementations
#

BindGlobal( "_JULIA_MODULE_TYPE", _JuliaGetGlobalVariableByModule( "Module", "Core" ) );
BindGlobal( "_JULIA_FUNCTION_TYPE", _JuliaGetGlobalVariableByModule( "Function", "Core" ) );
BindGlobal( "_JULIA_ISA", _WrapJuliaFunction( _JuliaGetGlobalVariableByModule( "isa", "Core" ) ) );

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
    local rnam, var;

    if IsBound\.( module!.storage, rnum ) then
        return \.(module!.storage, rnum );
    fi;

    rnam := NameRNam( rnum );

    var := _JuliaGetGlobalVariableByModule( rnam, JuliaPointer( module ) );
    if var = fail then
        Error( rnam, " is not bound in Julia" );
    fi;

    if _JULIA_ISA( var, _JULIA_FUNCTION_TYPE ) then
        var := _WrapJuliaFunction( var );
    elif _JULIA_ISA( var, _JULIA_MODULE_TYPE ) then
        var := _WrapJuliaModule( rnam, var );
    fi;

    return var;
end );

InstallMethod( \.\:\=,
               [ "IsJuliaModule", "IsPosInt", "IsObject" ],
  function( module, rnum, obj )
    Julia.GAP._setglobal( module, JuliaSymbol( NameRNam( rnum ) ), obj );
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

InstallValue( Julia, _WrapJuliaModule( "Main", _JuliaGetGlobalVariableByModule( "Main", "Main" ) ) );

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


InstallGlobalFunction( GetJuliaScratchspace,
  function( key )
    if not IsString( key ) then
        Error( "GetJuliaScratchspace: <key> must be a string" );
    fi;
    key:= Julia.Base.string( key );
    return JuliaToGAP( IsString,
             Julia.GAP.get_scratch_helper\!( key ) );
end );
