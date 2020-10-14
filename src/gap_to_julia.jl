
## Show a specific error on conversion failure.
struct ConversionError <: Base.Exception
    obj::Any
    jl_type::Any
end

Base.showerror(io::IO, e::ConversionError) =
    print(io, "failed to convert GapObj to $(e.jl_type):\n $(e.obj)")


## Conversion from GAP to Julia
"""
    gap_to_julia(type, x, recursion_dict=nothing; recursive=true)

Try to convert the object `x` to a Julia object of type `type`.
If `x` is a `GAP.GapObj` then the conversion rules are defined in the
manual of the GAP package JuliaInterface.
If `x` is another `GAP.Obj` (for example a `Int64`) then the result is
defined in Julia by `type`.

The parameter `recursion_dict` is meant to preseve the identity
of converted subobjects and should never be given by the user.

For GAP lists and records, it makes sense to convert also the subobjects
recursively, or to keep the subobjects as they are;
the behaviour is controlled by `recursive`, which can be `true` or `false`.

# Examples
```jldoctest
julia> GAP.gap_to_julia( GAP.evalstr( "1/3" ) )
1//3

julia> GAP.gap_to_julia( GAP.evalstr( "\\"abc\\"" ) )
"abc"

julia> val = GAP.evalstr( "[ [ 1, 2 ], [ 3, 4 ] ]" );

julia> GAP.gap_to_julia( val )
2-element Array{Any,1}:
 Any[1, 2]
 Any[3, 4]

julia> GAP.gap_to_julia( val, recursive = false )
2-element Array{Any,1}:
 GAP: [ 1, 2 ]
 GAP: [ 3, 4 ]

```
"""
function gap_to_julia(t::T, x::Any) where {T<:Type}
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
    if !(typeof(x) <: t)
        throw(ErrorException(
            "Don't know how to convert value of type " *
            string(typeof(x)) *
            " to type " *
            string(t),
        ))
    end
    return x
end

## Switch recursion on by default.
## If no method for the given arguments supports 'recursion_dict'
## then assume that it is not needed.
gap_to_julia(type_obj, obj, recursion_dict; recursive = true) =
    gap_to_julia(type_obj, obj; recursive = recursive)
gap_to_julia(type_obj, obj; recursive = true) = gap_to_julia(type_obj, obj)

## Default
gap_to_julia(::Type{Any}, x::GapObj; recursive = true) =
    gap_to_julia(x; recursive = recursive)
gap_to_julia(::Type{Any}, x::Any) = x
gap_to_julia(::T, x::Nothing) where {T<:Type} = nothing
gap_to_julia(::Type{Any}, x::Nothing) = nothing

## Handle "conversion" to GAP.Obj and GAP.GapObj (may occur in recursions).
gap_to_julia(::Type{Obj}, x::Obj) = x
gap_to_julia(::Type{GapObj}, x::GapObj) = x

## Integers
gap_to_julia(::Type{T}, x::Int64) where {T<:Integer} = trunc(T, x)

function gap_to_julia(::Type{T}, obj::GapObj) where {T<:Integer}
    Globals.IsInt(obj) && return T(BigInt(obj))
    throw(ConversionError(obj, T))
end

function gap_to_julia(::Type{BigInt}, x::GapObj)
    Globals.IsInt(x) || throw(ConversionError(x, BigInt))
    ## get size of GAP BigInt (in limbs), multiply
    ## by 64 to get bits
    size_limbs = @lock_noexcept ccall(:GAP_SizeInt, Cint, (Any,), x)
    size = abs(size_limbs * sizeof(UInt) * 8)
    ## allocate new GMP
    new_bigint = Base.GMP.MPZ.realloc2(size)
    new_bigint.size = size_limbs
    ## Get limb address ptr
    addr = @lock_noexcept ccall(:GAP_AddrInt, Ptr{UInt}, (Any,), x)
    ## Copy limbs
    unsafe_copyto!(new_bigint.d, addr, abs(size_limbs))
    return new_bigint
end

## Rationals
function gap_to_julia(::Type{Rational{T}}, x::Int64) where {T<:Integer}
    numerator = gap_to_julia(T, x)
    return numerator // T(1)
end

function gap_to_julia(::Type{Rational{T}}, x::GapObj) where {T<:Integer}
    Globals.IsInt(x) && return gap_to_julia(T, x) // T(1)
    !Globals.IsRat(x) && throw(ConversionError(x, Rational{T}))
    numer = Globals.NumeratorRat(x)
    denom = Globals.DenominatorRat(x)
    return gap_to_julia(T, numer) // gap_to_julia(T, denom)
end

## Floats
function gap_to_julia(::Type{Float64}, obj::GapObj)
    Globals.IsIEEE754FloatRep(obj) && return ValueMacFloat(obj)::Float64
    throw(ConversionError(obj, Float64))
end

gap_to_julia(::Type{T}, obj::GapObj) where {T<:AbstractFloat} =
    T(gap_to_julia(Float64, obj))

## Chars
function gap_to_julia(::Type{Char}, obj::GapObj)
    Globals.IsChar(obj) && return Char(Globals.INT_CHAR(obj))
    throw(ConversionError(obj, Char))
end

function gap_to_julia(::Type{Cuchar}, obj::GapObj)
    Globals.IsChar(obj) && return trunc(Cuchar, Globals.INT_CHAR(obj))
    throw(ConversionError(obj, Cuchar))
end

## Strings
function gap_to_julia(::Type{String}, obj::GapObj)
    Globals.IsStringRep(obj) && return CSTR_STRING(obj)
    Globals.IsString(obj) && return CSTR_STRING(Globals.CopyToStringRep(obj))
    throw(ConversionError(obj, String))
end
gap_to_julia(::Type{T}, obj::GapObj) where {T<:AbstractString} =
    convert(T, gap_to_julia(String, obj))

## Symbols
gap_to_julia(::Type{Symbol}, obj::GapObj) = Symbol(gap_to_julia(String, obj))

## Convert GAP string to Vector{UInt8} (==Array{UInt8,1})
function gap_to_julia(::Type{Vector{UInt8}}, obj::GapObj)
    Globals.IsStringRep(obj) && return CSTR_STRING_AS_ARRAY(obj)
    Globals.IsList(obj) && return [gap_to_julia(UInt8, obj[i]) for i = 1:length(obj)]
    throw(ConversionError(obj, Vector{UInt8}))
end

## BitArrays
function gap_to_julia(::Type{BitArray{1}}, obj::GapObj)
    !Globals.IsBlist(obj) && throw(ConversionError(obj, BitArray{1}))
    len = Globals.Length(obj)
    result = BitArray(undef, len)
    for i = 1:len
        result[i] = obj[i]
    end
    return result
end

## Vectors
function gap_to_julia(
    ::Type{Vector{T}},
    obj::GapObj,
    recursion_dict = IdDict();
    recursive = true,
) where {T}
    if Globals.IsList(obj)
        elmlist = ElmList  # returns 'nothing' for holes in the list
    elseif Globals.IsVectorObj(obj)
        # vector objects aren't lists,
        # but the function for accessing entries is `ELM_LIST`
        elmlist = Globals.ELM_LIST
    else
        throw(ConversionError(obj, Vector{T}))
    end

    if !haskey(recursion_dict, obj)
        len_list = length(obj)
        new_array = Vector{T}(undef, len_list)
        recursion_dict[obj] = new_array
        for i = 1:len_list
            current_obj = elmlist(obj, i)
            if recursive
                new_array[i] = get!(recursion_dict, current_obj) do
                    gap_to_julia(T, current_obj, recursion_dict; recursive = true)
                end
            else
                new_array[i] = current_obj
            end
        end
    end
    return recursion_dict[obj]
end

## Matrices or lists of lists
function gap_to_julia(
    type::Type{Matrix{T}},
    obj::GapObj,
    recursion_dict = IdDict();
    recursive = true,
) where {T}
    if haskey(recursion_dict, obj)
        return recursion_dict[obj]
    end
    if Globals.IsMatrixObj(obj)
        nrows = Globals.NumberRows(obj)
        ncols = Globals.NumberColumns(obj)
    elseif Globals.IsList(obj)
        nrows = length(obj)
        ncols = nrows == 0 ? 0 : length(obj[1])
    else
        throw(ConversionError(obj, type))
    end

    elm = Globals.MatElm
    new_array = type(undef, nrows, ncols)
    if recursive
        recursion_dict[obj] = new_array
    end
    for i = 1:nrows
        for j = 1:ncols
            current_obj = elm(obj, i, j)
            if recursive
                new_array[i, j] = get!(recursion_dict, current_obj) do
                    gap_to_julia(T, current_obj, recursion_dict; recursive = true)
                end
            else
                new_array[i, j] = current_obj
            end
        end
    end
    return new_array
end

## Tuples
## Note that the tuple type prescribes the types of the entries,
## thus we have to convert at least also the next layer,
## even if `recursive == false` holds.
function gap_to_julia(
    ::Type{T},
    obj::GapObj,
    recursion_dict = IdDict();
    recursive = true,
) where {T<:Tuple}
    !Globals.IsList(obj) && throw(ConversionError(obj, T))
    if !haskey(recursion_dict, obj)
        parameters = T.parameters
        len = length(parameters)
        Globals.Length(obj) == len ||
            throw(ArgumentError("length of $obj does not match type $T"))
        list = [
            gap_to_julia(parameters[i], obj[i], recursion_dict; recursive = recursive)
            for i = 1:len
        ]
        recursion_dict[obj] = T(list)
    end
    return recursion_dict[obj]
end

## Ranges
function gap_to_julia(::Type{T}, obj::GapObj) where {T<:UnitRange}
    !Globals.IsRange(obj) && throw(ConversionError(obj, T))
    len = Globals.Length(obj)
    if len == 0
        # construct an empty UnitRange object
        result = 1:0
    elseif len == 1
        result = obj[1]:obj[1]
    elseif obj[2] != obj[1] + 1
        throw(ArgumentError("step width of first argument is not 1"))
    else
        result = obj[1]:obj[len]
    end

    return T(result)
end

function gap_to_julia(::Type{T}, obj::GapObj) where {T<:StepRange}
    !Globals.IsRange(obj) && throw(ConversionError(obj, T))
    len = Globals.Length(obj)
    if len == 0
        # construct an empty StepRange object
        start = 1
        step = 1
        stop = 0
    elseif len == 1
        start = obj[1]
        step = 1
        stop = obj[1]
    else
        start = obj[1]
        step = obj[2]-obj[1]
        stop = obj[len]
    end

    # Julia does not support `StepRange(obj)` (but `StepRange{S,T}(obj)`),
    # and also `T(start, step, stop)` does not work for each `T` in question,
    # but we can always use `convert`.
    return convert(T, start:step:stop)
end

## Dictionaries
function gap_to_julia(
    ::Type{Dict{Symbol,T}},
    obj::GapObj,
    recursion_dict = IdDict();
    recursive = true,
) where {T}
    !Globals.IsRecord(obj) && throw(ConversionError(obj, Dict{Symbol,T}))
    if !haskey(recursion_dict, obj)
        names = Globals.RecNames(obj)
        names_list = Vector{Symbol}(names)
        dict = Dict{Symbol,T}()
        recursion_dict[obj] = dict
        for key in names_list
            current_obj = getproperty(obj, key)
            if recursive
                dict[key] = get!(recursion_dict, current_obj) do
                    gap_to_julia(T, current_obj, recursion_dict; recursive = true)
                end
            else
                dict[key] = current_obj
            end
        end
    end
    return recursion_dict[obj]
end

## Generic conversions
gap_to_julia(x::Any) = x

function gap_to_julia(x::GapObj; recursive = true)
    Globals.IsInt(x) && return gap_to_julia(BigInt, x)
    Globals.IsRat(x) && return gap_to_julia(Rational{BigInt}, x)
    Globals.IsFloat(x) && return gap_to_julia(Float64, x)
    Globals.IsChar(x) && return gap_to_julia(Cuchar, x)
    # Do not choose this conversion for other lists in 'IsString'.
    Globals.IsStringRep(x) && return gap_to_julia(AbstractString, x)
    # Do not choose this conversion for other lists in 'IsRange'.
    Globals.IsRangeRep(x) && return gap_to_julia(StepRange{Int64,Int64}, x)
    # Do not choose this conversion for other lists in 'IsBlist'.
    Globals.IsBlistRep(x) && return gap_to_julia(BitArray{1}, x)
    Globals.IsList(x) && return gap_to_julia(Vector{Any}, x; recursive = recursive)
    Globals.IsMatrixObj(x) && return gap_to_julia(Array{Any,2}, x; recursive = recursive)
    Globals.IsVectorObj(x) && return gap_to_julia(Vector{Any}, x; recursive = recursive)
    Globals.IsRecord(x) && return gap_to_julia(Dict{Symbol,Any}, x; recursive = recursive)
    throw(ConversionError(x, "any known type"))
end

## for the GAP function GAPToJulia:
## turning arguments into keyword arguments is easier in Julia than in GAP
_gap_to_julia(x::Obj) = gap_to_julia(x)
_gap_to_julia(x::Obj, recursive::Bool) = gap_to_julia(x; recursive = recursive)
_gap_to_julia(::Type{T}, x::Obj) where {T} = gap_to_julia(T, x)
_gap_to_julia(::Type{T}, x::Obj, recursive::Bool) where {T} =
    gap_to_julia(T, x; recursive = recursive)
