"""
    FFE

Wrap a pointer to a GAP FFE ("finite field element") immediate object.
This type is defined in the JuliaInterface C code.

# Examples
```jldoctest
julia> x = GAP.evalstr( "Z(3)" )
GAP: Z(3)

julia> typeof( x )
FFE

```
"""
primitive type FFE 64 end


"""
    GapObj

This is the Julia type of all those GAP objects that are not
"immediate" (Booleans, small integers, FFEs).

# Examples
```jldoctest
julia> isa( GAP.evalstr( "[ 1, 2 ]" ), GapObj ) # a GAP list
true

julia> isa( GAP.evalstr( "rec()" ), GapObj )    # a GAP record
true

julia> isa( GAP.evalstr( "(1,2,3)" ), GapObj )  # a GAP permutation
true

julia> isa( GAP.evalstr( "2^64" ), GapObj )     # a large GAP integer
true

julia> typeof( GAP.evalstr( "2^59" ) )          # a small GAP integer
Int64

julia> typeof( GAP.evalstr( "Z(2)" ) )          # a GAP FFE
FFE

julia> typeof( GAP.evalstr( "true" ) )          # a Boolean
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

# Examples
```jldoctest
julia> GapObj(1//3)
GAP: 1/3

julia> GapObj([1 2; 3 4])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

```
"""
const GapObj = GAP_jll.MPtr

# TODO: should we document Obj? What about ForeignGAP.MPtr?
const Obj = Union{GapObj,FFE,Int64,Bool,Nothing}

export FFE, GapObj
