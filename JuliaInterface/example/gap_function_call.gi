LoadPackage( "JuliaInterface" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "example" );

JuliaIncludeFile( Filename( dirs, "gap_function_call.jl" ) );

IsPrime_jl := JuliaBindCFunction( "IsPrimeInt", "IsPrime_jl", 1, [ "n" ] );

IsPrime_jl( 10 );

Power2 := JuliaBindCFunction( "Power2", "Power2", 1, ["n"] );

Power2( 10 );