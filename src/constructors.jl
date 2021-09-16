## Handle "conversion" to GAP.Obj and GAP.GapObj (may occur in recursions).
Obj(x::Obj) = x
GapObj(x::GapObj) = x

## Handle conversion of Julia objects to GAP objects
GapObj(obj; recursive::Bool = false) = julia_to_gap(obj, IdDict(), recursive = recursive)

## Integer, BigInt
"""
    BigInt(obj::GapObj)

Return the big integer converted from
the [GAP integer](GAP_ref(ref:Integers)) `obj`.
(Note that small GAP integers are not represented by `GapObj`s,
their conversion with `BigInt` is handled by Julia's methods.)

# Examples
```jldoctest
julia> val = GAP.evalstr("2^64")
GAP: 18446744073709551616

julia> BigInt(val)
18446744073709551616

julia> val = GAP.evalstr("2^59")
576460752303423488

julia> isa(val, GapObj)
false

julia> BigInt(val)
576460752303423488

```
"""
Base.BigInt(obj::GapObj) = gap_to_julia(BigInt, obj)

# A small integer cannot be represented by a `GapObj`,
# the `T` is expected to be `Int64` or `Int128` if `obj` can be converted
# to an integer type.
(::Type{T})(obj::GapObj) where {T<:Integer} = T(BigInt(obj))
@doc """
    Int128(obj::GapObj)

Return the `Int128` converted from
the [GAP integer](GAP_ref(ref:Integers)) `obj`.
(Note that small GAP integers are represented by Julia `Int64` objects,
in particular they are not `GapObj`s;
their conversion is not handled by methods installed in GAP.jl.)

# Examples
```jldoctest
julia> val = GAP.evalstr("2^80")
GAP: 1208925819614629174706176

julia> Int128(val)
1208925819614629174706176

```
""" Int128


"""
    big(obj::GapObj)

Return the big integer converted from
the [GAP integer](GAP_ref(ref:Integers)) `obj`,
or the big rational converted from
the [GAP rational](GAP_ref(ref:Rationals)) `obj`,
or the big float converted from
the [GAP float](GAP_ref(ref:Floats)) `obj`.

# Examples
```jldoctest
julia> val = GAP.evalstr("2^64")
GAP: 18446744073709551616

julia> big(val)
18446744073709551616

julia> val = GAP.evalstr("1/3")
GAP: 1/3

julia> big(val)
1//3

julia> val = GAP.evalstr("1.1")
GAP: 1.1

julia> big(val)
1.100000000000000088817841970012523233890533447265625

```
"""
function Base.big(obj::GapObj)
    GAP_IS_INT(obj) && return gap_to_julia(BigInt, obj)
    GAP_IS_RAT(obj) && return gap_to_julia(Rational{BigInt}, obj)
    GAP_IS_MACFLOAT(obj) && return gap_to_julia(BigFloat, obj)
    throw(ConversionError(obj, "a type supported by big"))
end

## Rationals
"""
    Rational{T}(obj::GapObj) where {T<:Integer}

Return the rational converted from
the [GAP integer](GAP_ref(ref:Integers)) or
the [GAP rational](GAP_ref(ref:Rationals)) `obj`,

# Examples
```jldoctest
julia> val = GAP.evalstr("2^64")
GAP: 18446744073709551616

julia> Rational{Int128}(val)
18446744073709551616//1

julia> Rational{BigInt}(val)
18446744073709551616//1

julia> val = GAP.evalstr("1/3")
GAP: 1/3

julia> Rational{Int64}(val)
1//3

```
"""
Base.Rational{T}(obj::GapObj) where {T<:Integer} = gap_to_julia(Rational{T}, obj)

## Floats
"""
    Float64(obj::GapObj)

Return the float converted from the [GAP float](GAP_ref(ref:Floats)) `obj`.

# Examples
```jldoctest
julia> val = GAP.evalstr("2.2")
GAP: 2.2

julia> Float64(val)
2.2

julia> Float32(val)
2.2f0

```
"""
Base.Float64(obj::GapObj) = gap_to_julia(Float64, obj)
(::Type{T})(obj::GapObj) where {T<:AbstractFloat} = T(Float64(obj))

## Chars
"""
    Char(obj::GapObj)

Return the character converted from the
[GAP character](GAP_ref(ref:Strings and Characters)) `obj`.

# Examples
```jldoctest
julia> val = GAP.evalstr("'x'")
GAP: 'x'

julia> Char(val)
'x': ASCII/Unicode U+0078 (category Ll: Letter, lowercase)

```
"""
Base.Char(obj::GapObj) = gap_to_julia(Char, obj)

"""
    Cuchar(obj::GapObj)

Return the `UInt8` that belongs to the
[GAP character](GAP_ref(ref:Strings and Characters)) `obj`.

# Examples
```jldoctest
julia> val = GAP.evalstr("'x'")
GAP: 'x'

julia> Cuchar(val)
0x78

```
"""
Base.Cuchar(obj::GapObj) = gap_to_julia(obj)

## Strings
"""
    String(obj::GapObj)

Return the Julia string converted from the
[GAP string](GAP_ref(ref:Strings and Characters)) `obj`.
Note that [GAP's String function](GAP_ref(ref:String)) can be applied to
arbitrary GAP objects, similar to Julia's `string` function;
this behaviour is not intended for this `String` constructor.

# Examples
```jldoctest
julia> val = GAP.evalstr("\\"abc\\"")
GAP: "abc"

julia> String(val)
"abc"

julia> val = GAP.evalstr("[]")
GAP: [  ]

julia> String(val)   # an empty GAP list is a string
""

```
"""
Base.String(obj::GapObj) = gap_to_julia(String, obj)
(::Type{T})(obj::GapObj) where {T<:AbstractString} = convert(T, String(obj))

## Symbols
"""
    Symbol(obj::GapObj)

Return the symbol converted from the
[GAP string](GAP_ref(ref:Strings and Characters)) `obj`.

# Examples
```jldoctest
julia> str = GAP.evalstr("\\"abc\\"")
GAP: "abc"

julia> Symbol(str)
:abc

```
"""
Core.Symbol(obj::GapObj) = Symbol(String(obj))

## BitVectors
@doc """
    BitVector(obj::GapObj)

Return the bit vector converted from the
[GAP list of booleans](GAP_ref(ref:Boolean Lists)) `obj`.

# Examples
```jldoctest
julia> val = GAP.evalstr("[ true, false, true ]")
GAP: [ true, false, true ]

julia> BitVector(val)
3-element BitVector:
 1
 0
 1

```
"""
BitVector(obj::GapObj) = gap_to_julia(BitVector, obj)

## Arrays
## (special case: convert GAP string to Vector{UInt8} (== Vector{UInt8}))
"""
    Vector{T}(obj::GapObj; recursive = true)

Return the 1-dimensional array converted from the
[GAP list](GAP_ref(ref:Lists)) `obj`.
The entries of the list are converted to the type `T`,
using [`gap_to_julia`](@ref).
If `recursive` is `true` then the entries of the list are
converted recursively, otherwise non-recursively.

If `T` is `UInt8` then `obj` may be a
[GAP string](GAP_ref(ref:Strings and Characters)).

# Examples
```jldoctest
julia> val = GAP.evalstr("[ [ 1 ], [ 2 ] ]")
GAP: [ [ 1 ], [ 2 ] ]

julia> Vector{Any}(val)
2-element Vector{Any}:
 Any[1]
 Any[2]

julia> Vector{Any}(val, recursive = false)
2-element Vector{Any}:
 GAP: [ 1 ]
 GAP: [ 2 ]

julia> val = GAP.evalstr( "NewVector( IsPlistVectorRep, Integers, [ 0, 2, 5 ] )" )
GAP: <plist vector over Integers of length 3>

julia> Vector{Int64}( val )
3-element Vector{Int64}:
 0
 2
 5

julia> val = GAP.evalstr("\\"abc\\"")
GAP: "abc"

julia> Vector{UInt8}(val)
3-element Vector{UInt8}:
 0x61
 0x62
 0x63

```
"""
Base.Vector{T}(obj::GapObj; recursive = true) where {T} =
    gap_to_julia(Vector{T}, obj; recursive = recursive)

## Matrix / list-of-lists
"""
    Matrix{T}(obj::GapObj; recursive = true)

Return the 2-dimensional array converted from the GAP matrix `obj`,
which can be a [GAP list of lists](GAP_ref(ref:Matrices)) or
a [GAP matrix object](GAP_ref(ref:Vector and Matrix Objects)).
The entries of the matrix are converted to the type `T`,
using [`gap_to_julia`](@ref).
If `recursive` is `true` then the entries are
converted recursively, otherwise non-recursively.

# Examples
```jldoctest
julia> val = GAP.evalstr("[ [ 1, 2 ], [ 3, 4 ] ]")
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
Base.Matrix{T}(obj::GapObj; recursive = true) where {T} =
    gap_to_julia(Matrix{T}, obj; recursive = recursive)

## Sets
@doc """
    Set{T}(obj::GapObj; recursive = true)

Return the set converted from the
[GAP list](GAP_ref(ref:Lists)) or [GAP collection](GAP_ref(ref:Collections))
`obj`.
The elements of `obj` are converted to the required type `T`,
using [`gap_to_julia`](@ref).
If `recursive` is `true` then the elements are
converted recursively, otherwise non-recursively.

This constructor method is intended for situations where the result
involves only native Julia objects such as integers and strings.
Dealing with results containing GAP objects will be inefficient.

# Examples
```
julia> Set{Int}(GAP.evalstr("[ 1, 2, 1 ]"))
Set{Int64} with 2 elements:
  2
  1

julia> Set{Vector{Int}}(GAP.evalstr("[[1], [2], [1]]"))
Set{Vector{Int64}} with 2 elements:
  [1]
  [2]

julia> Set{String}(GAP.evalstr("[\\"a\\", \\"b\\"]"))
Set{String} with 2 elements:
  "b"
  "a"

julia> Set{Any}(GAP.evalstr("[[1], [2], [1]]"))
Set{Any} with 2 elements:
  Any[1]
  Any[2]

```

In the following examples,
the order in which the Julia output is shown may vary.

# Examples
```jldoctest
julia> s = Set{Any}(GAP.evalstr("[[1], [2], [1]]"), recursive = false);

julia> s == Set{Any}([GAP.evalstr("[ 1 ]"), GAP.evalstr("[ 2 ]")])
true

julia> s = Set{Any}(GAP.evalstr("SymmetricGroup(2)"), recursive = false);

julia> s == Set{Any}([GAP.evalstr("()"), GAP.evalstr("(1,2)")])
true

```
"""
Base.Set{T}(obj::GapObj; recursive = true) where {T} =
    gap_to_julia(Set{T}, obj; recursive = recursive)

## Tuples
(::Type{T})(obj::GapObj; recursive = true) where {T<:Tuple} =
    gap_to_julia(T, obj, recursive = recursive)
@doc """
    Tuple{Types...}(obj::GapObj; recursive = true)

Return the tuple converted from the
[GAP list](GAP_ref(ref:Lists)) `obj`.
The entries of the list are converted to the required types `Types...`,
using [`gap_to_julia`](@ref).
If `recursive` is `true` then the entries of the list are
converted recursively, otherwise non-recursively.

# Examples
```jldoctest
julia> val = GAP.evalstr("[ 1, 5 ]")
GAP: [ 1, 5 ]

julia> Tuple{Int64,Int64}(val)
(1, 5)

julia> val = GAP.evalstr("[ [ 1 ], [ 2 ] ]")
GAP: [ [ 1 ], [ 2 ] ]

julia> Tuple{Any,Any}(val)
(Any[1], Any[2])

julia> Tuple{GapObj,GapObj}(val, recursive = false)
(GAP: [ 1 ], GAP: [ 2 ])

```
""" Tuple

## Ranges
(::Type{T})(obj::GapObj) where {T<:UnitRange} = gap_to_julia(T, obj)
@doc """
    UnitRange(obj::GapObj)

Return the unit range converted from the
[GAP range](GAP_ref(ref:Ranges)) `obj`, which has step width 1.

# Examples
```jldoctest
julia> val = GAP.evalstr("[ 1 .. 10 ]")
GAP: [ 1 .. 10 ]

julia> UnitRange(val)
1:10

julia> UnitRange{Int32}(val)
1:10

```
""" UnitRange

(::Type{T})(obj::GapObj) where {T<:StepRange} = gap_to_julia(T, obj)
@doc """
    StepRange(obj::GapObj)

Return the step range converted from the
[GAP range](GAP_ref(ref:Ranges)) `obj`, which may have arbitrary step width.

# Examples
```jldoctest
julia> val = GAP.evalstr("[ 1, 3 .. 11 ]")
GAP: [ 1, 3 .. 11 ]

julia> StepRange(val)
1:2:11

julia> r = StepRange{Int8,Int8}(val)
1:2:11

julia> typeof(r)
StepRange{Int8, Int8}

```
""" StepRange

## Dictionaries
"""
    Dict{Symbol,T}(obj::GapObj; recursive = true)

Return the dictionary converted from the
[GAP record](GAP_ref(ref:Records)) `obj`.
If `recursive` is `true` then the values of the record components are
recursively converted to objects of the type `T`,
using [`gap_to_julia`](@ref), otherwise they are kept as they are.

# Examples
```jldoctest
julia> val = GAP.evalstr("rec( a:= 1, b:= 2 )")
GAP: rec( a := 1, b := 2 )

julia> Dict{Symbol,Int}(val)
Dict{Symbol, Int64} with 2 entries:
  :a => 1
  :b => 2

julia> val = GAP.evalstr("rec( l:= [ 1, 2 ] )")
GAP: rec( l := [ 1, 2 ] )

julia> Dict{Symbol,Any}(val, recursive = false)
Dict{Symbol, Any} with 1 entry:
  :l => GAP: [ 1, 2 ]

julia> Dict{Symbol,Any}(val, recursive = true)
Dict{Symbol, Any} with 1 entry:
  :l => Any[1, 2]

julia> Dict{Symbol,Vector{Int}}(val, recursive = true)
Dict{Symbol, Vector{Int64}} with 1 entry:
  :l => [1, 2]

```
"""
Base.Dict{Symbol,T}(obj::GapObj; recursive = true) where {T} =
    gap_to_julia(Dict{Symbol,T}, obj; recursive = recursive)
