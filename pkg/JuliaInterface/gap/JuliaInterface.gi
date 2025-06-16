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

BindGlobal( "_JuliaCoreModule", _JuliaGetGlobalVariableByModule( "Core", _JuliaGetMainModule() ) );
BindGlobal( "_JULIA_FUNCTION_TYPE", _JuliaGetGlobalVariableByModule( "Function", _JuliaCoreModule ) );
BindGlobal( "_JULIA_ISA", _WrapJuliaFunction( _JuliaGetGlobalVariableByModule( "isa", _JuliaCoreModule ) ) );
BindGlobal( "GAP_jl", _JuliaGetGapModule() );

InstallMethod( ViewString,
    [ "IsFunction and IsInternalRep and HasNameFunction" ],
    1, # override GAP's default method for functions
    function( func )
    if IS_JULIA_FUNC( func ) then
      return Concatenation( "<Julia: ", NameFunction( func ), ">" );
    fi;
    TryNextMethod();
    end );

InstallMethod( ViewString,
    [ "IsJuliaModule" ],
    function( module )
    return Concatenation( "<Julia module ", JuliaToGAP( IsString, Julia.string( module ) ), ">" );
    end );

InstallMethod( Name,
    [ "IsJuliaModule" ],
    function( module )
    return Concatenation( "<Julia module ", JuliaToGAP( IsString, Julia.string( module ) ), ">" );
    end );

InstallMethod( \.,
              [ "IsJuliaModule", "IsPosInt and IsSmallIntRep" ],
  function( module, rnum )
    local rnam, var;

    rnam := NameRNam( rnum );

    ## TODO: remove this special case in a future breaking release.
    ## See https://github.com/oscar-system/GAP.jl/issues/1053 for details.
    if IsIdenticalObj(module, Julia) and rnam = "GAP" then
        ## Ensure that the Julia module GAP is always accessible as GAP_jl,
        ## even while it is still being initialized, and also if it not actually
        ## exported to the Julia Main module
        return GAP_jl;
    fi;

    var := _JuliaGetGlobalVariableByModule( rnam, module );
    if var = fail then
        Error( rnam, " is not bound in Julia" );
    fi;

    if _JULIA_ISA( var, _JULIA_FUNCTION_TYPE ) then
        var := _WrapJuliaFunction( var );
    fi;

    return var;
end );

InstallMethod( \.\:\=,
               [ "IsJuliaModule", "IsPosInt and IsSmallIntRep", "IsObject" ],
  function( module, rnum, obj )
    GAP_jl._setglobal( module, Julia.Symbol( NameRNam( rnum ) ), obj );
end );

InstallMethod( IsBound\.,
               [ "IsJuliaModule", "IsPosInt and IsSmallIntRep" ],
  function( module, rnum )
    local rnam;

    rnam := NameRNam( rnum );
    if IsIdenticalObj(module, Julia) and rnam = "GAP" then
        ## Ensure that the Julia module GAP is always accessible as GAP_jl,
        ## even while it is still being initialized, and also if it not actually
        ## exported to the Julia Main module
        return true;
    fi;

    return fail <> _JuliaGetGlobalVariableByModule( rnam, module );
end );

InstallMethod( Unbind\.,
               [ "IsJuliaModule", "IsPosInt and IsSmallIntRep" ],
  function( module, rnum )
    Error( "cannot unbind Julia variables" );
end );

InstallMethod(RecNames, [ "IsJuliaModule" ],
function( obj )
    return JuliaToGAP( IsList, GAP_jl.get_symbols_in_module( obj ), true );
end);

InstallValue( Julia, _JuliaGetMainModule() );

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
      # HACK: avoid warning "The Julia package 'Downloads' cannot be loaded"
      # with older versions of the GAP PackageManager
      if pkgname = "Downloads" then return false; fi;

      Info( InfoWarning, 1,
            "The Julia package '", pkgname, "' cannot be loaded." );
      return false;
    fi;
end );


InstallGlobalFunction( JuliaType,
  { T, paras } -> GAP_jl.create_type( T, GAP_jl._gap_to_julia( paras, true ) ) );


InstallGlobalFunction( GetJuliaScratchspace,
  function( key )
    if not IsString( key ) then
        Error( "GetJuliaScratchspace: <key> must be a string" );
    fi;
    key:= Julia.Base.string( key );
    return JuliaToGAP( IsString,
             GAP_jl.get_scratch_helper\!( key ) );
end );
