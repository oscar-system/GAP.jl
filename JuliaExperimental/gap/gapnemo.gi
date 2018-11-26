##############################################################################
##
##  gapnemo.gi
##
##  This is an experimental interface to Nemo's objects.
##


#############################################################################
##
#F  JuliaArrayOfFmpz( <coeffs> )
##
##  For a list <A>coeffs</A> of integers, this function creates
##  a &Julia; array that contains the corresponding &Julia; objects of type
##  <C>fmpz</C>.
##
BindGlobal( "JuliaArrayOfFmpz",
    coeffs -> Julia.Base.map( Julia.Nemo.fmpz, GAPToJulia( coeffs ) ) );


#############################################################################
##
#F  JuliaArrayOfFmpq( <coeffs> )
##
##  For a list <A>coeffs</A> of rationals, this function creates
##  a &Julia; array that contains the corresponding &Julia; objects of type
##  <C>fmpq</C>.
##
BindGlobal( "JuliaArrayOfFmpq", function( coeffs )
    local arr, i, fmpz, div, entry, num, den;

    arr:= [];
    i:= 1;
    fmpz:= Julia.Nemo.fmpz;
    div:= Julia.Base.("//");
    for entry in coeffs do
      if IsInt( entry ) then
        arr[i]:= entry;
      else
        num:= GAPToJulia( NumeratorRat( entry ) );
        den:= GAPToJulia( DenominatorRat( entry ) );
        arr[i]:= div( fmpz( num ), fmpz( den ) );
      fi;
      i:= i + 1;
    od;
    arr:= Julia.Base.map( Julia.Nemo.fmpq, GAPToJulia( arr ) );

    return arr;
    end );


#############################################################################
##
#F  FmpzToGAP( <fmpz> )
##
BindGlobal( "FmpzToGAP",
    fmpz -> JuliaToGAP( IsInt, Julia.Base.BigInt( fmpz ) ) );


#############################################################################
##
#F  GAPDescriptionOfNemoPolynomial( <C>, <pol> )
##
BindGlobal( "GAPDescriptionOfNemoPolynomial", function( C, pol )
    local R, info, FC, monomials;

    R:= C!.GAPDomain;

    if IsUnivariatePolynomialRing( R ) then
      info:= Julia.GAPNemoExperimental.CoefficientsOfUnivarateNemoPolynomial(
                 pol );
# is "Array{Nemo.fmpq,1}", I need "Nemo.fmpq_mat" ...
      info:= Julia.Nemo.matrix( Julia.Nemo.parent( info[1] ), 1,
                 Julia.Base.length( info ), info );
      FC:= ContextGAPNemo( LeftActingDomain( R ) );
      return FC!.MatrixNemoToGAP( FC, info )[1];
    else
#T not yet o.k.!
      info:= JuliaGetFieldOfObject( pol, "coeffs" );
      info:= NemoToGAP( ContextGAPNemo( LeftActingDomain( R ) ), info );
      monomials:= Julia.GAPUtilsExperimental.NestedArrayFromMatrix(
                      JuliaGetFieldOfObject( pol, "exps" ) );

      return Concatenation( TransposedMat( 
                 [ JuliaToGAP( IsList, monomials, true ), info ] ) );
    fi;
    end );


##############################################################################
##
BindGlobal( "ContextObjectsFamily", NewFamily( "ContextObjectsFamily" ) );


##############################################################################
##
InstallMethod( ViewString,
    [ "IsContextObj" ],
    Name );


##############################################################################
##
#F  NewContextGAPNemo( <arec> )
##
InstallGlobalFunction( NewContextGAPNemo, function( arec )
    local pair, nam, cond, C;

    if not IsRecord( arec ) then
      Error( "<arec> must be a record" );
    fi;

    for pair in [ [ "Name", "IsString" ],
                  [ "GAPDomain", "IsDomain" ],
                  [ "JuliaDomain", "HasJuliaPointer" ],
                  [ "ElementType", "IsType" ],
                  [ "ElementGAPToNemo", "IsFunction" ],
                  [ "ElementNemoToGAP", "IsFunction" ],
                  [ "VectorType", "IsType" ],
                  [ "VectorGAPToNemo", "IsFunction" ],
                  [ "VectorNemoToGAP", "IsFunction" ],
                  [ "MatrixType", "IsType" ],
                  [ "MatrixGAPToNemo", "IsFunction" ],
                  [ "MatrixNemoToGAP", "IsFunction" ],
                ] do
      nam:= pair[1];
      cond:= pair[2];
      if not IsBound( arec.( nam ) ) then
        Error( "the component '", nam, "' must be bound in <arec>" );
      elif not ValueGlobal( cond )( arec.( nam ) ) then
        Error( "the component '", nam, "' must be in \"", cond, "\"" );
      fi;
    od;

    arec.JuliaDomainPointer:= JuliaPointer( arec.JuliaDomain );

    C:= ObjectifyWithAttributes( arec,
            NewType( ContextObjectsFamily,
                     IsContextObj and IsAttributeStoringRep),
            Name, arec.Name );
    SetContextGAPNemo( FamilyType( arec!.ElementType ), C );
    SetContextGAPNemo( FamilyType( arec!.VectorType ), C );
    SetContextGAPNemo( FamilyType( arec!.MatrixType ), C );

    return C;
end );


##############################################################################
##
#M  GAPToNemo( <context>, <obj> )
#M  GAPToNemo( <domain>, <obj> )
##
InstallMethod( GAPToNemo,
    [ "IsDomain", "IsObject" ],
    function( D, obj )
    return GAPToNemo( ContextGAPNemo( D ), obj );
    end );

InstallMethod( GAPToNemo,
    [ "IsContextObj", "IsObject" ],
    function( C, obj )
    local juliaobj;

    if IsRowVector( obj ) or IsVectorObj( obj ) then
      juliaobj:= C!.VectorGAPToNemo( C, obj );
      return ObjectifyWithAttributes( rec(),
                 C!.VectorType,
                 BaseDomain, C!.JuliaDomain,
                 Length, Length( obj ),
                 JuliaPointer, juliaobj );
    elif IsMatrix( obj ) or IsMatrixObj( obj ) then
      juliaobj:= C!.MatrixGAPToNemo( C, obj );
      return ObjectifyWithAttributes( rec(),
                 C!.MatrixType,
                 BaseDomain, C!.JuliaDomain,
                 NumberRows, NumberRows( obj ),
                 NumberColumns, NumberColumns( obj ),
                 JuliaPointer, juliaobj );
    elif IsRingElement( obj ) then
      juliaobj:= C!.ElementGAPToNemo( C, obj );
      return ObjectifyWithAttributes( rec(),
                 C!.ElementType,
                 JuliaPointer, juliaobj );
    else
      Error( "cannot convert <obj>" );
    fi;
    end );


##############################################################################
##
#M  NemoToGAP( <context>, <obj> )
##
InstallMethod( NemoToGAP,
    [ "IsContextObj", "IsObject" ],
    function( C, obj )
    if IsMatrixObj( obj ) then
      return C!.MatrixNemoToGAP( C, obj );
    elif IsVectorObj( obj ) then
      return C!.VectorNemoToGAP( C, obj );
    elif IsRingElement( obj ) then
      return C!.ElementNemoToGAP( C, obj );
    else
      Error( "cannot convert <obj>" );
    fi;
    end );


##############################################################################
##
#E

