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

## conversions of Nemo objects to GAP objects
## (extends the conversions from GAP.jl's `src/julia_to_gap.jl`,
## where low level Julia objects are treated)

## `ZZRingElem` to GAP integer
GAP.@install function GapObj(obj::Nemo.ZZRingElemOrPtr)
  Nemo._fmpz_is_small(obj) && return GapObj(data(obj))
  GC.@preserve obj begin
    x = Nemo._as_bigint(obj)
    return ccall((:MakeObjInt, GAP.libgap), GapObj, (Ptr{UInt64}, Cint), x.d, x.size)
  end
end

GapInt(obj::ZZRingElem) = GapObj(obj)

## `QQFieldElem` to GAP rational
GAP.@install function GapObj(obj::Nemo.QQFieldElemOrPtr)
  GC.@preserve obj begin
    n = GapObj(Nemo._num_ptr(obj))
    d = GapObj(Nemo._den_ptr(obj))
    return Wrappers.QUO(n, d)
  end
end

## `PosInf` and `NegInf` to GAP infinity
GAP.@install GapObj(obj::PosInf) = GAP.Globals.infinity
GAP.@install GapObj(obj::NegInf) = -GAP.Globals.infinity

## Convert matrix
function GAP.GapObj_internal(
    obj::MatElem{T},
    recursion_dict::GapCacheDict,
    ::Val{recursive},
) where {T, recursive}

    recursive && recursion_dict !== nothing && haskey(recursion_dict, obj) && return recursion_dict[obj]

    rows = nrows(obj)
    cols = ncols(obj)
    ret_val = GAP.NewPlist(rows)

    recursion_dict = GAP.recursion_info_g(T, obj, ret_val, GAP.BoolVal(recursive), recursion_dict)

    for i = 1:rows
        r = ret_val[i] = GAP.NewPlist(cols)
        for j = 1:cols
            x = obj[i, j]
            y = GAP.GapObj_internal(x, recursion_dict, GAP.BoolVal(recursive))
            r[j] = y
        end
    end
    return ret_val
end

function GAP.GapObj_internal(obj::Union{ZZMatrix,QQMatrix}, ::GapCacheDict, ::Val)
    rows = nrows(obj)
    cols = ncols(obj)
    ret_val = GAP.NewPlist(rows)

    for i = 1:rows
        r = ret_val[i] = GAP.NewPlist(cols)
        for j = 1:cols
            ptr = Nemo.mat_entry_ptr(obj, i, j)
            y = GapObj(ptr)
            r[j] = y
        end
    end
    return ret_val
end


## element of cyclotomic field to GAP cyclotomic
GAP.@install function GapObj(obj::AbsSimpleNumFieldElem)
    F = parent(obj)
    @req Nemo.is_cyclo_type(F) "the element does not lie in a cyclotomic field"
    N = get_attribute(F, :cyclo)
    v = zeros(QQFieldElem, N)
    coeffs = coefficients(obj)
    v[1:length(coeffs)] = coeffs
    return GAPWrap.CycList(GapObj(v; recursive = true))
end

## `QQAbFieldElem` to GAP cyclotomic
GAP.@install function GapObj(elm::QQAbFieldElem)
    coeffs = [Nemo.coeff(elm.data, i) for i in 0:(elm.c-1)]  # QQFieldElem
    return GAPWrap.CycList(GapObj(coeffs; recursive = true))
end

## matrix of elements of cyclotomic field to GAP matrix of cyclotomics
GAP.@install function GapObj(obj::AbstractAlgebra.Generic.MatSpaceElem{AbsSimpleNumFieldElem})
    F = base_ring(obj)
    @req Nemo.is_cyclo_type(F) "the matrix entries do not lie in a cyclotomic field"
    mat = [GapObj(obj[i,j]) for i in 1:nrows(obj), j in 1:ncols(obj)]
    return GapObj(mat)
end
