
##
##  When Julia loads GAP.jl, the module GAP is not yet available here;
##  we have to use __JULIAGAPMODULE instead.
##
BindGlobal("_JL_Array_GAPObj_1", JuliaEvalString("Array{__JULIAGAPMODULE.Obj,1}"));

BindGlobal("_JL_Dict_GAPObj", JuliaEvalString("Dict{Symbol,__JULIAGAPMODULE.Obj}"));

##
##  We want to use &GAP's function call syntax also for certain Julia objects
##  that are <E>not</E> functions, for example for types such as <C>fmpz</C>.
##  Note that also Julia supports this.
##
InstallMethod( CallFuncList,
    [ "IsJuliaObject", "IsList" ],
    function( julia_obj, args )
        args := GAPToJulia( _JL_Array_GAPObj_1, args );
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

    args := GAPToJulia( _JL_Array_GAPObj_1, args );
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
                                     GAPToJulia( _JL_Array_GAPObj_1, args ),
                                     GAPToJulia( _JL_Dict_GAPObj, arec ) ) );
