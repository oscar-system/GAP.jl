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
GAP.@install function GapObj(obj::ZZRingElem)
  Nemo._fmpz_is_small(obj) && return GapObj(Int(obj))
  GC.@preserve obj begin
    x = Nemo._as_bigint(obj)
    return ccall((:MakeObjInt, GAP.libgap), GapObj, (Ptr{UInt64}, Cint), x.d, x.size)
  end
end

## `QQFieldElem` to GAP rational
GAP.@install GapObj(obj::QQFieldElem) = Wrappers.QUO(GapObj(numerator(obj)), GapObj(denominator(obj)))

## `PosInf` to GAP infinity
GAP.@install GapObj(obj::PosInf) = GAP.Globals.infinity

## `ZZMatrix` to matrix of GAP integers
## TODO/FIXME: rewrite to not first convert to `Matrix`
GAP.@install GapObj(obj::ZZMatrix) = GapObj(Matrix(obj); recursive = true)

## `QQMatrix` to matrix of GAP rationals or integers
## TODO/FIXME: rewrite to not first convert to `Matrix`
GAP.@install GapObj(obj::QQMatrix) = GapObj(Matrix(obj); recursive = true)
