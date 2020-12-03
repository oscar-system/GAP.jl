#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

_JULIAINTERFACE_INTERNAL_INIT();

## The GAP module is also bound to the variable __JULIAGAPMODULE,
## to prevent name clashes when accessing it before it is completely initialized.
Julia!.storage.GAP := _WrapJuliaModule( "GAP", _JuliaGetGlobalVariable( "__JULIAGAPMODULE" ) );

ReadPackage( "JuliaInterface", "gap/adapter.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");
ReadPackage( "JuliaInterface", "gap/helpstring.g");
ReadPackage( "JuliaInterface", "gap/juliahelp.g");
