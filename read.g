#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

ReadPackage( "JuliaInterface", "gap/BindCFunction.gi" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "julia" );

ReadPackage( "JuliaInterface", "gap/convertcyc.g");
JuliaIncludeFile( Filename( dirs, "convertcyc.jl" ) );
BindJuliaFunc( "juliabox_cycs" );

ReadPackage( "JuliaInterface", "gap/shortestvectors.g");
JuliaIncludeFile( Filename( dirs, "shortestvectors.jl" ) );
BindJuliaFunc( "shortestvectors" );
