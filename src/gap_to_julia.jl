
## Show a specific error on conversion failure.
struct ConversionError <: Base.Exception
    obj::Any
    jl_type::Any
end

Base.showerror(io::IO, e::ConversionError) =
    print(io, "failed to convert $(typeof(e.obj)) to $(e.jl_type):\n $(e.obj)")


## Conversion from GAP to Julia
"""
    gap_to_julia(type, x, recursion_dict=nothing; recursive::Bool=true)

Try to convert the object `x` to a Julia object of type `type`.
If `x` is a `GAP.GapObj` then the conversion rules are defined in the
manual of the GAP package JuliaInterface.
If `x` is another `GAP.Obj` (for example a `Int64`) then the result is
defined in Julia by `type`.

The parameter `recursion_dict` is used to preserve the identity
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

julia> val = GapObj([ 1 2 ; 3 4 ])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GAP.gap_to_julia( val )
2-element Vector{Any}:
 Any[1, 2]
 Any[3, 4]

julia> GAP.gap_to_julia( val, recursive = false )
2-element Vector{Any}:
 GAP: [ 1, 2 ]
 GAP: [ 3, 4 ]

julia> GAP.gap_to_julia( Vector{GapObj}, val )
2-element Vector{GapObj}:
 GAP: [ 1, 2 ]
 GAP: [ 3, 4 ]

julia> GAP.gap_to_julia( Matrix{Int}, val )
2×2 Matrix{Int64}:
 1  2
 3  4
```
"""
function gap_to_julia(t::T, x::Any) where {T<:Type}
    ## Default for conversion:
    ## Base case for conversion (least specialized method): Allow converting any
    ## Julia object x to type T, provided that the type of x is a subtype of T;
    ## otherwise, explicitly reject the conversion.
    ## As an example why this is useful, suppose you have a GAP list x (i.e., an
    ## object of type GapObj) containing a bunch of Julia tuples. Then this method
    ## enables conversion of that list to a Julia array of type Vector{Tuple},
    ## like this:
    ##    gap_to_julia(Vector{Tuple{Int64}},xx)
    ## This works because first the gap_to_julia method with signature
    ## (::Type{Vector{T}}, :: GapObj) is invoked, with T = Tuple{Int64}; this then
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
gap_to_julia(type_obj, obj, recursion_dict; recursive::Bool = true) =
    gap_to_julia(type_obj, obj; recursive = recursive)
gap_to_julia(type_obj, obj; recursive::Bool = true) = gap_to_julia(type_obj, obj)

## Default
gap_to_julia(::Type{Any}, x::GapObj; recursive::Bool = true) =
    gap_to_julia(x; recursive = recursive)
gap_to_julia(::Type{Any}, x::Any) = x
gap_to_julia(::T, x::Nothing) where {T<:Type} = nothing
gap_to_julia(::Type{Any}, x::Nothing) = nothing

## Handle "conversion" to GAP.Obj and GAP.GapObj (may occur in recursions).
gap_to_julia(::Type{Obj}, x::Obj) = x
gap_to_julia(::Type{GapObj}, x::GapObj) = x

## Integers
gap_to_julia(::Type{T}, x::GapInt) where {T<:Integer} = T(x)

## Rationals
gap_to_julia(::Type{Rational{T}}, x::GapInt) where {T<:Integer} = Rational{T}(x)

## Floats
gap_to_julia(::Type{T}, obj::GapObj) where {T<:AbstractFloat} = T(obj)

## Chars
gap_to_julia(::Type{Char}, obj::GapObj) = Char(obj)
gap_to_julia(::Type{Cuchar}, obj::GapObj) = Cuchar(obj)

## Strings
gap_to_julia(::Type{String}, obj::GapObj) = String(obj)
gap_to_julia(::Type{T}, obj::GapObj) where {T<:AbstractString} = T(obj)

## Symbols
gap_to_julia(::Type{Symbol}, obj::GapObj) = Symbol(obj)

## Convert GAP string to Vector{UInt8} (==Vector{UInt8})
function gap_to_julia(::Type{Vector{UInt8}}, obj::GapObj)
    Wrappers.IsStringRep(obj) && return CSTR_STRING_AS_ARRAY(obj)
    Wrappers.IsList(obj) && return [gap_to_julia(UInt8, obj[i]) for i = 1:length(obj)]
    throw(ConversionError(obj, Vector{UInt8}))
end

## BitVectors
gap_to_julia(::Type{BitVector}, obj::GapObj) = BitVector(obj)

## Vectors
function gap_to_julia(
    ::Type{Vector{T}},
    obj::GapObj,
    recursion_dict = IdDict();
    recursive::Bool = true,
) where {T}
    if Wrappers.IsList(obj)
        islist = true
    elseif Wrappers.IsVectorObj(obj)
        islist = false
        ELM_LIST = Wrappers.ELM_LIST
    else
        throw(ConversionError(obj, Vector{T}))
    end

    if !haskey(recursion_dict, obj)
        len_list = length(obj)
        new_array = Vector{T}(undef, len_list)
        recursion_dict[obj] = new_array
        for i = 1:len_list
            if islist
                current_obj = ElmList(obj, i)  # returns 'nothing' for holes in the list
            else
                # vector objects aren't lists,
                # but the function for accessing entries is `ELM_LIST`
                current_obj = ELM_LIST(obj, i)
            end
            if recursive && !isbitstype(typeof(current_obj))
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
    recursive::Bool = true,
) where {T}
    if haskey(recursion_dict, obj)
        return recursion_dict[obj]
    end
    if Wrappers.IsMatrixObj(obj)
        nrows = Wrappers.NumberRows(obj)
        ncols = Wrappers.NumberColumns(obj)
    elseif Wrappers.IsList(obj)
        nrows = length(obj)
        ncols = nrows == 0 ? 0 : length(obj[1])
    else
        throw(ConversionError(obj, type))
    end

    elm = Wrappers.ELM_MAT
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

## Sets
## Assume that this function cannot be called inside recursions.
## Note that Julia does not support `Set{Set{Int}}([[1], [1, 1]])`.
## Without this assumption, we would have to construct the set
## in the beginning, and then fill it up using `union!`.
function gap_to_julia(::Type{Set{T}}, obj::GapObj; recursive::Bool = true) where {T}
    if Wrappers.IsCollection(obj)
        obj = Wrappers.AsSet(obj)
    elseif Wrappers.IsList(obj)
        # The list entries may be not comparable via `<`.
        obj = Wrappers.DuplicateFreeList(obj)
    else
        throw(ConversionError(obj, Set{T}))
    end
    len_list = Wrappers.Length(obj)
    new_array = Vector{T}(undef, len_list)
    if recursive
        recursion_dict = IdDict()
    end
    for i = 1:len_list
        current_obj = ElmList(obj, i)
        if recursive
            new_array[i] = get!(recursion_dict, current_obj) do
                gap_to_julia(T, current_obj, recursion_dict; recursive = true)
            end
        else
            new_array[i] = current_obj
        end
    end
    return Set{T}(new_array)
end

## Tuples
## Note that the tuple type prescribes the types of the entries,
## thus we have to convert at least also the next layer,
## even if `recursive == false` holds.
function gap_to_julia(
    ::Type{T},
    obj::GapObj,
    recursion_dict = IdDict();
    recursive::Bool = true,
) where {T<:Tuple}
    !Wrappers.IsList(obj) && throw(ConversionError(obj, T))
    if !haskey(recursion_dict, obj)
        parameters = T.parameters
        len = length(parameters)
        Wrappers.Length(obj) == len ||
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
gap_to_julia(::Type{T}, obj::GapObj) where {T<:UnitRange} = T(obj)
gap_to_julia(::Type{T}, obj::GapObj) where {T<:StepRange} = T(obj)

## Dictionaries
function gap_to_julia(
    ::Type{Dict{Symbol,T}},
    obj::GapObj,
    recursion_dict = IdDict();
    recursive::Bool = true,
) where {T}
    !Wrappers.IsRecord(obj) && throw(ConversionError(obj, Dict{Symbol,T}))
    if !haskey(recursion_dict, obj)
        names = Wrappers.RecNames(obj)
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

function gap_to_julia(x::GapObj; recursive::Bool = true)
    GAP_IS_INT(x) && return gap_to_julia(BigInt, x)
    GAP_IS_RAT(x) && return gap_to_julia(Rational{BigInt}, x)
    GAP_IS_MACFLOAT(x) && return gap_to_julia(Float64, x)
    GAP_IS_CHAR(x) && return gap_to_julia(Cuchar, x)
    # Do not choose this conversion for other lists in 'IsString'.
    Wrappers.IsStringRep(x) && return gap_to_julia(AbstractString, x)
    # Do not choose this conversion for other lists in 'IsRange'.
    Wrappers.IsRangeRep(x) && return gap_to_julia(StepRange{Int64,Int64}, x)
    # Do not choose this conversion for other lists in 'IsBlist'.
    Wrappers.IsBlistRep(x) && return gap_to_julia(BitVector, x)
    Wrappers.IsList(x) && return gap_to_julia(Vector{Any}, x; recursive = recursive)
    Wrappers.IsMatrixObj(x) && return gap_to_julia(Matrix{Any}, x; recursive = recursive)
    Wrappers.IsVectorObj(x) && return gap_to_julia(Vector{Any}, x; recursive = recursive)
    Wrappers.IsRecord(x) && return gap_to_julia(Dict{Symbol,Any}, x; recursive = recursive)
    Wrappers.IS_JULIA_FUNC(x) && return UnwrapJuliaFunc(x)
    throw(ConversionError(x, "any known type"))
end

## for the GAP function GAPToJulia:
## turning arguments into keyword arguments is easier in Julia than in GAP
_gap_to_julia(x::Obj) = gap_to_julia(x)
_gap_to_julia(x::Obj, recursive::Bool) = gap_to_julia(x; recursive = recursive)
_gap_to_julia(::Type{T}, x::Obj) where {T} = gap_to_julia(T, x)
_gap_to_julia(::Type{T}, x::Obj, recursive::Bool) where {T} =
    gap_to_julia(T, x; recursive = recursive)
