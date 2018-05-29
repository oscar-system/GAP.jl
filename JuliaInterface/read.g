#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

ReadPackage( "JuliaInterface", "gap/BindCFunction.gi" );

dirs:= DirectoriesPackageLibrary( "JuliaInterface", "julia" );

JuliaIncludeFile( Filename( dirs, "gaptypes.jl" ) );

AddGapJuliaFuncs();


# Add the julia version number to the banner string.
PackageInfo( "JuliaInterface" )[1].BannerString:= ReplacedString(
    PackageInfo( "JuliaInterface" )[1].BannerString,
    "Homepage", Concatenation( "(julia version is ",
                    ConvertedFromJulia( JuliaEvalString( "string( VERSION )" ) ), 
                    ")\nHomepage" ) );

