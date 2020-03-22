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
