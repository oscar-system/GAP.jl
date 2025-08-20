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


#############################################################################
##
## some utilities

## Show a specific error on conversion failure.
struct ConversionError <: Base.Exception
    obj::Any
    jl_type::Any
end

Base.showerror(io::IO, e::ConversionError) =
    print(io, "failed to convert $(typeof(e.obj)) to $(e.jl_type):\n $(e.obj)")


"""
    RecDict_j = IdDict{Tuple{Any, Type}, Any}

An internal type of GAP.jl used for tracking conversion results in `gap_to_julia`.
The value stored at the key `(obj, T)` is the result
of the GAP to Julia conversion of `obj` that has type `T`.
Note that several Julia types can occur for the same GAP object.

Lookups for the key `(obj, T)` in an `IdDict` are successful if the conversion
result of an object identical to `obj` with target type `T` has been stored
in the dictionary.

Note that comparing two `GapObj`s with `===` yields the same result as
comparing them with `GAP.Globals.IsIdenticalObj`
because `GapObj` is a mutable type.
"""
const RecDict_j = IdDict{Tuple{Any, Type}, Any}

const JuliaCacheDict = Union{Nothing,RecDict_j}


"""
    RecDict_g = IdDict{Any,Any}

An internal type of GAP.jl used for tracking conversion results in `julia_to_gap`.
The value stored at the key `obj` is the result
of the Julia to GAP conversion of `obj`.
"""
const RecDict_g = IdDict{Any,Any}

const GapCacheDict = Union{Nothing,RecDict_g}


# helper functions for recursion in conversion from GAP to Julia
function recursion_info_j(::Type{T}, obj, recursive::Bool, recursion_dict::JuliaCacheDict) where {T}
    if recursive && recursion_dict === nothing
        return RecDict_j()
    else
        return recursion_dict
    end
end


# helper functions for recursion (conversion from Julia to GAP)
function recursion_info_g(::Type{T}, obj, recursive::Bool, recursion_dict::GapCacheDict) where {T}
    rec = recursive && _needs_tracking_julia_to_gap(T)
    if rec && recursion_dict === nothing
        rec_dict = RecDict_g()
    else
        rec_dict = recursion_dict
    end
    
    return rec, rec_dict
end

function handle_recursion(obj, ret_val, rec::Bool, rec_dict::Union{Nothing,IdDict})
    if rec_dict !== nothing
        # We assume that `obj` is not yet cached.
        rec_dict[obj] = ret_val
    end
    return rec ? rec_dict : nothing
end
