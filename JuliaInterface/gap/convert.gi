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
    Error("<obj> is not a Julia integer");
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
    Error("<obj> is not a Julia integer or rational");
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
    Error("<obj> is not a Julia float");
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

InstallMethod(JuliaToGAP, [IsRecord, IsJuliaObject],
function(filter, obj)
    # TODO: support Julia Dict{Symbol,T}, resp. Dict{AbstractString,T}
    Error("TODO: convert to GAP record");
end);

# convert array and tuple to GAP lists
InstallMethod(JuliaToGAP, [IsList, IsJuliaObject],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.Array) or Julia.isa(obj, Julia.Base.Tuple) then
        return Julia.GAP.julia_to_gap(obj);
    fi;
    Error("<obj> is not a Julia array or typle");
end);

InstallMethod(JuliaToGAP, [IsRange, IsJuliaObject],
function(filter, obj)
    if Julia.isa(obj, Julia.Base.AbstractRange) then
        return Julia.GAP.julia_to_gap(obj);
    fi;
    Error("<obj> is not a Julia range");
end);

InstallMethod(JuliaToGAP, [IsBlist, IsJuliaObject],
function(filter, obj)
    # TODO: support Julia Array{Bool,1} and BitArray{1}
    Error("TODO: convert to GAP boolean list");
end);

InstallMethod(JuliaToGAP, [IsString, IsJuliaObject],
function(filter, obj)
    # TODO: also accept Symbol?
    if Julia.isa(obj, Julia.Base.AbstractString) then
        return Julia.GAP.julia_to_gap(obj);
    fi;
    Error("<obj> is not a Julia string");
end);


#
#
#

InstallMethod(GAPToJulia, [IsJuliaObject, IsObject],
function(type, obj)
    return Julia.GAP.gap_to_julia(type, obj);
end);

InstallOtherMethod(GAPToJulia, [IsObject],
function(obj)
    return Julia.GAP.gap_to_julia(obj);
end);
