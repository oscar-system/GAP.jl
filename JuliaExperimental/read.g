#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# Read the implementation part of the package.
#

# ...
ReadPackage( "JuliaExperimental", "gap/utils.gi");


# ReadPackage( "JuliaExperimental", "gap/convertcyc.g");
# JuliaIncludeFile( Filename( dirs, "convertcyc.jl" ) );
# BindJuliaFunc( "juliabox_cycs" );
# 

# shortest vectors, LLL, orthogonal embeddings
ReadPackage( "JuliaExperimental", "gap/zlattice.g");


# Use Julia to compute the HNF of an integer matrix.
if JuliaImportPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/hnf.g");
fi;

# Combinatorics: Julia speeds up large loops
if JuliaImportPackage( "Primes" ) then
  ReadPackage( "JuliaExperimental", "gap/loewy.gd");
  ReadPackage( "JuliaExperimental", "gap/loewy.gi");
fi;

# Julia permutations
ReadPackage( "JuliaExperimental", "gap/gapperm.g");


# Nemo's number fields.
# 'Nemo' imports (some functions from) 'LinearAlgebra',
# see its 'Nemo.jl', but we have to tell GAP about 'LinearAlgebra',
# in order to use, e. g., 'Julia.LinearAlgebra.tr'.
if JuliaImportPackage( "LinearAlgebra" ) and
   JuliaImportPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/gapnemo.g");
  ReadPackage( "JuliaExperimental", "gap/numfield.g");
fi;


# Arb
if JuliaImportPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/realcyc.g");
fi;


# Singular
if JuliaImportPackage( "Singular" ) then
  ReadPackage( "JuliaExperimental", "gap/singular.g");
fi;


