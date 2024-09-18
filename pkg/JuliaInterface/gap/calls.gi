
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
        return Julia.GAP._apply( julia_obj, args );
    end );

InstallMethod( CallFuncList,
    [ "IsJuliaWrapper", "IsList" ],
    function( julia_obj, args )
        return CallFuncList( JuliaPointer( julia_obj ), args );
    end );

InstallGlobalFunction( CallJuliaFunctionWithCatch,
    function( julia_obj, args, arec... )
    local res;

    args := GAPToJulia( _JL_Vector_Any, args, false );
    if IsFunction( julia_obj ) then
      julia_obj:= Julia.GAP.UnwrapJuliaFunc( julia_obj );
    fi;
    if Length( arec ) = 0 then
      res:= Julia.GAP.call_with_catch( julia_obj, args );
    elif Length( arec ) = 1 and IsRecord( arec[1] ) then
      arec := GAPToJulia( _JL_Dict_Any, arec[1], false );
      res:= Julia.GAP.call_with_catch( julia_obj, args, arec );
    else
      Error( "usage: CallJuliaFunctionWithCatch( <julia_obj>, <args>, <arec>" );
    fi;
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
