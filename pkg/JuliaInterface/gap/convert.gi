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

# convert Julia Integer subtypes like Int8, Int16, ... UInt128, BigInt
InstallMethod(JuliaToGAP, ["IsInt", "IsJuliaObject"],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.Integer) then
        return GAP_jl.GapObj(obj);
    fi;
    Error("<obj> must be a Julia integer");
end);

# handle immediate integers as well
InstallMethod(JuliaToGAP, ["IsInt", "IsInt"],
function(filter, obj)
    return obj;
end);

InstallMethod(JuliaToGAP, ["IsRat", "IsJuliaObject"],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.Integer) or Julia.isa(obj, Julia.Base.Rational) then
        return GAP_jl.GapObj(obj);
    fi;
    Error("<obj> must be a Julia integer or rational");
end);

# No default conversion for IsCyc

# immediate FFEs are auto-converted, so nothing to do here
InstallMethod(JuliaToGAP, ["IsFFE", "IsFFE"],
function(filter, obj)
    return obj;
end);

InstallMethod(JuliaToGAP, ["IsFloat", "IsJuliaObject"],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.AbstractFloat) then
        return GAP_jl.GapObj(obj);
    fi;
    Error("<obj> must be a Julia float");
end);

# No default conversion for T_PERM, T_TRANS, T_PPERM

# Julia booleans true and false are auto-converted to GAP true and false, so nothing to do here
InstallMethod(JuliaToGAP, ["IsBool", "IsBool"],
function(filter, obj)
    return obj;
end);

InstallMethod(JuliaToGAP, ["IsChar", "IsJuliaObject"],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.Char) then
        return GAP_jl.GapObj(obj);
    elif Julia.isa(obj, Julia.Base.Int8) or
         Julia.isa(obj, Julia.Base.UInt8) then
        return CharInt( GAP_jl.GapObj(obj) );
    fi;

    Error("<obj> must be a Julia Char or Int8 or UInt8");
end);

BindGlobal("_JL_Dict_Symbol", JuliaType( Julia.Dict, [ Julia.Symbol ] ));
BindGlobal("_JL_Dict_AbstractString", JuliaType( Julia.Dict, [ Julia.AbstractString ] ));

InstallMethod(JuliaToGAP, ["IsRecord", "IsJuliaObject"],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, ["IsRecord", "IsJuliaObject", "IsBool"],
function(filter, obj, recursive)
    if Julia.isa(obj, _JL_Dict_Symbol) or Julia.isa(obj, _JL_Dict_AbstractString) then
        return GAP_jl.Obj(obj, recursive);
    fi;
    Error("<obj> must be a Julia Dict{Symbol} or Dict{AbstractString}");
end);

InstallMethod(JuliaToGAP, ["IsList", "IsJuliaObject"],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, ["IsList", "IsJuliaObject", "IsBool"],
function(filter, obj, recursive)
    if Julia.isa(obj, Julia.Base.Array) or Julia.isa(obj, Julia.Base.Tuple)
       or Julia.isa(obj, Julia.Base.AbstractRange) then
        return GAP_jl.Obj(obj, recursive);
    fi;
    Error("<obj> must be a Julia array or tuple or range");
end);


InstallMethod(JuliaToGAP, ["IsRange", "IsJuliaObject"],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, ["IsRange", "IsJuliaObject", "IsBool"],
function(filter, obj, recursive)
    if Julia.isa(obj, Julia.Base.AbstractRange) then
        return GAP_jl.Obj(obj, recursive);
    fi;
    Error("<obj> must be a Julia range");
end);

BindGlobal("_JL_Vector_Bool", JuliaType( Julia.Vector, [ Julia.Bool ] ));
BindGlobal("_JL_BitVector", Julia.BitVector);

InstallMethod(JuliaToGAP, ["IsBlist", "IsJuliaObject"],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, ["IsBlist", "IsJuliaObject", "IsBool"],
function(filter, obj, recursive)
    if Julia.isa(obj, _JL_Vector_Bool) or Julia.isa(obj, _JL_BitVector) then
        return GAP_jl.Obj(obj, recursive);
    fi;
    Error("<obj> must be a Julia Vector{Bool} or BitVector");
end);

InstallMethod(JuliaToGAP, ["IsString", "IsJuliaObject"],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.AbstractString) or
       Julia.isa(obj, Julia.Base.Symbol) then
        return GAP_jl.GapObj(obj);
    fi;
    Error("<obj> must be a Julia string or symbol");
end);

InstallGlobalFunction("GAPToJulia", GAP_jl._gap_to_julia );
