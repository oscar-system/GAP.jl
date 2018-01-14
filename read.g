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
# 
# JuliaIncludeFile( Filename( dirs, "gapperm.jl" ) );
# for funcname in [ "Permutation", "IdentityPerm", "EqPerm22", "LtPerm22", "ProdPerm22", "PowPerm2Int", "PowIntPerm2", "QuoIntPerm2", "LargestMovedPointPerm", "OrderPerm", "OnePerm", "InvPerm" ] do
#   BindJuliaFunc( funcname );
# od;

