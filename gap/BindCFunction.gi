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
    local cfunction_call_string, i, cfunc;

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

    if not IsList( arg_names ) then
        Error( "fourth argument must be a list of strings" );
        return;
    fi;

    cfunction_call_string := Concatenation( "cfunction(GAP.prepare_func_for_gap(", julia_name,")" );
    cfunction_call_string := Concatenation( cfunction_call_string, ",Ptr{Void},(" );
    for i in [ 0 .. nr_args ] do
        cfunction_call_string := Concatenation( cfunction_call_string, "Ptr{Void}," );
    od;
    Remove( cfunction_call_string );
    cfunction_call_string := Concatenation( cfunction_call_string, "))" );

    return JuliaBindCFunction_internal( gap_name, cfunction_call_string, nr_args, arg_names );

end );

InstallGlobalFunction( JuliaSetGAPFuncAsJuliaObjFunc,
  function( func, name )
    JuliaSetGAPFuncAsJuliaObjFunc_internal( func, name );
end );

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
        JuliaSetGAPFuncAsJuliaObjFunc( current_func, current_name );
    od;

end );
