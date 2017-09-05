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
  function( julia_name, gap_name, nr_args, arg_names )
    local cfunction_call_string, i;

    if not IsString( julia_name ) then
        Error( "first argument must be a string" );
        return;
    fi;

    if not IsString( gap_name ) then
        Error( "second argument must be a string" );
        return;
    fi;

    if not IsInt( nr_args ) or not nr_args >= 0 then
        Error( "third argument must be an non-negative integer" );
        return;
    fi;

    if not IsString( arg_names ) then
        Error( "fourth argument must be a string" );
        return;
    fi;

    cfunction_call_string := Concatenation( "cfunction(", julia_name );
    cfunction_call_string := Concatenation( cfunction_call_string, ",Ptr{Void},(" );
    for i in [ 0 .. nr_args ] do
        cfunction_call_string := Concatenation( cfunction_call_string, "Ptr{Void}," );
    od;
    Remove( cfunction_call_string );
    cfunction_call_string := Concatenation( cfunction_call_string, "))" );

    JuliaBindCFunction_internal( gap_name, cfunction_call_string, nr_args, arg_names );

end );
