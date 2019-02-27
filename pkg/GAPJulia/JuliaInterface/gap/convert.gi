#############################################################################
##
##  JuliaInterface package
##
#############################################################################

# convert Julia Integer subtypes like Int8, Int16, ... UInt64, BigInt
InstallMethod(JuliaToGAP, [IsInt, IsJuliaObject],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.Integer) then
        return Julia.GAP.julia_to_gap(obj);
    fi;
    Error("<obj> must be a Julia integer");
end);

# handle immediate integers as well
InstallMethod(JuliaToGAP, [IsInt, IsInt],
function(filter, obj)
    return obj;
end);

InstallMethod(JuliaToGAP, [IsRat, IsJuliaObject],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.Integer) or Julia.isa(obj, Julia.Base.Rational) then
        return Julia.GAP.julia_to_gap(obj);
    fi;
    Error("<obj> must be a Julia integer or rational");
end);

# No default conversion for IsCyc

# immediate FFEs are auto-converted, so nothing to do here
InstallMethod(JuliaToGAP, [IsFFE, IsFFE],
function(filter, obj)
    return obj;
end);

InstallMethod(JuliaToGAP, [IsFloat, IsJuliaObject],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.AbstractFloat) then
        return Julia.GAP.julia_to_gap(obj);
    fi;
    Error("<obj> must be a Julia float");
end);

# No default conversion for T_PERM, T_TRANS, T_PPERM

# Julia booleans true and false are auto-converted to GAP true and false, so nothing to do here
InstallMethod(JuliaToGAP, [IsBool, IsBool],
function(filter, obj)
    return obj;
end);

InstallMethod(JuliaToGAP, [IsChar, IsJuliaObject],
function(filter, obj)
    # TODO: support Julia Int8 and UInt8, but *not* Char (which is a 32bit type)
    # convert to GAP using CHAR_SINT resp. CHAR_INT
    Error("TODO: convert to GAP char");
end);

BindGlobal("_JL_Dict_Symbol", JuliaEvalString("Dict{Symbol}"));
BindGlobal("_JL_Dict_AbstractString", JuliaEvalString("Dict{AbstractString}"));
BindGlobal("_JL_VAL_TRUE", JuliaEvalString("Val(true)"));

InstallMethod(JuliaToGAP, [IsRecord, IsJuliaObject],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, [IsRecord, IsJuliaObject, IsBool],
function(filter, obj, recursive)
    if Julia.isa(obj, _JL_Dict_Symbol) or Julia.isa(obj, _JL_Dict_AbstractString) then
        if recursive then
            return Julia.GAP.julia_to_gap(obj,_JL_VAL_TRUE);
        else
            return Julia.GAP.julia_to_gap(obj);
        fi;
    fi;
    Error("<obj> must be a Julia Dict{Symbol} or Dict{AbstractString}");
end);

InstallMethod(JuliaToGAP, [IsList, IsJuliaObject],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, [IsList, IsJuliaObject, IsBool],
function(filter, obj, recursive)
    if Julia.isa(obj, Julia.Base.Array) or Julia.isa(obj, Julia.Base.Tuple) then
        if recursive then
            return Julia.GAP.julia_to_gap(obj,_JL_VAL_TRUE);
        else
            return Julia.GAP.julia_to_gap(obj);
        fi;
    fi;
    Error("<obj> must be a Julia array or tuple");
end);


InstallMethod(JuliaToGAP, [IsRange, IsJuliaObject],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, [IsRange, IsJuliaObject, IsBool],
function(filter, obj, recursive)
    if Julia.isa(obj, Julia.Base.AbstractRange) then
        if recursive then
            return Julia.GAP.julia_to_gap(obj,_JL_VAL_TRUE);
        else
            return Julia.GAP.julia_to_gap(obj);
        fi;
    fi;
    Error("<obj> must be a Julia range");
end);

BindGlobal("_JL_Array_Bool_1", JuliaEvalString("Array{Bool,1}"));
BindGlobal("_JL_BitArray_1", JuliaEvalString("BitArray{1}"));

InstallMethod(JuliaToGAP, [IsBlist, IsJuliaObject],
    {filter,obj} -> JuliaToGAP(filter,obj,false) );

InstallMethod(JuliaToGAP, [IsBlist, IsJuliaObject, IsBool],
function(filter, obj, recursive)
    if Julia.isa(obj, _JL_Array_Bool_1) or Julia.isa(obj, _JL_BitArray_1) then
        if recursive then
            return Julia.GAP.julia_to_gap(obj,_JL_VAL_TRUE);
        else
            return Julia.GAP.julia_to_gap(obj);
        fi;
    fi;
    Error("<obj> must be a Julia Array{Bool,1} or BitArray{1}");
end);

InstallMethod(JuliaToGAP, [IsString, IsJuliaObject],
function(filter, obj)
    # TODO: also accept Symbol?
    if Julia.isa(obj, Julia.Base.AbstractString) then
        return Julia.GAP.julia_to_gap(obj);
    fi;
    Error("<obj> must be a Julia string");
end);


#
#
#

InstallGlobalFunction("GAPToJulia", JuliaFunction( "gap_to_julia", "__JULIAGAPMODULE" ) );
