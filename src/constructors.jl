## Handle "conversion" to GAP.Obj and GAP.GapObj (may occur in recursions).
Obj(x::Obj) = x
GapObj(x::GapObj) = x

## Integer, BigInt
Base.BigInt(obj::GapObj) = gap_to_julia(BigInt, obj)
(::Type{T})(obj::GapObj) where T<:Integer = T(BigInt(obj))

function Base.big(obj::GapObj)
    Globals.IsInt(obj) && return gap_to_julia(BigInt, obj)
    Globals.IsRat(obj) && return gap_to_julia(Rational{BigInt}, obj)
    Globals.IsFloat(obj) && return gap_to_julia(BigFloat, obj)
    throw(ConversionError(obj, "a type supported by big"))
end

## Rationals
Base.Rational{T}(obj::GapObj) where T<:Integer = gap_to_julia(Rational{T}, obj)

## Floats
Base.Float64(obj::GapObj) = gap_to_julia(Float64, obj)
(::Type{T})(obj::GapObj) where T<:AbstractFloat = T(Float64(obj))

## Chars
Base.Char(obj::GapObj) = gap_to_julia(obj)
Base.Cuchar(obj::GapObj) = gap_to_julia(obj)

## Strings
Base.String(obj::GapObj) = gap_to_julia(String, obj)
(::Type{T})(obj::GapObj) where T<:AbstractString = convert(T, String(obj))

## Symbols
Core.Symbol(obj::GapObj) = Symbol(String(obj))

## Convert GAP string to Array{UInt8,1} (== Array{UInt8,1})
Vector{UInt8}(obj::GapObj) = gap_to_julia(Vector{UInt8}, obj)

## BitArrays
BitArray{1}(obj::GapObj) = gap_to_julia(BitArray{1}, obj)

## Arrays
Base.Vector{T}(obj::GapObj; recursive=true) where T = gap_to_julia(Vector{T}, obj; recursive=recursive)

## Matrix / list-of-lists
Base.Matrix{T}(obj::GapObj; recursive=true) where T = gap_to_julia(Matrix{T}, obj; recursive=recursive)

## Tuples
(::Type{T})(obj::GapObj; recursive=true) where T<:Tuple = gap_to_julia(T, obj, recursive=recursive)

## Ranges
(::Type{T})(obj::GapObj) where T<:UnitRange = gap_to_julia(T, obj)
(::Type{T})(obj::GapObj) where T<:StepRange = gap_to_julia(T, obj)

## Dictionaries
Base.Dict{Symbol,T}(obj::GapObj; recursive=true) where T = gap_to_julia(Dict{Symbol,T}, obj; recursive=recursive)

