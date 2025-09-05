```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

# Conversions

One of the main ideas of GAP.jl is that *automatic* conversions of Julia objects
to GAP objects and vice versa shall be avoided whenever this is possible.
For a few types of objects, such conversions are unavoidable,
see [Automatic GAP-to-Julia and Julia-to-GAP Conversions](@ref).

In all other situations, the user must explicitly convert between GAP objects
and corresponding Julia objects. This is typically done by "type coercion",
also just called "coercion": to convert a Julia object `x` into a GAP object,
you may write `GapObj(x)`, see [`GapObj`](@ref). Conversely, if `y` is a GAP
object, then e.g. `Vector{Int}(y)` will attempt to convert it into a
`Vector{Int}`. This will success if e.g. `y` is a GAP range or a plain list of
integers. See also [Constructor Methods for GAP-to-Julia Conversions](@ref).

For interactive use it may also be convenient to use the function
[`gap_to_julia`](@ref) with a single argument, which will attempt to "guess" a
suitable Julia type for the conversion (e.g. GAP strings will be converted to
Julia strings). However, we generally recommend against using it, as usually
it is better to coerce to a specific type, as that makes it easier to reason
about the code, and helps code to become "type stable" (an important concept
for [writing performant Julia code](https://docs.julialang.org/en/v1/manual/performance-tips/#Write-%22type-stable%22-functions)).


## Automatic GAP-to-Julia and Julia-to-GAP Conversions

When one calls a GAP function with Julia objects as arguments,
or a Julia function with GAP objects as arguments,
the arguments are in general not automatically converted to GAP objects
or Julia objects, respectively.
The exceptions are as follows.

- GAP's immediate integers (in the range -2^60 to 2^60-1)
  are automatically converted to Julia's `Int64` objects;
  Julia's `Int64` objects are automatically converted to GAP's immediate
  integers if they fit, and to GAP's large integers otherwise.

- GAP's immediate finite field elements
  are automatically converted to Julia's `GAP.FFE` objects, and vice versa.

- GAP's `true` and `false`
  are automatically converted to Julia's `true` and `false`, and vice versa.

## Explicit GAP-to-Julia and Julia-to-GAP Conversions

The following rules hold for explicit conversions.

1. Julia types control the conversions.

   - For conversions from Julia to GAP,
     there is at most one possibility on the GAP side,
     and the type of the given Julia object determines which code is used.

   - For conversions from GAP to Julia, several Julia types can be possible
     for the result, for example a GAP integer can be converted to several
     Julia integer types, or a GAP string can be converted to a Julia `String`
     or `Tuple`.
     Usually one wants to specify the target type,
     and then this type determines which code is used for the conversion.
     If one does not specify the target type, a default type will be chosen.

2. Subobjects, recursive conversions

   - GAP lists and records can have subobjects,
     the same holds for various Julia objects such as vectors, matrices,
     tuples, and dictionaries.
     One may or may not want to convert the subobjects recursively,
     this is controlled by the `recursive` keyword argument of the functions
     `GAP.gap_to_julia` and `GapObj`, which can be set to `true` or `false`.

   - For Julia-to-GAP conversion, the default is non-recursive conversion.

   - For GAP-to-Julia conversion, the default is recursive conversion.

   - For Julia-to-GAP conversion, recursion stops at subobjects of type
     `GapObj`.

   - For GAP-to-Julia conversion, recursion stops at subobjects that do
     not have the type `GAP.Obj`.

   - For GAP-to-Julia conversion, the given target type may force a
     conversion of subobjects up to a certain level also if non-recursive
     conversion is requested.
     In this case, recursive conversion means to convert subobjects to
     Julia also if the result has already the target type.

     For example, converting a GAP list of lists `l` to a Julia object of
     type `Vector{Vector{Any}}` means to convert the entries of `l`
     to `Vector{Any}` objects,
     and non-recursive conversion means that the entries of the `l[i]`
     will be kept in the result since the type requirement `Any` is satisfied,
     whereas these entries will get converted to Julia objects
     in the case of recursive conversion.

   - When recursive conversion is requested, identical subobjects
     in the given object correspond to identical subobjects in the result
     of the conversion.

     In order to achieve this, a dictionary gets created in the case of
     recursive conversion, which stores the subobjects and their conversion
     results.
     Some of the implications are as follows.

     - Recursive conversion is more expensive than non-recursive conversion.

     - It can happen that the results of recursive and non-recursive
       conversion are equal, but they differ w.r.t. the identity of subobjects.
       For example, the two entries of the GAP list
       `GAP.evalstr("[ [ 1, 2 ], ~[1] ]")` are identical,
       the same holds for the two entries of the vector obtained by
       recursive conversion of this list to an object of type
       `Vector{Vector{Int}}`;
       however, the two entries of the vector obtained by
       non-recursive conversion of this list to an object of type
       `Vector{Vector{Int}}` are equal but not identical.

     (Note that "identity of objects" has different meanings in GAP and Julia.
     For example, converting a GAP list of equal but nonidentical
     strings to a Julia vector of symbols will yield an object with
     identical subobjects.)

3. Mutability of results of conversions

   - In GAP, mutability is defined for individual objects.
     GAP objects that are newly created by Julia-to-GAP conversions
     are mutable whenever this is possible.

   - In Julia, mutability is defined for types.
     (The type `GapObj` is a mutable type.)

4. Implementation of conversion methods

   - In order to install a new GAP-to-Julia conversion for some
     prescribed target type `T`,
     one has to install a [`GAP.gap_to_julia_internal`](@ref) method
     where `T` is specified as the first argument.

   - In order to install a new Julia-to-GAP conversion for
     objects of type `T`,
     one has to install a [`GAP.GapObj_internal`](@ref) method.
     If one knows that objects of type `T` need not support
     recursive conversion then one can alternatively use the
     [`GAP.@install`](@ref) macro for the installation.

```@docs
gap_to_julia
GapObj(x, cache::GapCacheDict = nothing; recursive::Bool = false)
```

## Constructor Methods for GAP-to-Julia Conversions

(For Julia-to-GAP conversions,
one can use [`GapObj`](@ref) and [`GAP.Obj`](@ref) as constructors.)

```@docs
Int128
BigInt
Rational
Float64
Char
Cuchar
String
Symbol
UnitRange
StepRange
Tuple
BitVector
Vector{T}
Matrix{T}
Set{T}
Dict{Symbol,T}
```
