#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");
ReadPackage( "JuliaInterface", "gap/BindCFunction.gi" );
ReadPackage( "JuliaInterface", "gap/generated_path.gi" );

dirs_gap_jl := Directory( _JULIAINTERFACE_JULIA_MODULE_SOURCES );

if not IsBound( JULIAINTERNAL_LOADED_FROM_JULIA ) then
    JuliaEvalString( "__IS_LOADED_FROM_GAP = true" );
    JuliaEvalString( Concatenation( "Base.MainInclude.include( \"", Filename( dirs_gap_jl, "GAP.jl" ), "\")" ) );
fi;

dirs_julia := DirectoriesPackageLibrary( "JuliaInterface", "julia" );

JuliaIncludeFile( Filename( dirs_julia, "gaptypes.jl" ) );

JuliaEvalString( Concatenation( "__JULIAGAPMODULE.include( \"", Filename( dirs_julia, "libgap.jl" ), "\")" ) );

_JULIAINTERFACE_INTERNAL_INIT();

Julia!.storage.GAP := _WrapJuliaModule( "GAP", _JuliaGetGlobalVariable( "__JULIAGAPMODULE" ) );

ReadPackage( "JuliaInterface", "gap/adapter.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");
