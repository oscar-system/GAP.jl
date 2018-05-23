#
# JuliaInterface: Test interface to julia
#
# Declarations
#

DeclareGlobalFunction( "JuliaFunction" );
DeclareGlobalFunction( "JuliaGetGlobalVariable" );

DeclareOperation( "JuliaBox", [ IsObject ] );
DeclareOperation( "JuliaUnbox", [ IsJuliaObject ] );

BindGlobal( "__JULIAINTERFACE_MODULE_NAME",
  function( module_name )
    if Length( module_name ) = 0 then
        return "Main";
    else
        return module_name[ 1 ];
    fi;
end );

BindGlobal( "__JULIAINTERFACE_PREPARE_RECORD",
  function( module_name )

    if module_name = "Main" and IsBound( Julia.Main ) then
        return module_name;
    fi;
    
    if IsBound( Julia.(module_name) ) and ( not IsBound( Julia.(module_name).__JULIAINTERFACE_NOT_IMPORTED_YET ) ) then
        return fail;
    fi;

    if not IsBound( Julia.(module_name) ) then
        JuliaEvalString( Concatenation( "import ", module_name ) );
        Julia.(module_name) := rec( __JULIAINTERFACE_NOT_IMPORTED_YET := true );
    fi;

    return module_name;

end );

DeclareGlobalFunction( "BindJuliaFunc" );
InstallGlobalFunction( BindJuliaFunc,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    if IsBound( Julia.(module_name) ) and IsBound( Julia.(module_name).(julia_name) ) then
        return;
    fi;
    module_name := __JULIAINTERFACE_PREPARE_RECORD( module_name );
    if module_name = fail then
        return;
    fi;
    Julia.(module_name).(julia_name) := JuliaFunction( julia_name, module_name );
end );

DeclareGlobalFunction( "BindJuliaObj" );
InstallGlobalFunction( BindJuliaObj,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    if IsBound( Julia.(module_name) ) and IsBound( Julia.(module_name).(julia_name) ) then
        return;
    fi;
    module_name := __JULIAINTERFACE_PREPARE_RECORD( module_name );
    if module_name = fail then
        return;
    fi;
    Julia.(module_name).(julia_name) := JuliaGetGlobalVariable( julia_name, module_name );
end );

DeclareGlobalFunction( "GetJuliaFunc" );
InstallGlobalFunction( GetJuliaFunc,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    BindJuliaFunc( julia_name, module_name );
    return Julia.(module_name).(julia_name);
end );

DeclareGlobalFunction( "GetJuliaObj" );
InstallGlobalFunction( GetJuliaObj,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    BindJuliaObj( julia_name, module_name );
    return Julia.(module_name).(julia_name);
end );

DeclareGlobalFunction( "ImportJuliaModuleIntoGAP" );

DeclareGlobalFunction( "JuliaStructuralUnbox" );
