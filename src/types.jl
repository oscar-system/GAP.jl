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

_declare_gap_obj() = @ccall libgap.GAP_DeclareGapObj(:GapObj::Symbol, GAP::Module, Any::Any)::Any

_declare_bag(sym::Symbol, large::Bool) = @ccall libgap.GAP_DeclareBag(sym::Symbol, GAP::Module, Any::Any, large::Cint)::Any

const GapObj = _declare_gap_obj()::Type

const SmallBag = _declare_bag(:SmallBag, false)

const LargeBag = _declare_bag(:LargeBag, true)


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
julia> typeof(GapObj([1, 2]))          # a GAP list
GapObj

julia> typeof(GapObj(Dict(:a => 1)))   # a GAP record
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
in order to convert Julia objects to GAP objects,
see [`GapObj(x, cache::GapCacheDict = nothing; recursive::Bool = false)`](@ref)
for that.
""" GapObj


"""
    GAP.Obj

This is an alias for `Union{GapObj,FFE,Int64,Bool}`.
This type union covers all types a "native" GAP object may have
from Julia's viewpoint.

Moreover, it can be used as a constructor,
in order to convert Julia objects to GAP objects,
whenever a suitable conversion has been defined.

Recursive conversion of nested Julia objects (arrays, tuples, dictionaries)
can be forced either by a second argument `true`
or by the keyword argument `recursive` with value `true`.

# Examples
```jldoctest
julia> GAP.Obj(1//3)
GAP: 1/3

julia> GAP.Obj([1 2; 3 4])
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GAP.Obj([[1, 2], [3, 4]])
GAP: [ <Julia: [1, 2]>, <Julia: [3, 4]> ]

julia> GAP.Obj([[1, 2], [3, 4]], true)
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GAP.Obj([[1, 2], [3, 4]], recursive=true)
GAP: [ [ 1, 2 ], [ 3, 4 ] ]

julia> GAP.Obj(42)
42
```
"""
const Obj = Union{GapObj,FFE,Int64,Bool}

"""
    GapInt

Any GAP integer object is represented in Julia as either a `GapObj` (if it
is a "large" integer) or as an `Int` (if it is a "small" integer). This
type union can be used to express this conveniently, e.g. when one wants to
help type stability.

Note that also GAP's `infinity` and `-infinity` fit under this type (as do
many other objects which are not numbers).
"""
const GapInt = Union{GapObj,Int}

# Don't export GAP.Obj!
export FFE, GapObj, GapInt
