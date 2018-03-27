#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaExperimental", "gap/JuliaExperimental.gi");

# ReadPackage( "JuliaExperimental", "gap/convertcyc.g");
# JuliaIncludeFile( Filename( dirs, "convertcyc.jl" ) );
# BindJuliaFunc( "juliabox_cycs" );
# 
# ReadPackage( "JuliaExperimental", "gap/shortestvectors.g");
# JuliaIncludeFile( Filename( dirs, "shortestvectors.jl" ) );
# BindJuliaFunc( "shortestvectors" );



# Use Julia to compute the HNF of an integer matrix.
ReadPackage( "JuliaExperimental", "gap/hnf.g");


# GAP integers and rationals in Julia.
ReadPackage( "JuliaExperimental", "gap/gaprat.g");


# Julia permutations
ReadPackage( "JuliaExperimental", "gap/gapperm.g");


# Nemo's number fields.
ReadPackage( "JuliaExperimental", "gap/numfield.g");
