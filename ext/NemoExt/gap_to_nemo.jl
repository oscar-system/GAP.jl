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

## conversions of Nemo objects to Oscar objects
## (extends the conversions from GAP.jl's `src/gap_to_julia.jl` and
## `src/constructors.jl`, where low level Julia objects are treated)

##
## GAP integer to `ZZRingElem`
##
function ZZRingElem(obj::GapObj)
  GAP.GAP_IS_INT(obj) || throw(GAP.ConversionError(obj, ZZRingElem))
  result = GC.@preserve obj ZZRingElem(GAP.ADDR_OBJ(obj), div(GAP.SIZE_OBJ(obj), sizeof(Int)))
  if obj < 0 
    return Nemo.neg!(result)
  else
    return result
  end
end

GAP.gap_to_julia_internal(::Type{ZZRingElem}, obj::GapInt, ::GAP.JuliaCacheDict, ::Val{recursive}) where recursive = ZZRingElem(obj)
(::ZZRing)(obj::GapObj) = ZZRingElem(obj)

##
## large GAP rational or integer to `QQFieldElem`
##
function QQFieldElem(obj::GapObj)
  GAP.GAP_IS_INT(obj) && return QQFieldElem(ZZRingElem(obj))
  GAP.GAP_IS_RAT(obj) || throw(GAP.ConversionError(obj, QQFieldElem))
  return QQFieldElem(ZZRingElem(Wrappers.NumeratorRat(obj)), ZZRingElem(Wrappers.DenominatorRat(obj)))
end

GAP.gap_to_julia_internal(::Type{QQFieldElem}, obj::GapInt, ::GAP.JuliaCacheDict, ::Val{recursive}) where recursive = QQFieldElem(obj)
(::QQField)(obj::GapObj) = QQFieldElem(obj)

##
## matrix conversion
##

function __ensure_gap_matrix(obj::GapObj)
    @req Wrappers.IsMatrixOrMatrixObj(obj) "<obj> is not a GAP matrix"
end

##
## matrix of GAP integers to `ZZMatrix`
##
function ZZMatrix(obj::GapObj)
  __ensure_gap_matrix(obj)
  nrows = Wrappers.NumberRows(obj)
  ncols = Wrappers.NumberColumns(obj)
  m = zero_matrix(ZZ, nrows, ncols)
  for i in 1:nrows, j in 1:ncols
    x = obj[i,j]
    @inbounds m[i,j] = x isa Int ? x : ZZRingElem(x::GapObj)
  end
  return m
end

GAP.gap_to_julia_internal(::Type{ZZMatrix}, obj::GapObj, ::GAP.JuliaCacheDict, ::Val{recursive}) where recursive = ZZMatrix(obj)

##
## matrix of GAP rationals or integers to `QQMatrix`
##
function QQMatrix(obj::GapObj)
  __ensure_gap_matrix(obj)
  nrows = Wrappers.NumberRows(obj)
  ncols = Wrappers.NumberColumns(obj)
  m = zero_matrix(QQ, nrows, ncols)
  for i in 1:nrows, j in 1:ncols
    x = obj[i,j]
    @inbounds m[i,j] = x isa Int ? x : QQFieldElem(x::GapObj)
  end
  return m
end

GAP.gap_to_julia_internal(::Type{QQMatrix}, obj::GapObj, ::GAP.JuliaCacheDict, ::Val{recursive}) where recursive = QQMatrix(obj)

##
## generic matrix() method for GAP matrices which converts each element on its
## own: this is inefficient but almost always works, so we use it as our base
## case
##
function matrix(R::Ring, obj::GapObj)
  # TODO: add special code for compressed matrices, resp. MatrixObj, so that
  # we can perform the characteristic check once, instead of nrows*ncols
  # times
  __ensure_gap_matrix(obj)
  nrows = Wrappers.NumberRows(obj)
  ncols = Wrappers.NumberColumns(obj)
  m = zero_matrix(R, nrows, ncols)
  for i in 1:nrows, j in 1:ncols
    x = obj[i,j]::Union{Int,GapObj,GAP.FFE} # type annotation so Julia generates better code
    @inbounds m[i,j] = x isa Int ? x : R(x)
  end
  return m
end

# also allow map_entries to make Claus happy ;-)
map_entries(R::Ring, obj::GapObj) = matrix(R, obj)
