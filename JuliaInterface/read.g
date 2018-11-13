#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

ReadPackage( "JuliaInterface", "gap/BindCFunction.gi" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "julia" );

JuliaIncludeFile( Filename( dirs, "gaptypes.jl" ) );

if not IsBound( JULIAINTERNAL_LOADED_FROM_JULIA ) then
    dirs:= DirectoriesPackageLibrary( "JuliaInterface", "../LibGAP.jl/src" );
    Julia.Base.include( Julia.Main!.julia_pointer, Filename( dirs, "initialization.jl" ) );
    Julia.Base.include( Julia.Main.GAP!.julia_pointer, Filename( dirs, "libgap.jl" ) );
fi;

_JULIAINTERFACE_INTERNAL_INIT();

ImportJuliaModuleIntoGAP( "GAP" );

ReadPackage( "JuliaInterface", "gap/arith.gi");
