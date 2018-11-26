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

    return NewContextGAPNemo( rec(
      Name:= Concatenation( "<context for Integers mod ", String( m ), ">" ),

      GAPDomain:= R,

      JuliaDomain:= ObjectifyWithAttributes( rec(), NewType( collfam, type ),
                      JuliaPointer, juliaRing,
                      GeneratorsOfRing, [ gen ],
                      Size, m ),

      ElementType:= efam!.elementType,

      ElementGAPToNemo:= function( C, obj )
        if IsInt( obj ) then
          return C!.JuliaDomainPointer( obj );
        elif IsZmodnZObj( obj ) then
          return C!.JuliaDomainPointer( obj![1] );
        fi;
      end,

      ElementNemoToGAP:= function( C, obj )
        if HasJuliaPointer( obj ) then
          obj:= JuliaPointer( obj );
        fi;
        return JuliaToGAP( IsInt, Julia.Base.getfield( obj,
                   JuliaSymbol( "data" ) ) ) * One( C!.GAPDomain );
#T Deal with the case of fmpz!
      end,

      VectorType:= efam!.vectorType,

      VectorGAPToNemo:= function( C, vec )
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

      VectorNemoToGAP:= function( C, mat )
        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        return GAPMatrix_fmpz_mat( Julia.Nemo.lift( mat ) )[1]
               * One( C!.GAPDomain );
      end,

      MatrixType:= efam!.matrixType,

      MatrixGAPToNemo:= function( C, mat )
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

      MatrixNemoToGAP:= function( C, mat )
        if HasJuliaPointer( mat ) then
          mat:= JuliaPointer( mat );
        fi;
        return GAPMatrix_fmpz_mat( Julia.Nemo.lift( mat ) )
               * One( C!.GAPDomain );
      end,

    ) );
    end );


## --------------------------------------------------------------------

#############################################################################
##
#F  Nemo_ResidueRing( <m> )
##
##  the ring of residues modulo the integer <m>
##

#T not needed anymore!

BindGlobal( "Nemo_ResidueRing", function( m )
    local type, juliaobj, efam, collfam, result, gen;

    type:= IsNemoRing and IsAttributeStoringRep and
           IsCommutative and IsAssociative;

    # Check the argument.
    if not IsPosInt( m ) then
      Error( "<m> must be a positive integer" );
    fi;

    juliaobj:= Julia.Nemo.ResidueRing( Julia.Nemo.ZZ, m );

    # Create the GAP wrapper.
    # Note that elements from two Nemo polynomial rings cannot be compared,
    # so we create always a new family.
    efam:= NewFamily( "NEMO_ResiduesFamily", IsNemoObject, IsScalar );
    collfam:= CollectionsFamily( efam );
    efam!.defaultType:= NewType( efam,
        IsNemoRingElement and IsAttributeStoringRep );
    # Do *NOT* set 'IsMatrix', this would imply 'IsList'!
    efam!.matrixType:= NewType( CollectionsFamily( collfam ),
        IsMatrixObj and IsNemoRingElement and IsAttributeStoringRep );

    result:= Objectify( NewType( collfam, type ), rec() );

    gen:= ObjectifyWithAttributes( rec(),
                            efam!.defaultType,
                            JuliaPointer, juliaobj( 1 ) );

    # Set attributes.
    SetJuliaPointer( result, juliaobj );
    SetGeneratorsOfRing( result, [ gen ] );
    SetIsFinite( result, true );
    SetSize( result, m );
#T set one and zero?

    return result;
end );



InstallOtherMethod( InverseMutable,
    [ "IsNemoRingElement" ],
    function( mat )
    local efam, juliaobj;

    efam:= ElementsFamily( ElementsFamily( FamilyObj( mat ) ) );
    juliaobj:= Julia.Base.inv( JuliaPointer( mat ) );

    return ObjectifyWithAttributes( rec(),
                            efam!.matrixType,
                            JuliaPointer, juliaobj );
    end );


#############################################################################
##
##  matrix groups of Nemo matrices?
##

#T The higher ranked method from 'lib/grpmat.gi' calls 'IdentityMat'.
#T (Remove the higher ranked method?)
InstallOtherMethod( One,
    "for a magma-with-one consisting of Nemo matrix objects",
    [ "IsMagmaWithOne and IsNemoObjectCollCollColl" ],
    RankFilter( IsMatrixGroup ),
    M -> One( Representative( M ) ) );

#T The method from 'lib/grpmat.gi' calls 'DimensionsMat'.
#T (Adjust this method.)
InstallMethod( IsGeneratorsOfMagmaWithInverses,
    "for a list of matrices",
    [ IsRingElementCollCollColl ],
    function( matlist )
    local nrows, ncols;

    if ForAll( matlist, IsMatrixObj ) then
      nrows:= NumberRows( matlist[1] );
      ncols:= NumberColumns( matlist[1] );
      return nrows = ncols and
             ForAll( matlist,
                     mat -> NumberRows( mat ) = nrows and
                            NumberColumns( mat ) = ncols ) and
             ForAll( matlist, mat -> Inverse( mat ) <> fail );
    fi;

    TryNextMethod();
    end );

#T The method from 'lib/grpmat.gi' does not know about 'IsMatrixObj'.
#T (Adjust this method.)
InstallMethod( DefaultScalarDomainOfMatrixList,
    "generic: form ring",
    [ IsList and IsCollection ],
    function( l )
    local i,j,k,fg,f;

    if Length( l ) <> 0 and ForAll( l, IsMatrixObj ) then
      # Take the BaseDomain.
      return BaseDomain( l[1] );
#T better compare
    else
      TryNextMethod();
    fi;
end);

#T The method from 'lib/grpmat.gi' calls 'Length'.
#T (Adjust this method.)
InstallMethod( DimensionOfMatrixGroup, "from generators",
    [ IsMatrixGroup and HasGeneratorsOfGroup ],
    function( grp )
    if not IsEmpty( GeneratorsOfGroup( grp ) )  then
      return NumberRows( GeneratorsOfGroup( grp )[1] );
    else
        TryNextMethod();
    fi;
end );

#T The method from 'lib/grpmat.gi' calls 'Length'.
#T (Adjust this method.)
InstallMethod( DimensionOfMatrixGroup, "from one",
    [ IsMatrixGroup and HasOne ], 1,
    grp -> NumberRows( One( grp ) ) );

#T The method from 'lib/grpmat.gi' calls 'Length'.
#T (Adjust this method.)
InstallMethod( ViewObj,
    "for a matrix group with stored generators",
    [ IsMatrixGroup and HasGeneratorsOfGroup ],
function(G)
local gens;
  gens:=GeneratorsOfGroup(G);
  if Length(gens)>0 and Length(gens)*
                        DimensionOfMatrixGroup(G)^2 / GAPInfo.ViewLength > 8 then
    Print("<matrix group");
    if HasSize(G) then
      Print(" of size ",Size(G));
    fi;
    Print(" with ",Length(GeneratorsOfGroup(G)),
          " generators>");
  else
    Print("Group(");
    ViewObj(GeneratorsOfGroup(G));
    Print(")");
  fi;
end);

#T The method from 'lib/zmodnz.gi' calls iterated element access.
#T (Adjust this method; and better take care of 0x0 matrices.)
InstallMethod( DefaultFieldOfMatrixGroup,
    "for a matrix group over a ring Z/nZ",
    [ IsMatrixGroup and IsZmodnZObjNonprimeCollCollColl ],
    G -> ZmodnZ( Characteristic( Representative( G )[1,1] ) ) );

#T This is a hack.
#T Perhaps Nemo should provide a method?
InstallMethod( Characteristic,
    [ "IsJuliaObject" ],
    function( obj )
    if JuliaTypeInfo( obj ) = "Nemo.nmod" then
      return JuliaToGAP( IsInt, Julia.Base.getfield(
                 Julia.Nemo.parent( obj ), JuliaSymbol( "n" ) ) );
    fi;
    TryNextMethod();
    end );

#T This is a hack.
#T Better change GAP's 'NicomorphismOfGeneralMatrixGroup' such that
#T not 'One(G)' is entered as the 2nd argument
#T but a ``list of 'IsVectorObj' objects repres. the rows'';
#T provide such a functionality in 'matobj.*'.
InstallOtherMethod( SparseActionHomomorphismOp,
  "no domain given", true,
# [ IsGroup, IsList, IsList, IsList, IsFunction ], 0,
  [ IsGroup, IsMatrixObj, IsList, IsList, IsFunction ], 0,
function( G, start, gens, acts, act )
  local c;
  # Replace the matrix object by a plain list of its rows.
  c:= ContextGAPNemo( FamilyObj( start ) );
  start:= List( NemoToGAP( c, start ), row -> GAPToNemo( c, row ) );

  return DoSparseActionHomomorphism(G,start,gens,acts,act,false);
end); 


##############################################################################
##
#M  <vecobj>^<matobj>
##
##  action of 'IsMatrixObj' matrices on 'IsVectorObj' vectors
#T should become part of 'matobj.g*'?
##
InstallOtherMethod( \^,
    [ "IsVectorObj", "IsMatrixObj" ],
    \* );


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


