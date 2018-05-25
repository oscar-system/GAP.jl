#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# Read the implementation part of the package.
#

# ...
ReadPackage( "JuliaExperimental", "gap/utils.gi");
ReadPackage( "JuliaExperimental", "gap/arith.gi");


# ReadPackage( "JuliaExperimental", "gap/convertcyc.g");
# JuliaIncludeFile( Filename( dirs, "convertcyc.jl" ) );
# BindJuliaFunc( "juliabox_cycs" );
# 


# Translate GAP records to Julia dictionaries and vice versa.
ReadPackage( "JuliaExperimental", "gap/record.g");


# shortest vectors, LLL, orthogonal embeddings
ReadPackage( "JuliaExperimental", "gap/zlattice.g");


# Use Julia to compute the HNF of an integer matrix.
if JuliaUsingPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/hnf.g");
fi;


# GAP integers and rationals in Julia.
ReadPackage( "JuliaExperimental", "gap/gaprat.g");


# Julia permutations
ReadPackage( "JuliaExperimental", "gap/gapperm.g");


# Nemo's number fields.
if JuliaUsingPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/numfield.g");
fi;


# Arb
if JuliaUsingPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/realcyc.g");
fi;


# Singular
if JuliaUsingPackage( "Singular" ) then
  ReadPackage( "JuliaExperimental", "gap/singular.g");
fi;


