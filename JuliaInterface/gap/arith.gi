
#############################################################################
##
##  Install methods for 'IsJuliaObj' objects.
##

InstallOtherMethod( AdditiveInverseOp,
    [ "IsJuliaObject" ],
    function( obj )
      return Julia.Base.("-")( obj );
    end );

InstallOtherMethod( ZeroOp,
    [ "IsJuliaObject" ],
    function( obj )
      return Julia.Base.zero( obj );
    end );

InstallOtherMethod( OneOp,
    [ "IsJuliaObject" ],
    function( obj )
      return Julia.Base.one( obj );
    end );

InstallOtherMethod( \[\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.getindex( obj, i );
    end );

InstallOtherMethod( \[\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep" ],
    function( obj, i, j )
      return Julia.Base.getindex( obj, i, j );
    end );

Perform([[ "IsJuliaObject", "IsJuliaObject" ],
         [ "IsJuliaObject", "IsInt and IsSmallIntRep" ],
         [ "IsInt and IsSmallIntRep", "IsJuliaObject" ]],
    function(argTypes)
        InstallOtherMethod( \+, argTypes, Julia.Base.\+ );
        InstallOtherMethod( \*, argTypes, Julia.Base.\* );
        InstallOtherMethod( \-, argTypes, Julia.Base.\- );
        InstallOtherMethod( \=, argTypes, Julia.Base.\=\= );
        InstallOtherMethod( \<, argTypes, Julia.Base.\< );
    end);


InstallOtherMethod( \^,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.("^")( obj, i );
    end );


#############################################################################
##
#E

