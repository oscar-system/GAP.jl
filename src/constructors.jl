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

## Handle "conversion" to GAP.Obj and GapObj (may occur in recursions).
Obj(x::Obj) = x
GapObj(x::GapObj) = x

## Handle conversion of Julia objects to GAP objects
Obj(obj; recursive::Bool = false) = GapObj_internal(obj, nothing, BoolVal(recursive))::Obj

Obj(obj, recursive::Bool) = GapObj_internal(obj, nothing, BoolVal(recursive))::Obj
GapObj(obj, recursive::Bool) = GapObj_internal(obj, nothing, BoolVal(recursive))::Obj

## Conversion to gap integers
GapInt(x::Integer) = GapObj(x)


"""
    BigInt(obj::GapObj)

Return the big integer converted from
the [GAP integer](GAP_ref(ref:Integers)) `obj`.
(Note that small GAP integers are not represented by `GapObj`s,
their conversion with `BigInt` is handled by Julia's methods.)

# Examples
```jldoctest
julia> val = GAP.Globals.Factorial(25)
GAP: 15511210043330985984000000

julia> BigInt(val)
15511210043330985984000000

julia> val = GAP.Globals.Factorial(10)
3628800

julia> isa(val, GapObj)
false

julia> BigInt(val)
3628800

```
"""
function Base.BigInt(obj::GapObj)
    GAP_IS_INT(obj) || throw(ConversionError(obj, BigInt))
    ## get size of GAP BigInt (in limbs), multiply
    ## by 64 to get bits
    size_limbs = @ccall libgap.GAP_SizeInt(obj::Any)::Cint
    size = abs(size_limbs * sizeof(UInt) * 8)
    ## allocate new GMP
    new_bigint = Base.GMP.MPZ.realloc2(size)
    new_bigint.size = size_limbs
    ## Get limb address ptr
    addr = @ccall libgap.GAP_AddrInt(obj::Any)::Ptr{UInt}
    ## Copy limbs
    unsafe_copyto!(new_bigint.d, addr, abs(size_limbs))
    return new_bigint
end

# A small integer cannot be represented by a `GapObj`,
# the `T` is expected to be `Int64` or `Int128` if `obj` can be converted
# to an integer type.
function (::Type{T})(obj::GapObj) where {T<:Integer}
    GAP_IS_INT(obj) || throw(ConversionError(obj, T))
    return T(BigInt(obj))::T
end

@doc """
    Int128(obj::GapObj)

Return the `Int128` converted from
the [GAP integer](GAP_ref(ref:Integers)) `obj`.
(Note that small GAP integers are represented by Julia `Int64` objects,
in particular they are not `GapObj`s;
their conversion is not handled by methods installed in GAP.jl.)

# Examples
```jldoctest
julia> val = GAP.Globals.Factorial(25)
GAP: 15511210043330985984000000

julia> Int128(val)
15511210043330985984000000

julia> Int(val)
ERROR: InexactError: Int64(15511210043330985984000000)
```
""" Int128

"""
    Rational{T}(obj::GapObj) where {T<:Integer}

Return the rational converted from
the [GAP integer](GAP_ref(ref:Integers)) or
the [GAP rational](GAP_ref(ref:Rationals)) `obj`,

# Examples
```jldoctest
julia> val = GAP.Globals.Factorial(25)
GAP: 15511210043330985984000000

julia> Rational{Int128}(val)
15511210043330985984000000//1

julia> Rational{BigInt}(val)
15511210043330985984000000//1

julia> val = GAP.Obj(1//3)
GAP: 1/3

julia> Rational{Int64}(val)
1//3

```
"""
function Base.Rational{T}(obj::GapObj) where {T<:Integer}
    GAP_IS_INT(obj) && return T(obj) // T(1)
    GAP_IS_RAT(obj) || throw(ConversionError(obj, Rational{T}))
    numer = Wrappers.NumeratorRat(obj)
    denom = Wrappers.DenominatorRat(obj)
    return T(numer) // T(denom)
end

"""
    Float64(obj::GapObj)

Return the float converted from the [GAP float](GAP_ref(ref:Floats)) `obj`.

# Examples
```jldoctest
julia> val = GAP.Obj(2.2)
GAP: 2.2

julia> Float64(val)
2.2

julia> Float32(val)
2.2f0

```
"""
function Base.Float64(obj::GapObj)
    GAP_IS_MACFLOAT(obj) && return ValueMacFloat(obj)::Float64
    throw(ConversionError(obj, Float64))
end
(::Type{T})(obj::GapObj) where {T<:AbstractFloat} = T(Float64(obj))

"""
    Char(obj::GapObj)

Return the character converted from the
[GAP character](GAP_ref(ref:Strings and Characters)) `obj`.

# Examples
```jldoctest
julia> val = GAP.Obj('x')
GAP: 'x'

julia> Char(val)
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)

```
"""
function Base.Char(obj::GapObj)
    GAP_IS_CHAR(obj) && return Char(Wrappers.INT_CHAR(obj))
    throw(ConversionError(obj, Char))
end

"""
    Cuchar(obj::GapObj)

Return the `UInt8` that belongs to the
[GAP character](GAP_ref(ref:Strings and Characters)) `obj`.

# Examples
```jldoctest
julia> val = GAP.Obj('x')
GAP: 'x'

julia> Cuchar(val)
0x78

```
"""
function Base.Cuchar(obj::GapObj)
    GAP_IS_CHAR(obj) && return trunc(Cuchar, Wrappers.INT_CHAR(obj))
    GAP_IS_INT(obj) && return throw(InexactError(nameof(Cuchar), Cuchar, obj))
    throw(ConversionError(obj, Cuchar))
end

"""
    String(obj::GapObj)

Return the Julia string converted from the
[GAP string](GAP_ref(ref:Strings and Characters)) `obj`.
Note that [GAP's String function](GAP_ref(ref:String)) can be applied to
arbitrary GAP objects, similar to Julia's `string` function;
this behaviour is not intended for this `String` constructor.

# Examples
```jldoctest
julia> val = GAP.Obj("abc")
GAP: "abc"

julia> String(val)
"abc"

julia> val = GAP.Obj([])
GAP: [  ]

julia> String(val)   # an empty GAP list is a string
""

```
"""
function Core.String(obj::GapObj)
    Wrappers.IsStringRep(obj) && return CSTR_STRING(obj)
    Wrappers.IsString(obj) && return CSTR_STRING(Wrappers.CopyToStringRep(obj))
    throw(ConversionError(obj, String))
end

"""
    Symbol(obj::GapObj)

Return the symbol converted from the
[GAP string](GAP_ref(ref:Strings and Characters)) `obj`.

# Examples
```jldoctest
julia> str = GAP.Obj("abc")
GAP: "abc"

julia> Symbol(str)
:abc

```
"""
function Core.Symbol(obj::GapObj)
    if Wrappers.IsString(obj)
        if !Wrappers.IsStringRep(obj)
            obj = Wrappers.CopyToStringRep(obj)
        end
        s, len = UNSAFE_CSTR_STRING(obj)
        return @ccall jl_symbol_n(s::Ptr{UInt8}, len::Int)::Ref{Symbol}
    end
    throw(ConversionError(obj, Symbol))
end

@doc """
    BitVector(obj::GapObj)

Return the bit vector converted from the
[GAP list of booleans](GAP_ref(ref:Boolean Lists)) `obj`.

# Examples
```jldoctest
julia> val = GAP.Obj([true, false, true])
GAP: [ true, false, true ]

julia> BitVector(val)
3-element BitVector:
 1
 0
 1

```
"""
function Base.BitVector(obj::GapObj)
    !Wrappers.IsBlist(obj) && throw(ConversionError(obj, BitVector))
    # TODO: a much better conversion would be possible, at least if `obj` is
    # in IsBlistRep, then we could essentially memcpy data
    len = length(obj)
    result = BitVector(undef, len)
    for i = 1:len
        result[i] = obj[i]::Bool
    end
    return result
end

"""
    Vector{T}(obj::GapObj; recursive::Bool = false)

Return the 1-dimensional array converted from the
[GAP list](GAP_ref(ref:Lists)) `obj`.
The entries of the list are converted to the type `T`.
If `recursive` is `true` then the entries of the list are
converted recursively, otherwise non-recursively.

If `T` is `UInt8` then `obj` may be a
[GAP string](GAP_ref(ref:Strings and Characters)).

# Examples
```jldoctest
julia> val = GAP.Obj([[1], [2]]; recursive=true)
GAP: [ [ 1 ], [ 2 ] ]

julia> Vector{Any}(val; recursive=true)
2-element Vector{Any}:
 Any[1]
 Any[2]

julia> Vector{Any}(val)
2-element Vector{Any}:
 GAP: [ 1 ]
 GAP: [ 2 ]

julia> Vector{Vector{Int64}}(val)
2-element Vector{Vector{Int64}}:
 [1]
 [2]

julia> val = GAP.evalstr( "NewVector( IsPlistVectorRep, Integers, [ 0, 2, 5 ] )" )
GAP: <plist vector over Integers of length 3>

julia> Vector{Int64}(val)
3-element Vector{Int64}:
 0
 2
 5

julia> val = GAP.Obj("abc")
GAP: "abc"

julia> Vector{UInt8}(val)
3-element Vector{UInt8}:
 0x61
 0x62
 0x63

```
"""
Base.Vector{T}(obj::GapObj; recursive::Bool = false) where {T} =
    gap_to_julia(Vector{T}, obj; recursive)

"""
    Matrix{T}(obj::GapObj; recursive::Bool = false)

Return the 2-dimensional array converted from the GAP matrix `obj`,
which can be a [GAP list of lists](GAP_ref(ref:Matrices)) or
a [GAP matrix object](GAP_ref(ref:Vector and Matrix Objects)).
The entries of the matrix are converted to the type `T`.
If `recursive` is `true` then the entries are
converted recursively, otherwise non-recursively.

# Examples
```jldoctest
julia> val = GAP.Obj([[1, 2], [3, 4]]; recursive=true)
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> Matrix{Int64}(val)
2×2 Matrix{Int64}:
 1  2
 3  4

julia> val = GAP.evalstr( "NewMatrix( IsPlistMatrixRep, Integers, 2, [ 0, 1, 2, 3 ] )" )
GAP: <2x2-matrix over Integers>

julia> Matrix{Int64}(val)
2×2 Matrix{Int64}:
 0  1
 2  3

```
"""
Base.Matrix{T}(obj::GapObj; recursive::Bool = false) where {T} =
    gap_to_julia(Matrix{T}, obj; recursive)

@doc """
    Set{T}(obj::GapObj; recursive::Bool = false)

Return the set converted from the
[GAP list](GAP_ref(ref:Lists)) or [GAP collection](GAP_ref(ref:Collections))
`obj`.
The elements of `obj` are converted to the required type `T`.
If `recursive` is `true` then the elements are
converted recursively, otherwise non-recursively.

This constructor method is intended for situations where the result
involves only native Julia objects such as integers and strings.
Dealing with results containing GAP objects will be inefficient.

# Examples
```julia
julia> Set{Int}(GAP.Obj([1, 2, 1]))
Set{Int64} with 2 elements:
  2
  1

julia> Set{Vector{Int}}(GAP.Obj([[1], [2], [1]]))
Set{Vector{Int64}} with 2 elements:
  [1]
  [2]

julia> Set{String}(GAP.Obj(["a", "b"]; recursive=true))
Set{String} with 2 elements:
  "b"
  "a"

julia> Set{Any}(GAP.Obj([[1], [2], [1]]; recursive=true))
Set{Any} with 2 elements:
  Any[1]
  Any[2]
```
"""
Base.Set{T}(obj::GapObj; recursive::Bool = false) where {T} =
    gap_to_julia(Set{T}, obj; recursive)

@doc """
    Tuple{Types...}(obj::GapObj; recursive::Bool = false)

Return the tuple converted from the
[GAP list](GAP_ref(ref:Lists)) `obj`.
The entries of the list are converted to the required types `Types...`.
If `recursive` is `true` then the entries of the list are
converted recursively, otherwise non-recursively.

# Examples
```jldoctest
julia> val = GAP.Obj([1, 5])
GAP: [ 1, 5 ]

julia> Tuple{Int64,Int64}(val)
(1, 5)

julia> val = GAP.Obj([[1], [2]]; recursive=true)
GAP: [ [ 1 ], [ 2 ] ]

julia> Tuple{Any,Any}(val; recursive=true)
(Any[1], Any[2])

julia> Tuple{GapObj,GapObj}(val)
(GAP: [ 1 ], GAP: [ 2 ])

```
""" Tuple

(::Type{T})(obj::GapObj; recursive::Bool = false) where {T<:Tuple} =
    gap_to_julia(T, obj; recursive)

@doc """
    UnitRange(obj::GapObj)

Return the unit range converted from the
[GAP range](GAP_ref(ref:Ranges)) `obj`, which has step width 1.

# Examples
```jldoctest
julia> val = GAP.Obj(1:10)
GAP: [ 1 .. 10 ]

julia> UnitRange(val)
1:10

julia> UnitRange{Int32}(val)
1:10

```
""" UnitRange

function (::Type{T})(obj::GapObj) where {T<:UnitRange}
    !Wrappers.IsRange(obj) && throw(ConversionError(obj, T))
    len = length(obj)
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

    return convert(T, result)::T
end


@doc """
    StepRange(obj::GapObj)

Return the step range converted from the
[GAP range](GAP_ref(ref:Ranges)) `obj`, which may have arbitrary step width.

# Examples
```jldoctest
julia> val = GAP.Obj(1:2:11)
GAP: [ 1, 3 .. 11 ]

julia> StepRange(val)
1:2:11

julia> r = StepRange{Int8,Int8}(val)
1:2:11

julia> typeof(r)
StepRange{Int8, Int8}

```
""" StepRange

function(::Type{T})(obj::GapObj) where {T<:StepRange}
    !Wrappers.IsRange(obj) && throw(ConversionError(obj, T))
    len = length(obj)
    if len == 0
        # construct an empty StepRange object
        start = 1
        step = 1
        stop = 0
    elseif len == 1
        start = obj[1]::Int
        step = 1
        stop = obj[1]::Int
    else
        start = obj[1]::Int
        step = obj[2]::Int - start
        stop = obj[len]::Int
    end

    # Julia does not support `StepRange(obj)` (but `StepRange{S,T}(obj)`),
    # and also `T(start, step, stop)` does not work for each `T` in question,
    # but we can always use `convert`.
    return convert(T, start:step:stop)
end

"""
    Dict{Symbol,T}(obj::GapObj; recursive::Bool = false)

Return the dictionary converted from the
[GAP record](GAP_ref(ref:Records)) `obj`.
If `recursive` is `true` then the values of the record components are
recursively converted to objects of the type `T`.

# Examples
```jldoctest
julia> val = GAP.Obj(Dict(:a => 1, :b => 2))
GAP: rec( a := 1, b := 2 )

julia> Dict{Symbol,Int}(val)
Dict{Symbol, Int64} with 2 entries:
  :a => 1
  :b => 2

julia> val = GAP.Obj(Dict(:l => GAP.Obj([1, 2])))
GAP: rec( l := [ 1, 2 ] )

julia> Dict{Symbol,Any}(val)
Dict{Symbol, Any} with 1 entry:
  :l => GAP: [ 1, 2 ]

julia> Dict{Symbol,Any}(val; recursive=true)
Dict{Symbol, Any} with 1 entry:
  :l => Any[1, 2]

julia> Dict{Symbol,Vector{Int}}(val; recursive=true)
Dict{Symbol, Vector{Int64}} with 1 entry:
  :l => [1, 2]

```
"""
Base.Dict{Symbol,T}(obj::GapObj; recursive::Bool = false) where {T} =
    gap_to_julia(Dict{Symbol,T}, obj; recursive)
