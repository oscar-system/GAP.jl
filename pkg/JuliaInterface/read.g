#############################################################################
##
##  JuliaInterface package
##
##  Reading the implementation part of the package.
##
#############################################################################

ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

ReadPackage( "JuliaInterface", "gap/adapter.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");
ReadPackage( "JuliaInterface", "gap/helpstring.g");
ReadPackage( "JuliaInterface", "gap/juliahelp.g");

ReadPackage( "JuliaInterface", "gap/override.g");

# setup JLL overrides
GAP_jl.setup_overrides();
