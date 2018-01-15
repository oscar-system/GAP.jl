LoadPackage( "JuliaInterface" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "example" );

JuliaIncludeFile( Filename( dirs, "gap_function_call.jl" ) );

JuliaBindCFunction( "IsPrimeInt", "IsPrime_jl", 1, "n" );

IsPrime_jl( 10 );
