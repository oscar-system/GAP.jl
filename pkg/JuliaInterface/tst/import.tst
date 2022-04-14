##
gap> START_TEST( "import.tst" );

##
gap> JuliaImportPackage(fail);
Error, <pkgname> must be a string, the name of a Julia package

##
gap> JuliaImportPackage( "Core" );
true
gap> JuliaImportPackage( "No_Julia_Package_With_This_Name" );
#I  The Julia package 'No_Julia_Package_With_This_Name' cannot be loaded.
false

##
gap> Julia;
<Julia module Main>
gap> Julia.Base;
<Julia module Base>

#
gap> IsBound( Julia.Base );
true
gap> Julia.Base.sqrt;
<Julia: sqrt>
gap> IsBound( Julia.Base.foo_bar_quux_not_defined );
false
gap> Julia.Base.foo_bar_quux_not_defined;
Error, foo_bar_quux_not_defined is not bound in Julia
gap> Julia.Base.foo_bar_quux_not_defined := 1;
1
gap> Julia.Base.foo_bar_quux_not_defined;
1

#
gap> IsBound( Julia.Base.C_NULL );
true
gap> Julia.Base.C_NULL;
<Julia: Ptr{Nothing} @0x0000000000000000>
gap> IsBound( Julia.Base.C_NULL );
true
gap> Unbind( Julia.Base.C_NULL );
Error, cannot unbind Julia variables

##
gap> STOP_TEST( "import.tst", 1 );
