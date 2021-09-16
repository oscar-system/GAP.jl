#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

## Ensure that the Julia module GAP is always accessible as Julia.GAP,
## even while it is still being initialized, and also if it not actually
## exported to the Julia Main module
Julia!.storage.GAP := _WrapJuliaModule( "GAP", _JuliaGetGapModule() );

ReadPackage( "JuliaInterface", "gap/adapter.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");
ReadPackage( "JuliaInterface", "gap/helpstring.g");
ReadPackage( "JuliaInterface", "gap/juliahelp.g");
