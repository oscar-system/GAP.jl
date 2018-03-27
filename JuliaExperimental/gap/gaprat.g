##############################################################################
##
##  gaprat.g
##
##  This is experimental code for wrapping GAP's integers and rationals
##  into Julia objects.
##  The Julia objects are implemented in 'julia/gaprat.jl'.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile( 
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ), 
    "gaprat.jl" ) );

ImportJuliaModuleIntoGAP( "GAPRatModule" );


##############################################################################
##
#E

