##############################################################################
##
##  context.gi
##
##  implementations of context objects,
##  which are used for generic conversions between GAP and Nemo/Singular
##


##############################################################################
##
InstallMethod( ViewString,
    [ "IsContextObj" ],
    Name );


##############################################################################
##
#F  NewContextGAPJulia( "Nemo", <arec> )
#F  NewContextGAPJulia( "Singular", <arec> )
##
InstallGlobalFunction( NewContextGAPJulia, function( pkgname, arec )
    local pair, nam, cond, C;

    if not IsRecord( arec ) then
      Error( "<arec> must be a record" );
    fi;

    for pair in [ [ "Name", "IsString" ],
                  [ "GAPDomain", "IsDomain" ],
                  [ "JuliaDomain", "HasJuliaPointer" ],
                  [ "ElementType", "IsType" ],
                  [ "ElementGAPToJulia", "IsFunction" ],
                  [ "ElementJuliaToGAP", "IsFunction" ],
                  [ "ElementWrapped", "IsFunction" ],
                  [ "VectorType", "IsType" ],
                  [ "VectorGAPToJulia", "IsFunction" ],
                  [ "VectorJuliaToGAP", "IsFunction" ],
                  [ "VectorWrapped", "IsFunction" ],
                  [ "MatrixType", "IsType" ],
                  [ "MatrixGAPToJulia", "IsFunction" ],
                  [ "MatrixJuliaToGAP", "IsFunction" ],
                  [ "MatrixWrapped", "IsFunction" ],
                ] do
      nam:= pair[1];
      cond:= pair[2];
      if not IsBound( arec.( nam ) ) then
        Error( "the component '", nam, "' must be bound in <arec>" );
      elif not ValueGlobal( cond )( arec.( nam ) ) then
        Error( "the component '", nam, "' must be in '", cond, "'" );
      fi;
    od;

    arec.JuliaDomainPointer:= JuliaPointer( arec.JuliaDomain );

    C:= ObjectifyWithAttributes( arec,
            NewType( ContextObjectsFamily,
                     IsContextObj and IsAttributeStoringRep),
            Name, arec.Name );
    if pkgname = "Nemo" then
      SetContextGAPNemo( FamilyType( arec!.ElementType ), C );
      SetContextGAPNemo( FamilyType( arec!.VectorType ), C );
      SetContextGAPNemo( FamilyType( arec!.MatrixType ), C );
    elif pkgname = "Singular" then
      SetContextGAPSingular( FamilyType( arec!.ElementType ), C );
      SetContextGAPSingular( FamilyType( arec!.VectorType ), C );
      SetContextGAPSingular( FamilyType( arec!.MatrixType ), C );
    else
      Error( "<pkgname> must be \"Nemo\" or \"Singular\"" );
    fi;

    return C;
end );

