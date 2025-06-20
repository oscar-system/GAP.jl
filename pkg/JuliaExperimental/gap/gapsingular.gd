#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##
##  This is an experimental interface to Singular's objects.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "singular.jl" ) );

JuliaImportPackage( "Nemo" );
JuliaImportPackage( "Singular" );


#############################################################################
##
##  Declare filters for the wrapped Julia objects.
##
DeclareCategory( "IsSingularObject", IsObject );

DeclareCategoryCollections( "IsSingularObject" );
DeclareCategoryCollections( "IsSingularObjectCollection" );
DeclareCategoryCollections( "IsSingularObjectCollColl" );

DeclareSynonym( "IsSingularFieldElement", IsSingularObject and IsScalar );
DeclareSynonym( "IsSingularMatrixObj", IsSingularObject and IsMatrixObj );
DeclareSynonym( "IsSingularVectorObj", IsSingularObject and IsVectorObj );

DeclareSynonym( "IsSingularRingElement", IsSingularObject and IsRingElement );
DeclareSynonym( "IsSingularPolynomial", IsSingularObject and IsPolynomial );
DeclareSynonym( "IsSingularPolynomialRing",
    IsSingularObject and IsPolynomialRing );
DeclareSynonym( "IsSingularField", IsSingularObject and IsField );


##############################################################################
##
#O  GAPToSingular( <context>, <obj> )
#O  GAPToSingular( <domain>, <obj> )
##
##  Compute a wrapped Singular object that corresponds to
##  the given &GAP; object <A>obj</A>,
##  w.r.t. the context <A>context</A>.
##
DeclareOperation( "GAPToSingular", [ IsContextObj, IsObject ] );
DeclareOperation( "GAPToSingular", [ IsDomain, IsObject ] );


##############################################################################
##
#O  SingularToGAP( <context>, <obj> )
##
##  Compute a &GAP; object that corresponds to
##  the given wrapped Singular object <A>obj</A>,
##  w.r.t. the context <A>context</A>.
##
DeclareOperation( "SingularToGAP", [ IsContextObj, IsObject ] );

