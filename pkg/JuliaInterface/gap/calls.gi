#############################################################################
##
##  JuliaInterface package
##
#############################################################################

BindGlobal("_JL_Vector_Any", JuliaEvalString("Vector{Any}"));

BindGlobal("_JL_Dict_Any", JuliaEvalString("Dict{Symbol,Any}"));

##
##  We want to use &GAP's function call syntax also for certain Julia objects
##  that are <E>not</E> functions, for example for types such as <C>String</C>.
##  Note that also Julia supports this.
##
InstallMethod( CallFuncList,
    [ "IsJuliaObject", "IsList" ],
    function( julia_obj, args )
        args := GAPToJulia( _JL_Vector_Any, args, false );
        return GAP_jl._apply( julia_obj, args );
    end );

InstallMethod( CallFuncList,
    [ "IsJuliaWrapper", "IsList" ],
    function( julia_obj, args )
        return CallFuncList( JuliaPointer( julia_obj ), args );
    end );

InstallGlobalFunction( CallJuliaFunctionWithCatch,
    function( julia_obj, args, kwargs... )
    local res;

    args := GAPToJulia( _JL_Vector_Any, args, false );
    if IsFunction( julia_obj ) then
      julia_obj:= GAP_jl.UnwrapJuliaFunc( julia_obj );
    fi;
    if Length( kwargs ) = 0 then
      res:= GAP_jl.call_with_catch( julia_obj, args );
    elif Length( kwargs ) = 1 and IsRecord( kwargs[1] ) then
      kwargs := GAPToJulia( _JL_Dict_Any, kwargs[1], false );
      res:= GAP_jl.call_with_catch( julia_obj, args, kwargs );
    else
      Error( "usage: CallJuliaFunctionWithCatch( <julia_obj>, <args>[, <kwargs>]" );
    fi;
    if res[1] then
      return rec( ok:= true, value:= res[2] );
    else
      return rec( ok:= false, value:= JuliaToGAP( IsString, res[2] ) );
    fi;
end );

InstallGlobalFunction( CallJuliaFunctionWithKeywordArguments,
    { julia_obj, args, kwargs } -> GAP_jl.kwarg_wrapper( julia_obj,
                                     # non-recursive conversions
                                     GAPToJulia( _JL_Vector_Any, args, false ),
                                     GAPToJulia( _JL_Dict_Any, kwargs, false ) ) );
