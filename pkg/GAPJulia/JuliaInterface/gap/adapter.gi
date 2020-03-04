
#############################################################################
##
##  Install methods for 'IsJuliaObject' objects.
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

Perform([[ "IsJuliaObject", "IsJuliaObject" ],
         [ "IsJuliaObject", "IsInt and IsSmallIntRep" ],
         [ "IsInt and IsSmallIntRep", "IsJuliaObject" ]],
    function(argTypes)
        InstallOtherMethod( \+, argTypes, Julia.Base.\+ );
        InstallOtherMethod( \*, argTypes, Julia.Base.\* );
        InstallOtherMethod( \-, argTypes, Julia.Base.\- );
        InstallOtherMethod( \/, argTypes, Julia.Base.\/ );
        InstallOtherMethod( LQUO, argTypes, Julia.Base.\\ );
        InstallOtherMethod( \^, argTypes, Julia.Base.\^ );
        InstallOtherMethod( \=, argTypes, Julia.Base.\=\= );
        InstallOtherMethod( \<, argTypes, Julia.Base.\< );
    end);


#
# lists
#
InstallOtherMethod( \[\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.getindex( obj, i );
    end );

InstallOtherMethod( \[\]\:\=,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep", "IsObject" ],
    function( obj, i, val )
      return Julia.Base.setindex\!( obj, val, i );
    end );

#
# "matrices" / lists of lists
#
#TODO:  Remove the installations for '\[\]' and '\[\]\:\='
#       as soon as a released GAP version supports '\[\,\]' and '\[\,\]\:\='.
if IsBound( \[\,\] ) then
InstallOtherMethod( \[\,\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep" ],
    function( obj, i, j )
      return Julia.Base.getindex( obj, i, j );
    end );
else
InstallOtherMethod( \[\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep" ],
    function( obj, i, j )
      return Julia.Base.getindex( obj, i, j );
    end );
fi;

if IsBound( \[\,\]\:\= ) then
InstallOtherMethod( \[\,\]\:\=,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep", "IsObject" ],
    function( obj, i, j, val )
      return Julia.Base.setindex\!( obj, val, i, j );
    end );
else
InstallOtherMethod( \[\]\:\=,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep", "IsObject" ],
    function( obj, i, j, val )
      return Julia.Base.setindex\!( obj, val, i, j );
    end );
fi;

#
# access to fields and properties
#
BindGlobal("_JL_RNAM_TO_JULIA_SYMBOL_CACHE", rec());
BindGlobal("_JL_RNAM_TO_JULIA_SYMBOL", function(rnam)
    local symbol;
    if ISB_REC(_JL_RNAM_TO_JULIA_SYMBOL_CACHE, rnam) then
        symbol := ELM_REC(_JL_RNAM_TO_JULIA_SYMBOL_CACHE, rnam);
    else;
        symbol := JuliaSymbol( NameRNam( rnam ) );
        ASS_REC(_JL_RNAM_TO_JULIA_SYMBOL_CACHE, rnam, symbol);
    fi;
    return symbol;
end);

InstallOtherMethod( \.,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, rnam )
      return Julia.Base.getproperty( obj, _JL_RNAM_TO_JULIA_SYMBOL( rnam ) );
    end );

InstallOtherMethod( \.\:\=,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep", "IsObject" ],
    function( obj, rnam, val )
      return Julia.Base.setproperty\!( obj, _JL_RNAM_TO_JULIA_SYMBOL( rnam ), val );
    end );


#############################################################################
##
#E

