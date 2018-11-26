##############################################################################
##
##  gapnemo.gd
##
##  This is an experimental interface to Nemo's objects.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "gapnemo.jl" ) );

JuliaImportPackage( "Nemo" );


#############################################################################
##
##  Declare filters.
##
DeclareCategory( "IsNemoObject", IsObject );

DeclareCategoryCollections( "IsNemoObject" );
DeclareCategoryCollections( "IsNemoObjectCollection" );
DeclareCategoryCollections( "IsNemoObjectCollColl" );

DeclareSynonym( "IsNemoFieldElement", IsNemoObject and IsScalar );
DeclareSynonym( "IsNemoMatrixObj", IsNemoObject and IsMatrixObj );
DeclareSynonym( "IsNemoVectorObj", IsNemoObject and IsVectorObj );

DeclareSynonym( "IsNemoRing", IsNemoObject and IsRing );
DeclareSynonym( "IsNemoRingElement", IsNemoObject and IsRingElement );

DeclareSynonym( "IsNemoPolynomial", IsNemoObject and IsPolynomial );
DeclareSynonym( "IsNemoPolynomialRing", IsNemoObject and IsPolynomialRing );
DeclareSynonym( "IsNemoField", IsNemoObject and IsField );
DeclareSynonym( "IsNemoNumberField", IsNemoField and IsNumberField );


##############################################################################
##
##  implementation of context objects,
##  which are used for generic conversions between GAP and Nemo
##


##############################################################################
##
#C  IsContextObj( <obj> )
##
DeclareCategory( "IsContextObj", IsObject );


##############################################################################
##
#A  ContextGAPNemo( <D> )
##
DeclareAttribute( "ContextGAPNemo", IsDomain );


##############################################################################
##
#F  NewContextGAPNemo( <arec> )
##
##  checks the record <arec> for the availability of the mandatory components,
##  and then turns the record <arec> into an object in the filter
##  <Ref Cat="IsContextObj"/>.
##
DeclareGlobalFunction( "NewContextGAPNemo" );


##############################################################################
##
#O  GAPToNemo( <context>, <obj> )
#O  GAPToNemo( <domain>, <obj> )
##
DeclareOperation( "GAPToNemo", [ IsContextObj, IsObject ] );
DeclareOperation( "GAPToNemo", [ IsDomain, IsObject ] );


##############################################################################
##
#O  NemoToGAP( <context>, <obj> )
##
DeclareOperation( "NemoToGAP", [ IsContextObj, IsObject ] );


##############################################################################
##
#E

