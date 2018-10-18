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
    local cfunction_call_string, i, cfunc, function_ptr, arg_string, nr_args;

    if not IsString( julia_name ) then
        ErrorNoReturn( "first argument must be a string" );
    fi;

    if IsString( arg_names ) then
        arg_string := arg_names;
        arg_names := SplitString(arg_names, ",");
    elif IsList( arg_names ) and ForAll( arg_names, IsString ) then
        arg_string := JoinStringsWithSeparator( arg_names, "," );
    else
        ErrorNoReturn( "second argument must be a string or a a list of strings" );
    fi;

    nr_args := Length( arg_names );

    ## Create a call to the @cfunction macro, to get a pointer to a compiled function
    cfunction_call_string := Concatenation( "temp = @cfunction(", julia_name );
    cfunction_call_string := Concatenation( cfunction_call_string, ",Ptr{Cvoid},(" );
    for i in [ 1 .. nr_args ] do
        cfunction_call_string := Concatenation( cfunction_call_string, "Ptr{Cvoid}," );
    od;
    cfunction_call_string := Concatenation( cfunction_call_string, "));" );
    ## Cast pointer to void to be able to unbox it later
    cfunction_call_string := Concatenation( cfunction_call_string, "\nreinterpret(Ptr{Cvoid},temp)");
    function_ptr := JuliaEvalString( cfunction_call_string );
    return _NewJuliaCFunc( function_ptr, nr_args, arg_string );

end );

InstallGlobalFunction( JuliaSetGAPFuncAsJuliaObjFunc,
    _JuliaSetGAPFuncAsJuliaObjFunc );

BindGlobal( "AddGapJuliaFuncs",
  function( )
    local all_necessary_funcs, current_name, current_func;

    all_necessary_funcs := Filtered( NamesGVars(),
      function( i )
        local glob;
        if not IsBoundGlobal( i ) then
            return false;
        fi;
        glob := ValueGlobal( i );
        if IsFunction( glob )  then
            return true;
        fi;
        return false;
    end );

    for current_name in all_necessary_funcs do
        current_func := ValueGlobal( current_name );
        _JuliaSetGAPFuncAsJuliaObjFunc( current_func, current_name );
    od;

end );
