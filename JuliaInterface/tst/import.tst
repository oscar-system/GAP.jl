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
#I  The Julia module 'No_Julia_Module_With_This_Name' cannot be imported.

##
gap> STOP_TEST( "import.tst", 1 );

