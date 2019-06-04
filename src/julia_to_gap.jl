## Converters
"""
    julia_to_gap(input, recursive::Val{Recursive} = Val(false), recursion_dict = IdDict())

Converts a julia object `input`` to an appropriate GAP object.
If recursive is set to `Val(true)`, recursive conversions on
arrays, tuples, and dictionaries is performed.

The input `recursive_data` should never be set by the user, it is meant to keep egality
of input data, by converting egal data to identical objects in GAP.
"""


## Default
julia_to_gap(x::GapObj) = x
julia_to_gap(x::FFE) = x
julia_to_gap(x::Bool) = x


## Integers
julia_to_gap(x::Int128) = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
julia_to_gap(x::Int64)  = x
julia_to_gap(x::Int32)  = Int64(x)
julia_to_gap(x::Int16)  = Int64(x)
julia_to_gap(x::Int8)   = Int64(x)

## Unsigned Integers
julia_to_gap(x::UInt128) = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
julia_to_gap(x::UInt64)  = MakeObjInt(BigInt(x)) # FIXME: inefficient hack
julia_to_gap(x::UInt32)  = Int64(x)
julia_to_gap(x::UInt16)  = Int64(x)
julia_to_gap(x::UInt8)   = Int64(x)

## BigInts
julia_to_gap(x::BigInt) = MakeObjInt(x)

## Rationals
function julia_to_gap(x::Rational{T}) where T <: Integer
    denom_julia = denominator(x)
    numer_julia = numerator(x)
    if denom_julia == 0
        if numer_julia >= 0
            return Globals.infinity
        else
            return -Globals.infinity
        end
    end
    numer = julia_to_gap(numer_julia)
    denom = julia_to_gap(denom_julia)
    return Globals.QUO(numer,denom)
end

## Floats
julia_to_gap(x::Float64) = NEW_MACFLOAT(x)
julia_to_gap(x::Float32) = NEW_MACFLOAT(Float64(x))
julia_to_gap(x::Float16) = NEW_MACFLOAT(Float64(x))

## Chars
julia_to_gap(x::Char) = CharWithValue(Cuchar(x)) 

## Strings and symbols
julia_to_gap(x::AbstractString) = MakeString(x)
julia_to_gap(x::Symbol) = MakeString(string(x))

## Generic caller for optional arguments
julia_to_gap(obj::Any, recursive, recursion_dict ) = julia_to_gap(obj)

## Arrays
function julia_to_gap(obj::Array{T,1}, recursive::Val{Recursive}=Val(false), recursion_dict = IdDict()) where Recursive where T
    len = length(obj)
    ret_val = NewPlist(len)
    if Recursive
        recursion_dict[obj] = ret_val
    end
    for i in 1:len
        x = obj[i]
        if x == nothing
            continue
        end
        if Recursive
#=
            # It would be much nicer to write this, but we cannot in Julia 1.x, see
            # https://github.com/JuliaLang/julia/issues/30165
            x = get!(recursion_dict, x) do
                julia_to_gap(x, recursive, recursion_dict)
            end
=#
            if haskey(recursion_dict,x)
                x = recursion_dict[x]
            else
                x = recursion_dict[x] = julia_to_gap(x, recursive, recursion_dict)
            end
        end
        ret_val[i] = x
    end
    return ret_val
end

## Convert two dimensional arrays
function julia_to_gap(obj::Array{T,2}, recursive::Val{Recursive}=Val(false), recursion_dict = IdDict()) where Recursive where T
    (rows,cols) = size(obj)
    if haskey(recursion_dict, obj)
        return recursion_dict[obj]
    end
    ret_val = NewPlist(rows)
    if Recursive
        recursion_dict[obj] = ret_val
    end
    for i in 1:rows
        ret_val[i] = julia_to_gap(obj[i,:],recursive,recursion_dict)
    end
    return ret_val
end

## Tuples
function julia_to_gap(obj::Tuple, recursive::Val{Recursive}=Val(false), recursion_dict = IdDict()) where Recursive
    array = collect(Any, obj)
    return julia_to_gap(array, recursive, recursion_dict)
end

## Dictionaries
function julia_to_gap(obj::Dict{T,S}, recursive::Val{Recursive}=Val(false), recursion_dict = IdDict()) where Recursive where S where T <: Union{Symbol,AbstractString}

    # FIXME: add a dedicated method for creating an empty GAP record
    record = EvalString("rec()")
    if Recursive
        recursion_dict[obj] = record
    end
    for (x,y) in obj
        x = Globals.RNamObj(MakeString(string(x)))
        if Recursive
#=
            # It would be much nicer to write this, but we cannot in Julia 1.x, see
            # https://github.com/JuliaLang/julia/issues/30165
            y = get!(recursion_dict, y) do
                julia_to_gap(y, recursive, recursion_dict)
            end
=#
            if haskey(recursion_dict,y)
                y = recursion_dict[y]
            else
                y = recursion_dict[y] = julia_to_gap(y, recursive, recursion_dict)
            end
        end
        Globals.ASS_REC(record, x, y)
    end

    return record
end

julia_to_gap(func::Function) = NewJuliaFunc(func)


## TODO: BitArray <-> blist; ranges; ...
