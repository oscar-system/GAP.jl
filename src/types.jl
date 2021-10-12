"""
    FFE

Wrap a pointer to a GAP FFE ("finite field element") immediate object.
This type is defined in the JuliaInterface C code.

# Examples
```jldoctest
julia> x = GAP.Globals.Z(3)
GAP: Z(3)

julia> typeof(x)
FFE

```
"""
primitive type FFE 64 end


"""
    GapObj

This is the Julia type of all those GAP objects that are not
"immediate" (booleans, small integers, FFEs).

# Examples
```jldoctest
julia> typeof( GAP.evalstr( "[ 1, 2 ]" ) ) # a GAP list
GapObj

julia> typeof( GAP.evalstr( "rec()" ) )    # a GAP record
GapObj

julia> typeof( GAP.evalstr( "(1,2,3)" ) )  # a GAP permutation
GapObj

julia> typeof( GAP.evalstr( "2^64" ) )     # a large GAP integer
GapObj

julia> typeof( GAP.evalstr( "2^59" ) )     # a small GAP integer
Int64

julia> typeof( GAP.evalstr( "Z(2)" ) )     # a GAP FFE
FFE

julia> typeof( GAP.evalstr( "true" ) )     # a boolean
Bool

```

Note that this is Julia's viewpoint on GAP objects.
From the viewpoint of GAP, also the pointers to Julia objects are
implemented as "non-immediate GAP objects",
but they appear as Julia objects to Julia, not "doubly wrapped".

# Examples
```jldoctest
julia> GAP.evalstr( "Julia.Base" )
Base

julia> typeof( GAP.evalstr( "Julia.Base" ) )        # native Julia object
Module

```

One can use `GapObj` as a constructor,
in order to convert Julia objects to GAP objects.
Such calls are delegated to [`julia_to_gap`](@ref).

However, this is restricted to outputs that actually are of type `GapObj`.
To also deal with GAP integers, finite field elements and booleans, use
[`GAP.Obj`](@ref) instead.

# Examples
```jldoctest
julia> GapObj(1//3)
GAP: 1/3

julia> GapObj([1 2; 3 4])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GapObj(42)
ERROR: TypeError: in typeassert, expected GapObj, got a value of type Int64

```
"""
const GapObj = GAP_jll.MPtr


"""
    GAP.Obj

This is an alias for `Union{GapObj,FFE,Int64,Bool}`.
This type union covers all types a "native" GAP object may have
from Julia's viewpoint.

Moreover, it can be used as a constructor,
in order to convert Julia objects to GAP objects,
whenever a suitable conversion has been defined.

# Examples
```jldoctest
julia> GAP.Obj(1//3)
GAP: 1/3

julia> GAP.Obj([1 2; 3 4])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GAP.Obj(42)
42

```
"""
const Obj = Union{GapObj,FFE,Int64,Bool}

"""
    GapInt

Any GAP integer object is represened in Julia as either a `GapObj` (if it
is a "large" integer) or as an `Int` (if it is a "small" integer). This
type union can be used to express this conveniently, e.g. when one wants to
help type stability.

Note that also GAP's `infinity` and `-infinity` fit under this type (as do
many other objects which are not numbers).
"""
const GapInt = Union{GapObj,Int}

# Don't export GAP.Obj!
export FFE, GapObj, GapInt
