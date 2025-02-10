#############################################################################
##
##  JuliaInterface package
##
##  Reading the declaration part of the package.
##
#############################################################################

LoadDynamicModule(_path_JuliaInterface_so);
Unbind(_path_JuliaInterface_so);

ReadPackage( "JuliaInterface", "gap/JuliaInterface.gd");

ReadPackage( "JuliaInterface", "gap/convert.gd" );
