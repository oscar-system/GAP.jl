#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");
ReadPackage( "JuliaInterface", "gap/BindCFunction.gi" );

dirs_julia := DirectoriesPackageLibrary( "JuliaInterface", "julia" );

JuliaIncludeFile( Filename( dirs_julia, "gaptypes.jl" ) );

dirs_libgap := DirectoriesPackageLibrary( "JuliaInterface", "../../../src" );

if not IsBound( JULIAINTERNAL_LOADED_FROM_JULIA ) then
    JuliaEvalString( Concatenation( "Base.include( Main,\"", Filename( dirs_libgap, "GAPJulia.jl" ), "\")" ) );
fi;

JuliaEvalString( Concatenation( "Base.include( Main.GAP,\"", Filename( dirs_julia, "libgap.jl" ), "\")" ) );

_JULIAINTERFACE_INTERNAL_INIT();

ReadPackage( "JuliaInterface", "gap/adapter.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");

ImportJuliaModuleIntoGAP( "GAP" );
