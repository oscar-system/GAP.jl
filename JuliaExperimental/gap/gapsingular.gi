##############################################################################
##
##  gapsingular.gi
##
##  experimental interface between GAP and Singular's objects
##


##############################################################################
##
#M  GAPToSingular( <context>, <obj> )
#M  GAPToSingular( <domain>, <obj> )
##
InstallMethod( GAPToSingular,
    [ "IsDomain", "IsObject" ],
    function( D, obj )
    return GAPToSingular( ContextGAPSingular( D ), obj );
    end );

InstallMethod( GAPToSingular,
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
#M  SingularToGAP( <context>, <obj> )
##
InstallMethod( SingularToGAP,
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

