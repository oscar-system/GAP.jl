#
# JuliaInterface: Test interface to julia
#
# Declarations
#

#! @Description
#!   Insert documentation for you function here
DeclareGlobalFunction( "JuliaInterface_Example" );


DeclareCategory( "IsJuliaFunction", IsObject );
DeclareCategory( "IsJuliaObject", IsObject );

JuliaFunctionFamily := NewFamily( "JuliaFunctionFamily" );
JuliaObjectFamily := NewFamily( "JuliaObjectFamily" );

BindGlobal("TheTypeJuliaFunction", NewType( JuliaFunctionFamily, IsJuliaFunction ));
BindGlobal("TheTypeJuliaObject", NewType( JuliaObjectFamily, IsJuliaObject ));
