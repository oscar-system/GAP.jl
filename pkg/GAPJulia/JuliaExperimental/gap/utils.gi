


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "utils.jl" ) );


#############################################################################
##
##  Declare filters.
##


##############################################################################
##
#F  JuliaMatrixFromGapMatrix( <gapmatrix> )
##
##  <gapmatrix> must be a matrix of small integers.
##
BindGlobal( "JuliaMatrixFromGapMatrix", function( gapmatrix )
    local juliamatrix;

    juliamatrix:= GAPToJulia( gapmatrix );  # nested array
    return Julia.GAPUtilsExperimental.MatrixFromNestedArray( juliamatrix );
    end );


#############################################################################
##
#E

