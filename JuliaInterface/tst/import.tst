##
gap> START_TEST( "import.tst" );

##
gap> JuliaImportPackage( "Core" );
true
gap> JuliaImportPackage( "No_Julia_Package_With_This_Name" );
#I  The Julia package 'No_Julia_Package_With_This_Name' cannot be loaded.
false

##
gap> ImportJuliaModuleIntoGAP( "Core" );
gap> ImportJuliaModuleIntoGAP( "No_Julia_Module_With_This_Name" );
Error, JuliaError

##
gap> Julia;
<Julia module Main>
gap> Julia.Base;
<Julia module Base>
gap> IsBound( Julia.Base );
true
gap> Julia.Base.sqrt;
function( arg... ) ... end
gap> IsBound( Julia.Base.C_NULL );
true
gap> Julia.Base.C_NULL;
<Julia: Ptr{Nothing} @0x0000000000000000>
gap> IsBound( Julia.Base.C_NULL );
true
gap> Unbind( Julia.Base.C_NULL );
gap> IsBound( Julia.Base.C_NULL );
true

##
gap> STOP_TEST( "import.tst", 1 );
