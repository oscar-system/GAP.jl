##############################################################################
##
##  record.g
##
##  Convert GAP records to Julia dictionaries and vice versa.
##
##  No additional Julia code is needed for that.
##


##############################################################################
##
#! @Arguments arec
#! @Returns a &Julia; object
#! @Description
#!  For a record <A>arec</A>,
#!  this function creates a dictionary in &Julia;
#!  whose components are the record components of <A>arec</A>,
#!  and the corresponding 
InstallMethod( ConvertedToJulia,
    [ "IsRecord" ],
    function( arec )
    local dict, setindex, comp, val;

    # Create an empty dictionary, in Julia one writes 'Dict()'.
    # Note that 'Julia.Base.Dict' is not in 'IsJuliaFunction';
    # without a 'CallFuncList' method for 'IsJuliaObject',
    # one would have to write
    # dict:= __JuliaCallFunc0Arg( Julia.Base.Dict );
    dict:= Julia.Base.Dict();

    # Add the components.
    setindex:= Julia.Base.( "setindex!" );
    for comp in RecNames( arec ) do
      # Do not call 'ConvertedToJulia', catch the 'fail' results.
      val:= __ConvertedToJulia( arec.( comp ) );
#T correct for IsJuliaFunction objects?
      if val = fail then
        # We cannot convert all components.
        return fail;
      fi;
      setindex( dict, val, comp );
    od;

    return dict;
end );


##############################################################################
##
#! @Arguments dict
#! @Returns a &GAP; record or <K>fail</K>
#! @Description
#!  For a pointer <A>dict</A> to a &Julia; dictionary,
#!  this function returns the &GAP; record whose components are the
#!  keys of <A>dict</A>, and the values are the corresponding values.
#!  If the global option <C>"recursive"</C> is <K>true</K> then
#!  the lists and records that occur as values are unboxed recursively.
DeclareGlobalFunction( "ConvertedFromJuliaRecordFromDictionary" );


##############################################################################
##
#! @Arguments obj
#! @Returns a &GAP; object
#! @Description
#!  For a pointer <A>obj</A> to a &Julia; object,
#!  this function does the same as <Ref Func="StructuralConvertedFromJulia"/>,
#!  except that also &Julia; dictionaries 
DeclareGlobalFunction( "StructuralConvertedFromJulia_AlsoRecord" );


InstallGlobalFunction( "ConvertedFromJuliaRecordFromDictionary", function( dict )
    local info, result, recursive, i, comp;

    info:= __ConvertedFromJulia_record_dict( dict );
    result:= rec();
    recursive:= ( ValueOption( "recursive" ) = true );
    for i in [ 1 .. Length( info[1] ) ] do
      comp:= __ConvertedFromJulia( info[1][i] );
      if not IsString( comp ) then
        # This dictionary cannot be converted to a GAP record.
        return fail;
      fi;
      if recursive then
        result.( comp ):= StructuralConvertedFromJulia_AlsoRecord( info[2][i] );
      else
        result.( comp ):= info[2][i];
      fi;
    od;

    return result;
end );


InstallGlobalFunction( StructuralConvertedFromJulia_AlsoRecord, function( object )
    local unboxed_obj;

    unboxed_obj:= __ConvertedFromJulia( object );
    if IsList( unboxed_obj ) and not IsString( unboxed_obj ) then
      return List( unboxed_obj, StructuralConvertedFromJulia_AlsoRecord );
    elif unboxed_obj = fail and
         StartsWith( JuliaTypeInfo( object ), "Dict{" ) then
      # The Julia object is a dictionary.
      unboxed_obj:= ConvertedFromJuliaRecordFromDictionary( object : recursive );
    fi;
    return unboxed_obj;
end );


