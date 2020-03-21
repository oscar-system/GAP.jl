#############################################################################
##
##  JuliaInterface package
##
##  Copyright 2017
##    Thomas Breuer, RWTH Aachen University
##    Sebastian Gutsche, Siegen University
##
#############################################################################

InstallGlobalFunction( JuliaBindCFunction,
  function( julia_name, arg_names )
    local cfunction_call_string, i, cfunc, function_ptr, nr_args;

    if not IsString( julia_name ) then
        ErrorNoReturn( "first argument must be a string" );
    fi;

    if IsString( arg_names ) then
        arg_names := SplitString(arg_names, ",");
        MakeImmutable( arg_names );
    elif IsList( arg_names ) and ForAll( arg_names, IsString ) then
        # make sure this is an immutable plist containing immutable strings
        arg_names := List( arg_names, Immutable );
        MakeImmutable( arg_names );
    else
        ErrorNoReturn( "second argument must be a string or a list of strings" );
    fi;

    nr_args := Length( arg_names );

    ## Create a call to the @cfunction macro, to get a pointer to a compiled function
    cfunction_call_string := Concatenation( "temp = @cfunction(", julia_name );
    Append( cfunction_call_string, ",Ptr{Cvoid},(" );
    for i in [ 1 .. nr_args ] do
        Append( cfunction_call_string, "Ptr{Cvoid}," );
    od;
    Append( cfunction_call_string, "));\n" );
    ## Cast pointer to void to be able to unbox it later
    Append( cfunction_call_string, "reinterpret(Ptr{Cvoid},temp)");
    function_ptr := JuliaEvalString( cfunction_call_string );
    return _NewJuliaCFunc( function_ptr, arg_names );

end );
