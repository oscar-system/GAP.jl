#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaExperimental", "gap/JuliaExperimental.gi");

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
