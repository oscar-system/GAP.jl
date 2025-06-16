#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

BindGlobal("_JL_Vector_Any", JuliaType( Julia.Vector, [ Julia.Any ] ));

BindGlobal("_JL_Dict_Any", JuliaType( Julia.Dict, [ Julia.Symbol, Julia.Any ] ));

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
