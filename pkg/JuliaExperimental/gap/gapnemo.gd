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
##  Declare filters for the wrapped Julia objects.
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
#O  GAPToNemo( <context>, <obj> )
#O  GAPToNemo( <domain>, <obj> )
##
##  Compute a wrapped Nemo object that corresponds to
##  the given &GAP; object <A>obj</A>,
##  w.r.t. the context <A>context</A>.
##
DeclareOperation( "GAPToNemo", [ IsContextObj, IsObject ] );
DeclareOperation( "GAPToNemo", [ IsDomain, IsObject ] );


##############################################################################
##
#O  NemoToGAP( <context>, <obj> )
##
##  Compute a &GAP; object that corresponds to
##  the given wrapped Nemo object <A>obj</A>,
##  w.r.t. the context <A>context</A>.
##
DeclareOperation( "NemoToGAP", [ IsContextObj, IsObject ] );

