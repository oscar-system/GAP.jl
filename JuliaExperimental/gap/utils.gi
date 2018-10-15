


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


#############################################################################
##
DeclareAttribute( "JuliaPointer", IsObject );


##############################################################################
##
#! @Arguments obj
#! @Returns a &Julia; object
#! @Description
#!  For an object <A>obj</A> with attribute <Ref Attr="JuliaPointer"/>,
#!  this function returns the value of this attribute.
InstallMethod( ConvertedToJulia,
    [ "HasJuliaPointer" ],
    obj -> JuliaPointer( obj ) );


##############################################################################
##
#F  JuliaMatrixFromGapMatrix( <gapmatrix> )
##
##  <gapmatrix> must be a matrix of small integers.
##
BindGlobal( "JuliaMatrixFromGapMatrix", function( gapmatrix )
    local juliamatrix;

    juliamatrix:= ConvertedToJulia( gapmatrix );  # nested array
    return Julia.GAPUtilsExperimental.MatrixFromNestedArray( juliamatrix );
    end );


#############################################################################
##
#E

