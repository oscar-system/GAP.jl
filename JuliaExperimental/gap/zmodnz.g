##############################################################################
##
##  zmodnz.g
##
##  This is an experimental interface to Nemo's residue class rings,
##  their elements and matrices of them.
##

#T TODO: if the modulus is large then the data are fmpz!
#T   how to carry back then?

##############################################################################
##
#M  ContextGAPNemo( Integers mod <n> )
##
##  On the Nemo side, we have
##  <C>Julia.Nemo.ResidueRing( Julia.Nemo.ZZ, <M>n</M> )</C>.
##
InstallMethod( ContextGAPNemo,
    [ "IsRing and IsZmodnZObjNonprimeCollection and IsAttributeStoringRep" ],
    function( R )
    local m, juliaRing, efam, collfam, gen, type;

    # Check that we have a ring that fits.
    m:= Size( R );
    if Characteristic( R ) <> m then
      return fail;
    fi;

    # Create the Nemo ring.
    juliaRing:= Julia.Nemo.ResidueRing( Julia.Nemo.ZZ, GAPToJulia( m ) );

    # Create the GAP wrapper.
    # Note that elements from different Nemo residue rings cannot be compared,
    # so we create always a new family.
    efam:= NewFamily( "Nemo_ResiduesFamily", IsObject,
               IsNemoObject and IsScalar and IsZmodnZObjNonprime );
    SetIsUFDFamily( efam, false );
    collfam:= CollectionsFamily( efam );
    efam!.elementType:= NewType( efam,
        IsNemoRingElement and IsAttributeStoringRep );
    efam!.vectorType:= NewType( collfam,
        IsVectorObj and IsNemoObject and IsAttributeStoringRep );
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsNemoRingElement and IsAttributeStoringRep );

    gen:= ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 1 ) );

    SetZero( efam, ObjectifyWithAttributes( rec(),
                            efam!.elementType,
                            JuliaPointer, juliaRing( 0 ) ) );
    SetOne( efam, gen );
    SetCharacteristic( efam, m );
#   efam!.polynomialType:= NewType( RationalFunctionsFamily( efam ),
#       IsPolynomial and IsNemoRingElement and IsAttributeStoringRep );

    type:= IsNemoRing and IsAttributeStoringRep and
           IsFinite and IsCommutative and IsAssociative;

    return NewContextGAPJulia( "Nemo", rec(
      Name:= Concatenation( "<context for Integers mod ", String( m ), ">" ),

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing,
                      GeneratorsOfRing, [ gen ],
                      Size, m ),

      ElementType:= efam!.elementType,

      ElementGAPToJulia:= function( C, obj )
        if IsInt( obj ) then
          return C!.JuliaDomainPointer( obj );
        elif IsZmodnZObj( obj ) then
          return C!.JuliaDomainPointer( obj![1] );
        fi;
      end,

      ElementJuliaToGAP:= function( C, obj )
        return JuliaToGAP( IsInt, Julia.Base.getfield( obj,
                   JuliaSymbol( "data" ) ) ) * One( C!.GAPDomain );
#T Deal with the case of fmpz!
      end,

      ElementWrapped:= function( C, obj )
        return ObjectifyWithAttributes( rec(), C!.ElementType,
                   JuliaPointer,  obj );
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToJulia:= function( C, vec )
        if IsZmodnZObjNonprimeCollection( vec ) then
          # 'vec' is a vector of residues, unpack it.
          if IsPlistRep( vec ) then
            vec:= List( vec, Int );
          fi;
        fi;
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                   Julia.GAPUtilsExperimental.MatrixFromNestedArray(
                       GAPToJulia( [ vec ] ) ) );
      end,

      VectorJuliaToGAP:= function( C, mat )
        return GAPMatrix_fmpz_mat( Julia.Nemo.lift( mat ) )[1]
               * One( C!.GAPDomain );
      end,

      VectorWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.VectorType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToJulia:= function( C, mat )
        if IsZmodnZObjNonprimeCollColl( mat ) then
          # 'mat' is a matrix of residues, unpack it.
          if IsPlistRep( mat ) then
            mat:= List( mat, row -> List( row, Int ) );
          fi;
        fi;
        return Julia.Nemo.matrix( C!.JuliaDomainPointer,
                   Julia.GAPUtilsExperimental.MatrixFromNestedArray(
                       GAPToJulia( mat ) ) );
      end,

      MatrixJuliaToGAP:= function( C, mat )
        return GAPMatrix_fmpz_mat( Julia.Nemo.lift( mat ) )
               * One( C!.GAPDomain );
      end,

      MatrixWrapped:= function( C, mat )
        return ObjectifyWithAttributes( rec(), C!.MatrixType,
                   JuliaPointer, mat,
                   BaseDomain, C!.GAPDomain );
      end,
    ) );
    end );


#############################################################################
##
##  Support for matrix groups of Nemo matrices of residues
##


############################################################################
##
#M  RowsOfMatrix( <matobj> )
##
InstallMethod( RowsOfMatrix,
    [ "IsNemoMatrixObj" ],
    function( mat )
    local C;

    C:= ContextGAPNemo( FamilyObj( mat ) );
    return List( NemoToGAP( C, mat ), row -> GAPToNemo( C, row ) );
    end );


##############################################################################
##
#T hack in order to work around a bug in SparseActionHomomorphism
#T (fixed in master branch?)
##
InstallOtherMethod( \^,
    IsIdenticalObj,
    [ "IsListDefault", "IsMatrixObj and IsNemoObject" ],
    function( pnts, mat )
      return List( pnts, pnt -> pnt^mat );
    end );


##############################################################################
##
#T  TODO: provide more matrix group functionality:
##
# DefaultFieldOfMatrixGroup
# FieldOfMatrixGroup
# TransposedMatrixGroup
# NaturalActedSpace
# IsSubgroupSL  (other Natural-properties!)
# InvariantBilinearForm
# AffineActionByMatrixGroup

