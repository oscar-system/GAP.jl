
BindGlobal("_JL_Vector_Any", JuliaEvalString("Vector{Any}"));

BindGlobal("_JL_Dict_Any", JuliaEvalString("Dict{Symbol,Any}"));

##
##  We want to use &GAP's function call syntax also for certain Julia objects
##  that are <E>not</E> functions, for example <C>ZZ</C>.
##  Note that also Julia supports this.
##
InstallMethod( CallFuncList,
    [ "IsJuliaObject", "IsList" ],
    function( julia_obj, args )
        args := GAPToJulia( _JL_Vector_Any, args, false );
        return Julia.Core._apply( julia_obj, args );
    end );

InstallMethod( CallFuncList,
    [ "IsJuliaWrapper", "IsList" ],
    function( julia_obj, args )
        return CallFuncList( JuliaPointer( julia_obj ), args );
    end );

InstallGlobalFunction( CallJuliaFunctionWithCatch,
    function( julia_obj, args )
    local res;

    args := GAPToJulia( _JL_Vector_Any, args, false );
    if IsFunction( julia_obj ) then
      julia_obj:= Julia.GAP.UnwrapJuliaFunc( julia_obj );
    fi;
    res:= Julia.GAP.call_with_catch( julia_obj, args );
    if res[1] then
      return rec( ok:= true, value:= res[2] );
    else
      return rec( ok:= false, value:= JuliaToGAP( IsString, res[2] ) );
    fi;
end );

InstallGlobalFunction( CallJuliaFunctionWithKeywordArguments,
    { julia_obj, args, arec } -> Julia.GAP.kwarg_wrapper( julia_obj,
                                     # non-recursive conversions
                                     GAPToJulia( _JL_Vector_Any, args, false ),
                                     GAPToJulia( _JL_Dict_Any, arec, false ) ) );
