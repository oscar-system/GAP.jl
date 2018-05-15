
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

InstallOtherMethod( \+,
    [ "IsJuliaObject", "IsJuliaObject" ],
    function( obj1, obj2 )
      return Julia.Base.("+")( obj1, obj2 );
    end );

InstallOtherMethod( \+,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.("+")( obj, i );
    end );

InstallOtherMethod( \+,
    [ "IsPosInt and IsSmallIntRep", "IsJuliaObject" ],
    function( i, obj )
      return Julia.Base.("+")( i, obj );
    end );

InstallOtherMethod( \-,
    [ "IsJuliaObject", "IsJuliaObject" ],
    function( obj1, obj2 )
      return Julia.Base.("-")( obj1, obj2 );
    end );

InstallOtherMethod( \-,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.("-")( obj, i );
    end );

InstallOtherMethod( \-,
    [ "IsPosInt and IsSmallIntRep", "IsJuliaObject" ],
    function( i, obj )
      return Julia.Base.("-")( i, obj );
    end );

InstallOtherMethod( \*,
    [ "IsJuliaObject", "IsJuliaObject" ],
    function( obj1, obj2 )
      return Julia.Base.("*")( obj1, obj2 );
    end );

InstallOtherMethod( \*,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.("*")( obj, i );
    end );

InstallOtherMethod( \*,
    [ "IsPosInt and IsSmallIntRep", "IsJuliaObject" ],
    function( i, obj )
      return Julia.Base.("*")( i, obj );
    end );

InstallOtherMethod( \^,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.("^")( obj, i );
    end );


#############################################################################
##
#E

