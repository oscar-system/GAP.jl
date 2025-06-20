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
##  experimental interface between GAP and Nemo's objects
##


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
    local result;

    if IsRowVector( obj ) or IsVectorObj( obj ) then
      result:= C!.VectorWrapped( C, C!.VectorGAPToJulia( C, obj ) );
      SetLength( result, Length( obj ) );
      return result;
    elif IsMatrix( obj ) or IsMatrixObj( obj ) then
      result:= C!.MatrixWrapped( C, C!.MatrixGAPToJulia( C, obj ) );
      SetNumberRows( result, NumberRows( obj ) );
      SetNumberColumns( result, NumberColumns( obj ) );
      return result;
    elif IsRingElement( obj ) then
      return C!.ElementWrapped( C, C!.ElementGAPToJulia( C, obj ) );
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
      return C!.MatrixJuliaToGAP( C, obj );
    elif IsVectorObj( obj ) then
      return C!.VectorJuliaToGAP( C, obj );
    elif IsRingElement( obj ) then
      return C!.ElementJuliaToGAP( C, obj );
    else
      Error( "cannot convert <obj>" );
    fi;
    end );


#############################################################################
##
##  some auxiliary functions
##


#############################################################################
##
##  Convert between an exponent vector and the corresponding word in syllable
##  representation.
##
BindGlobal( "ExponentVectorFromWord", function( word, n )
    local result, i;

    result:= ListWithIdenticalEntries( n, 0 );
    for i in [ 2, 4 .. Length( word ) ] do
      result[ word[ i-1 ] ]:= word[i];
    od;
    return result;
    end );

BindGlobal( "WordFromExponentVector", function( exps )
    local result, i;

    result:= [];
    for i in [ 1 .. Length( exps ) ] do
      if exps[i] <> 0 then
        Add( result, i );
        Add( result, exps[i] );
      fi;
    od;
    return result;
    end );


#############################################################################
##
#F  JuliaArrayOfFmpz( <coeffs> )
##
##  For a &GAP; list <A>coeffs</A> of integers, this function creates
##  a &Julia; array that contains the corresponding &Julia; objects of type
##  <C>ZZRingElem</C>.
##
BindGlobal( "JuliaArrayOfFmpz",
    coeffs -> Julia.Base.map( Julia.Nemo.ZZRingElem, GAPToJulia( coeffs ) ) );


#############################################################################
##
#F  JuliaArrayOfFmpq( <coeffs> )
##
##  For a list <A>coeffs</A> of rationals, this function creates
##  a &Julia; array that contains the corresponding &Julia; objects of type
##  <C>QQFieldElem</C>.
##
BindGlobal( "JuliaArrayOfFmpq", function( coeffs )
    local arr, i, ZZRingElem, div, entry, num, den;

    arr:= [];
    i:= 1;
    ZZRingElem:= Julia.Nemo.ZZRingElem;
    div:= Julia.Base.("//");
    for entry in coeffs do
      if IsInt( entry ) then
        arr[i]:= entry;
      else
        num:= GAPToJulia( NumeratorRat( entry ) );
        den:= GAPToJulia( DenominatorRat( entry ) );
        arr[i]:= div( ZZRingElem( num ), ZZRingElem( den ) );
      fi;
      i:= i + 1;
    od;
    arr:= Julia.Base.map( Julia.Nemo.QQFieldElem, GAPToJulia( arr ) );

    return arr;
    end );


#############################################################################
##
#F  FmpzToGAP( <ZZRingElem> )
##
BindGlobal( "FmpzToGAP",
    ZZRingElem -> JuliaToGAP( IsInt, Julia.Base.BigInt( ZZRingElem ) ) );


#############################################################################
##
#F  GAPDescriptionOfNemoPolynomial( <C>, <pol> )
##
BindGlobal( "GAPDescriptionOfNemoPolynomial", function( C, pol )
    local R, info, FC, n, RC, coeffs, monoms;

    R:= C!.GAPDomain;
    if HasJuliaPointer( pol ) then
      pol:= JuliaPointer( pol );
    fi;

    if IsUnivariatePolynomialRing( R ) then
      info:= Julia.GAPNemoExperimental.CoefficientsOfUnivarateNemoPolynomial(
                 pol );
      # This is "Vector{Nemo.QQFieldElem}", but we need "Nemo.QQMatrix".
      info:= Julia.Nemo.matrix( Julia.Nemo.parent( info[1] ), 1,
                 Julia.Base.length( info ), info );
      FC:= ContextGAPNemo( LeftActingDomain( R ) );
      return FC!.MatrixJuliaToGAP( FC, info )[1];
    else
      n:= Julia.Base.length( pol );
      RC:= ContextGAPNemo( LeftActingDomain( R ) );
      coeffs:= List( [ 1 .. n ],
               i -> RC!.ElementJuliaToGAP( RC, Julia.Nemo.coeff( pol, i ) ) );
      monoms:= List( [ 1 .. n ],
               i -> WordFromExponentVector( JuliaToGAP( IsList,
                        Julia.Nemo.exponent_vector( pol, i ) ) ) );
      return Concatenation( TransposedMat( [ monoms, coeffs ] ) );
    fi;
    end );

