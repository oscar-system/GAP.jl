#
# JuliaInterface: Test interface to julia
#
# Implementations
#

BindJuliaFunc( "string" );

BindJuliaFunc( "include" );

BindGlobal( "JuliaKnownFiles", [] );

BindGlobal( "JuliaIncludeFile", function( filename )
    if not filename in JuliaKnownFiles then
      JuliaCallFunc1Arg( GetJuliaFunc( "include" ), JuliaBox( filename ) );
      AddSet( JuliaKnownFiles, filename );
    fi;
end );


InstallMethod( ViewString,
               [ IsJuliaObject ],

  function( julia_obj )

    return Concatenation( "<Julia: ", String( julia_obj ), ">" );

end );

InstallMethod( String,
               [ IsJuliaObject ],

  function( julia_obj )

    return JuliaUnbox( JuliaCallFunc1Arg( __JuliaFunctions.string, julia_obj ) );

end );

InstallMethod( CallFuncList,
               [ IsJuliaFunction, IsList ],

  function( julia_func, argument_list )

    if Length( argument_list ) = 0 then

        return JuliaUnbox( JuliaCallFunc0Arg( julia_func ) );

    elif Length( argument_list ) = 1 then

        return JuliaUnbox( JuliaCallFunc1Arg( julia_func, JuliaBox( argument_list[ 1 ] ) ) );

    elif Length( argument_list ) = 2 then

        return JuliaUnbox( JuliaCallFunc2Arg( julia_func, JuliaBox( argument_list[ 1 ] ), JuliaBox( argument_list[ 2 ] ) ) );

    elif Length( argument_list ) = 3 then

        return JuliaUnbox( JuliaCallFunc3Arg( julia_func, JuliaBox( argument_list[ 1 ] ), JuliaBox( argument_list[ 2 ] ), JuliaBox( argument_list[ 3 ] ) ) );

    fi;

    return JuliaUnbox( JuliaCallFuncXArg( julia_func, List( argument_list, JuliaBox ) ) );

end );
