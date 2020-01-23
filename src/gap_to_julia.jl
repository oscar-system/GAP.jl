## Converters
"""
    gap_to_julia(type,x,recursion_dict=nothing)

Tries to convert the GAP object `x` to an julia
object of type `type`.

The parameter `recursion_dict` is meant to preseve egality
of converted objects and should never be given by the user.
"""

## Default for conversion:
## Base case for conversion (least specialized method): Allow converting any
## Julia object x to type T, provided that the type of x is a subtype of T;
## otherwise, explicitly reject the conversion.
## As an example why this is useful, suppose you have a GAP list x (i.e., an
## object of type GapObj) containing a bunch of Julia tuples. Then this method
## enables conversion of that list to a Julia array of type Array{Tuple,1},
## like this:
##    gap_to_julia(Array{Tuple{Int64},1},xx)
## This works because first the gap_to_julia method with signature
## (::Type{Array{T,1}}, :: GapObj) is invoked, with T = Tuple{Int64}; this then
## invokes gap_to_julia recursively with signature (::Tuple{Int64},::Any),
## which ends up selecting the method below.

struct ConversionError <: Base.Exception
    obj
    jl_type
end

Base.showerror(io::IO, e::ConversionError) =
    print(io, "failed to convert GapObj to $(e.jl_type):\n $(e.obj)")

function Base.Int64(obj::GapObj)
    Globals.IsInt(obj) && return Int64(BigInt(obj))
    throw(ConversionError(obj, Int))
end

function Base.Float64(obj::GapObj)
    Globals.IsFloat(obj) && return ValueMacFloat(obj)::Float64
    throw(ConversionError(obj, Float64))
end

function Base.Rational{T}(obj::GapObj) where T <: Integer
    Globals.IsInt(obj) && return T(obj) // one(T)
    Globals.IsRat(obj) && return T(Globals.NumeratorRat(obj)) // T(Globals.DenominatorRat(obj))
    throw(ConversionError(obj, Rational{T}))
end

function Base.BigInt(x::GapObj)
    Globals.IsInt(x) || throw(ConversionError(x, BigInt))
    ## get size of GAP BigInt (in limbs), multiply
    ## by 64 to get bits
    size_limbs = ccall(:GAP_SizeInt, Cint, (Any,), x)
    size = abs(size_limbs * sizeof(UInt) * 8)
    ## allocate new GMP
    new_bigint = Base.GMP.MPZ.realloc2(size)
    new_bigint.size = size_limbs
    ## Get limb address ptr
    addr = ccall(:GAP_AddrInt, Ptr{UInt}, (Any,), x)
    ## Copy limbs
    unsafe_copyto!(new_bigint.d, addr, abs(size_limbs))
    return new_bigint::BigInt
end

function Base.big(obj::GapObj) # very much type unstable
    Globals.IsFloat(obj) && return BigFloat(Float64(obj))
    Globals.IsInt(obj) && return BigInt(obj)
    Globals.IsRat(obj) && return Rational{BigInt}(obj)
    throw(ConversionError(obj, "any of BigFloat, BigInt or Rational{BigInt}"))
end

# Base.convert(::Type{T}, x::GapObj) where T = T(x)
# Base.convert(::Type{Any}, x::GapObj) = x

(::Type{T})(obj::GapObj) where T<:Signed = T(Int64(obj))
(::Type{T})(obj::GapObj) where T<:Unsigned = T(Int64(obj))
(::Type{T})(obj::GapObj) where T<:Base.IEEEFloat = T(Float64(obj))
Base.BigFloat(obj::GapObj) = BigFloat(Float64(obj))

## Chars
function Base.Cuchar(obj::GapObj)
    Globals.IsChar(obj) && return Cuchar(Globals.INT_CHAR(obj))
    throw(ConversionError(obj, Cuchar))
end

## Strings and symbols
function Base.String(obj::GapObj)
    Globals.IsStringRep(obj) && return CSTR_STRING(obj)
    throw(ConversionError(obj, String))
end
(::Type{S})(obj::GapObj) where S<:AbstractString = S(String(obj))
Core.Symbol(obj::GapObj) = Symbol(String(obj))

## Convert GAP string to Array{UInt8,1}
function Vector{UInt8}(obj::GapObj)
    ## convert strings to uint8 lists, if requested
    if Globals.IsStringRep(obj)
        array = UNSAFE_CSTR_STRING(obj)
        return deepcopy(array)
    end
    Globals.IsList(obj) && return [UInt8(obj[i]) for i in 1:length(obj)]
    throw(ConversionError(obj, Vector{UInt8}))
end

function guess_type(obj::GapObj) # TODO
    Globals.IsList(obj) && return Vector{guess_type(first(obj))}
    Globals.IsRecord(obj) && return Dict{Symbol, Any}
    # (...) list of singleton types here
    return Any
end
guess_type(::T) where T = T

## Arrays
function Base.Vector(obj::GapObj, recursion_dict=IdDict())
    Globals.IsList(obj) || throw(ConversionError(obj, Vector))
    T = Union{(guess_type(obj[i]) for i in 1:length(obj))...}
    return Vector{T}(obj, recursion_dict)
end

function Base.Matrix(obj::GapObj, recursion_dict=IdDict())
    Globals.IsList(obj) || throw(ConversionError(obj, Vector))
    f = first(obj)
    Globals.IsList(f)  || throw(ConversionError(obj, Vector))
    T = guess_type(f)
    return Matrix{T}(obj, recursion_dict)
end

# shallow layer for recursion:
_gap_to_julia(::Type, obj, recursion_dict) = obj
_gap_to_julia(::Type{T}, obj::GapObj, recursion_dict) where T =
    T(obj, recursion_dict)
_gap_to_julia(::Type{Any}, obj::GapObj, recursion_dict) = gap_to_julia(obj)

function Base.Vector{T}(obj::GapObj, recursion_dict=IdDict()) where T
    Globals.IsList(obj) || throw(ConversionError(obj, Vector{T}))

    if !haskey(recursion_dict, obj)
        new_array = Vector{T}(undef, length(obj))
        for i in 1:length(obj)
            current_obj = ElmList(obj, i)
            # should return 'missing' for holes in the list
            new_array[i] = get!(recursion_dict, current_obj,
                _gap_to_julia(T, current_obj, recursion_dict))
        end
        recursion_dict[obj] = new_array
    end
    return recursion_dict[obj]
end

## Matrix / list-of-lists
function Base.Matrix{T}(obj::GapObj, recursion_dict=IdDict()) where T
    Globals.IsList(obj) || throw(ConversionError(obj, Matrix{T}))
    Globals.IsList(first(obj)) || throw(ConversionError(obj, Matrix{T}))

    if !haskey(recursion_dict, obj)
        nrows = length(obj)
        ncols = iszero(nrows) ? 0 : length(first(obj))
        new_array = Matrix{T}(undef, nrows, ncols)
        for i in 1:nrows
            for j in 1:ncols
                current_obj = ElmList(ElmList(obj, i), j)
                new_array[i, j] = get!(recursion_dict, current_obj,
                    _gap_to_julia(T, current_obj, recursion_dict))
            end
        end
        recursion_dict[obj] = new_array
    end
    return recursion_dict[obj]
end

## Tuples
function (::Type{T})(obj::GapObj, recursion_dict = IdDict() ) where T <: Tuple
    Globals.IsList(obj) || throw(ConversionError(obj, T))
    if !haskey(recursion_dict, obj)
        recursion_dict[obj] = T(Any[_gap_to_julia(S, o, recursion_dict) for (S, o) in zip(T.parameters, obj)])
    end
    return recursion_dict[obj]
end

function Base.Tuple(obj::GapObj, recursion_dict=IdDict())
    Globals.IsList(obj) || throw(ConversionError(obj, T))
    if !haskey(recursion_dict, obj)
        recursion_dict[obj] = Tuple(collect(obj))
    end
    return recursion_dict[obj]
end

## Dictionaries
function Base.Dict{Symbol,T}(obj::GapObj, recursion_dict=IdDict()) where {T}
    Globals.IsRecord(obj) || throw(ConversionError(obj, Dict{Symbol, T}))
    if !haskey(recursion_dict, obj)
        names = Globals.RecNames(obj)
        names_list = [Symbol(n) for n in names]
        dict = Dict{Symbol,T}()
        for key in names_list
            current_obj = getproperty(obj, key)
            dict[key] = get!(recursion_dict, current_obj,
                _gap_to_julia(T, current_obj, recursion_dict))
        end
        recursion_dict[obj] = dict
    end

    return recursion_dict[obj]
end

## TODO: BitArray <-> blist; ranges; ...

## Generic conversions

function gap_to_julia(x::GapObj)
    Globals.IsInt(x) && return BigInt(x)
    Globals.IsRat(x) && return Rational{BigInt}(x)
    Globals.IsFloat(x) && return Float64(x)
    Globals.IsChar(x) && return Cuchar(x)
    Globals.IsString(x) && return String(x)
    Globals.IsList(x) && return Vector(x)
    Globals.IsRecord(x) && return Dict{Symbol,Any}(x)
    throw(ConversionError(x, "any known type"))
end

# hacking GAP into running state
gap_to_julia(x) = x
gap_to_julia(::Type{T}, x) where T = T(x)
gap_to_julia(::Type{Any}, x) where T = x
gap_to_julia(::Type{<:Obj}, x) = x
