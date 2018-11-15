#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");
ReadPackage( "JuliaInterface", "gap/BindCFunction.gi" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "julia" );

JuliaIncludeFile( Filename( dirs, "gaptypes.jl" ) );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "../LibGAP.jl/src" );

if not IsBound( JULIAINTERNAL_LOADED_FROM_JULIA ) then
    Julia.Base.include( Julia.Main!.julia_pointer, ConvertedToJulia( Filename( dirs, "initialization.jl" ) ) );
fi;

Julia.Base.include( Julia.Main.GAP!.julia_pointer, ConvertedToJulia( Filename( dirs, "libgap.jl" ) ) );

_JULIAINTERFACE_INTERNAL_INIT();

ImportJuliaModuleIntoGAP( "GAP" );

ReadPackage( "JuliaInterface", "gap/arith.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");
