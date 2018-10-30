#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

ReadPackage( "JuliaInterface", "gap/BindCFunction.gi" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "julia" );

JuliaIncludeFile( Filename( dirs, "gaptypes.jl" ) );

ImportJuliaModuleIntoGAP( "GAP" );

if not IsBound( JULIAINTERNAL_LOADED_FROM_JULIA ) then
    dirs:= DirectoriesPackageLibrary( "JuliaInterface", "../LibGAP.jl/src" );
    JuliaIncludeFile( Filename( dirs, "libgap.jl" ) );
fi;
