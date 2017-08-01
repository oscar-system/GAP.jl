#
# JuliaInterface: Test interface to julia
#
# Implementations
#
InstallGlobalFunction( JuliaInterface_Example,
function()
	Print( "This is a placeholder function, replace it with your own code.\n" );
end );

BindGlobal( "JuliaString", JuliaFunction( "string" ) );


InstallMethod( ViewString,
               [ IsJuliaObject ],
               
  function( julia_obj )
    
    return Concatenation( "<Julia: ", String( julia_obj ), ">" );
    
end );

InstallMethod( String,
               [ IsJuliaObject ],
               
  function( julia_obj )
    
    return JuliaUnbox( JuliaCallFunc1Arg( JuliaString, julia_obj ) );
    
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
