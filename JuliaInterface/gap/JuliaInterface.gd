#
# JuliaInterface: Test interface to julia
#
# Declarations
#

BindGlobal( "__JuliaFunctions", rec( ) );

DeclareGlobalFunction( "JuliaFunction" );
DeclareGlobalFunction( "JuliaGetGlobalVariable" );

DeclareOperation( "JuliaBox", [ IsObject ] );
DeclareOperation( "JuliaUnbox", [ IsJuliaObject ] );

DeclareGlobalFunction( "BindJuliaFunc" );
InstallGlobalFunction( BindJuliaFunc,
  function( julia_name )
    if not IsBound( __JuliaFunctions.(julia_name) ) then
        __JuliaFunctions.(julia_name) := JuliaFunction( julia_name );
    fi;
end );

DeclareGlobalFunction( "GetJuliaFunc" );
InstallGlobalFunction( GetJuliaFunc,
  function( julia_name )
    if not IsBound( __JuliaFunctions.(julia_name) ) then
        __JuliaFunctions.(julia_name) := JuliaFunction( julia_name );
    fi;
    return __JuliaFunctions.(julia_name);
end );

DeclareGlobalFunction( "ImportJuliaModuleIntoGAP" );

DeclareGlobalFunction( "JuliaStructuralUnbox" );
