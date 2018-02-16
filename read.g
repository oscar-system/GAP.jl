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




# ReadPackage( "JuliaInterface", "gap/convertcyc.g");
# JuliaIncludeFile( Filename( dirs, "convertcyc.jl" ) );
# BindJuliaFunc( "juliabox_cycs" );
# 
# ReadPackage( "JuliaInterface", "gap/shortestvectors.g");
# JuliaIncludeFile( Filename( dirs, "shortestvectors.jl" ) );
# BindJuliaFunc( "shortestvectors" );



# Use Julia to compute the HNF of an integer matrix.
ReadPackage( "JuliaInterface", "gap/hnf.g");


# GAP integers and rationals in Julia.
ReadPackage( "JuliaInterface", "gap/gaprat.g");


# Julia permutations
ReadPackage( "JuliaInterface", "gap/gapperm.g");


# Nemo's number fields.
ReadPackage( "JuliaInterface", "gap/numfield.g");


# Add the julia version number to the banner string.
PackageInfo( "JuliaInterface" )[1].BannerString:= ReplacedString(
    PackageInfo( "JuliaInterface" )[1].BannerString,
    "Homepage", Concatenation( "(julia version is ",
                    JuliaUnbox( JuliaEvalString( "string( VERSION )" ) ), 
                    ")\nHomepage" ) );

