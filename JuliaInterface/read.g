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
    JuliaEvalString( Concatenation( "Base.include( Main,\"", Filename( dirs, "initialization.jl" ), "\")" ) );
fi;

JuliaEvalString( Concatenation( "Base.include( Main.GAP,\"", Filename( dirs, "libgap.jl" ), "\")" ) );

_JULIAINTERFACE_INTERNAL_INIT();

ReadPackage( "JuliaInterface", "gap/arith.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");

ImportJuliaModuleIntoGAP( "GAP" );
