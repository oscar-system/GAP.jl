#############################################################################
##
##  JuliaInterface package
##
#############################################################################

## Create a record from key value lists
BindGlobal( "CreateRecFromKeyValuePairList",
  function( keys, vals )
    local return_rec, i;
    return_rec := rec();
    for i in [1 .. Length( keys ) ] do
        return_rec.(keys[i]) := vals[i];
    od;
    return return_rec;
end );

BindGlobal( "StringDisplayObj",
function(obj)
  local str, out;
  str := "";
  out := OutputTextString(str, false);
  STREAM_CALL(out, Display, obj);
  CloseStream(out);
  return str;
end );

BindGlobal( "StringViewObj",
function(obj)
  local str, out;
  str := "";
  out := OutputTextString(str, false);
  STREAM_CALL(out, ViewObj, obj);
  CloseStream(out);
  return str;
end );

##  Compute the URL of a manual entry in the current &GAP; online manuals.
##  (This should eventually be moved to GAPDoc.)
##
##  <A>reference</A> must be a string of the form <C>pkgname:label</C>,
##  for example <C>ref:Size</C> or <C>atlasrep:InfoAtlasRep</C>.
##
##  <A>prefix</A>, if given, must be the URL to a directory containing the
##  HTML versions of &GAP; manuals;
##  the default is the current address at <C>www.gap-system.org</C>.
##
BindGlobal( "UrlOfManualEntry", function( reference, prefix... )
    local pos, pkgname, label, ref, test, localurl, middle, nextpos, suffix;

    # Deal with the optional argument.
    if Length( prefix ) = 0 then
      prefix:= "https://www.gap-system.org/Manuals/";
    elif Length( prefix ) = 1 and IsString( prefix[1] ) then
      prefix:= prefix[1];
    else
      Error( "<prefix>, if given must be a string" );
    fi;

    # get package name and label
    pos:= Position( reference, ':' );
    if pos = fail then
      return fail;
    fi;
    pkgname:= reference{ [ 1 .. pos-1 ] };
    label:= reference{ [ pos+1 .. Length( reference ) ] };

    # the anchor for the label
    ref:= GAPDoc2HTMLProcs.ResolveExternalRef( pkgname, label, 1 );
    if ref = fail then
      return fail;
    fi;
    test:= ref[1];
    if test{ [ PositionSublist( test, ": " ) + 2 .. Length( test ) ] }
       <> label then
      Info( InfoWarning, 1,
            "UrlOfManualEntry for label '", label, "': found reference to '",
            test, "'" );
      return fail;
    fi;
    localurl:= ref[6];

    # prescribe the substring where to cut off the suffix
    if pkgname = "ref" then
      middle:= "/doc/ref/";
    elif pkgname = "tut" then
      middle:= "/doc/tut/";
    else
      middle:= "/pkg/";
    fi;

    # compute the suffix
    pos:= PositionSublist( localurl, middle );
    if pos = fail then
      return fail;
    fi;
    nextpos:= PositionSublist( localurl, middle, pos );
    while nextpos <> fail do
      pos:= nextpos;
      nextpos:= PositionSublist( localurl, "/pkg/", pos );
    od;
    suffix:= localurl{ [ pos + 1 .. Length( localurl ) ] };

    return Concatenation( prefix, suffix );
end );

BindGlobal( "ComputeLinksToGAPManuals", function( str )
    local pos, pos2, reference, repl;

    pos:= PositionSublist( str, "GAP_ref(" );
    while pos <> fail do
      pos2:= Position( str, ')', pos );
      if pos2 = fail then
        Info( InfoWarning, 1, "syntax/tagging problem" );
        return "";
      fi;
      reference:= str{ [ pos + 8 .. pos2 - 1 ] };
      repl:= UrlOfManualEntry( reference );
      if repl = fail then
        Info( InfoWarning, 1, "reference '", reference, "' not found" );
        return "";
      fi;
      str:= ReplacedString( str, str{ [ pos .. pos2 ] }, repl );
      pos:= PositionSublist( str, "GAP_ref(", pos );
    od;
    return str;
end );
