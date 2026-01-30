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

module Wrappers

using GAP
import GAP: @wrap

@wrap Add(x::GapObj, y::Any)::Nothing
@wrap Add(x::GapObj, y::Any, z::Int)::Nothing
@wrap AdditiveInverseSameMutability(x::Any)::Any
@wrap Append(x::GapObj, y::GapObj)::Nothing
@wrap ASS_LIST(x::Any, i::Int, v::Any)::Nothing
@wrap ASS_MAT(x::Any, i::Int, j::Int, v::Any)::Nothing
@wrap ASS_REC(x::Any, y::Int, v::Any)::Nothing
@wrap AsSet(x::GapObj)::GapObj
@wrap ASSS_LIST(x::Any, y::Any, v::Any)::Any
@wrap Characteristic(x::Any)::GapInt
@wrap CHAR_FFE_DEFAULT(x::Any)::GapInt
@wrap CopyToStringRep(x::Any)::Any
@wrap DenominatorRat(x::Any)::GapInt
@wrap DIFF(x::Any, y::Any)::Any
@wrap Difference(x::Any, y::Any)::Any
@wrap DuplicateFreeList(x::GapObj)::GapObj
@wrap ELM_LIST(x::Any, i::Int)::Any
@wrap ELM_MAT(x::Any, i::Int, j::Int)::Any
@wrap ELM_REC(x::Any, y::Int)::Any
@wrap ELMS_LIST(x::Any, y::Any)::Any
@wrap EQ(x::Any, y::Any)::Bool
@wrap IN(x::Any, y::Any)::Bool
@wrap InfoLevel(x::GapObj)::Int
@wrap INT_CHAR(x::Any)::Int
@wrap InverseSameMutability(x::Any)::Any
@wrap IS_JULIA_FUNC(x::Any)::Bool
@wrap ISB_LIST(x::Any, i::Int)::Bool
@wrap ISB_REC(x::Any, y::Int)::Bool
@wrap IsBlist(x::Any)::Bool
@wrap IsBlistRep(x::Any)::Bool
@wrap IsCollection(x::Any)::Bool
@wrap IsDoneIterator(x::Any)::Bool
@wrap IsIterator(x::Any)::Bool
@wrap IsList(x::Any)::Bool
@wrap IsMatrixObj(x::Any)::Bool
@wrap IsMatrixOrMatrixObj(x::Any)::Bool
@wrap IsPackageLoaded(x::GapObj)::Bool
@wrap IsRange(x::Any)::Bool
@wrap IsRangeRep(x::Any)::Bool
@wrap IsRecord(x::Any)::Bool
@wrap IsSet(x::Any)::Bool
@wrap IsString(x::Any)::Bool
@wrap IsStringRep(x::Any)::Bool
@wrap IsVectorObj(x::Any)::Bool
@wrap Iterator(x::Any)::GapObj
@wrap Length(x::Any)::GapInt
@wrap LoadPackage(x::GapObj, y::GapObj, z::Bool)::Any
@wrap LowercaseString(x::GapObj)::GapObj
@wrap LQUO(x::Any, y::Any)::Any
@wrap LT(x::Any, y::Any)::Bool
@wrap MakeReadOnlyGlobal(x::Any)::Nothing
@wrap MakeReadWriteGlobal(x::Any)::Nothing
@wrap MOD(x::Any, y::Any)::Any
@wrap NextIterator(x::Any)::Any
@wrap NormalizedWhitespace(x::GapObj)::GapObj
@wrap NumberColumns(x::Any)::GapInt
@wrap NumberRows(x::Any)::GapInt
@wrap NumeratorRat(x::Any)::GapInt
@wrap OneSameMutability(x::Any)::Any
@wrap PopOptions()::Nothing
@wrap POW(x::Any, y::Any)::Any
@wrap PROD(x::Any, y::Any)::Any
@wrap PushOptions(x::Any)::Nothing
@wrap QUO(x::Any, y::Any)::Any
@wrap Read(x::GapObj)::Nothing
@wrap RecNames(x::Any)::Any
@wrap RNamObj(x::Any)::Int
@wrap SetInfoLevel(x::GapObj, y::Int)::Nothing
@wrap SetPackagePath(x::GapObj, y::GapObj)::Nothing
@wrap ShallowCopy(x::Any)::Any
@wrap Sort(x::GapObj)::Nothing
@wrap String(x::Any)::Any
@wrap StringDisplayObj(x::Any)::GapObj
@wrap StringViewObj(x::Any)::GapObj
@wrap StructuralCopy(x::Any)::Any
@wrap SUM(x::Any, y::Any)::Any
@wrap UNB_REC(x::GapObj, y::Int)::Nothing
@wrap ZeroSameMutability(x::Any)::Any

end
