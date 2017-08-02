#
# JuliaInterface: Test interface to julia
#
# Declarations
#

BindGlobal( "__JuliaFunctions", rec( ) );

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
    return __JuliaFunctions.(julia_name);
end );


DeclareCategory( "IsJuliaFunction", IsObject );
DeclareCategory( "IsJuliaObject", IsObject );

JuliaFunctionFamily := NewFamily( "JuliaFunctionFamily" );
JuliaObjectFamily := NewFamily( "JuliaObjectFamily" );

BindGlobal("TheTypeJuliaFunction", NewType( JuliaFunctionFamily, IsJuliaFunction ));
BindGlobal("TheTypeJuliaObject", NewType( JuliaObjectFamily, IsJuliaObject ));
