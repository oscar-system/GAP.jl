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
