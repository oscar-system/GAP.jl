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
DeclareCategory( "IsJuliaArray", IsObject );

JuliaFunctionFamily := NewFamily( "JuliaFunctionFamily" );
JuliaObjectFamily := NewFamily( "JuliaObjectFamily" );
JuliaArrayFamily := NewFamily( "JuliaArrayFamily" );

BindGlobal("TheTypeJuliaFunction", NewType( JuliaFunctionFamily, IsJuliaFunction ));
BindGlobal("TheTypeJuliaObject", NewType( JuliaObjectFamily, IsJuliaObject ));
BindGlobal("TheTypeJuliaArray", NewType( JuliaArrayFamily, IsJuliaArray ));
