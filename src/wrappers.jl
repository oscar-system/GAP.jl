module Wrappers

using GAP

@gapwrap AINV(x::Any) = GAP.Globals.AINV(x)::Any
@gapwrap ASS_LIST(x::Any, i::Int, v::Any) = GAP.Globals.ASS_LIST(x, i, v)::Nothing
@gapwrap ASS_MAT(x::Any, i::Int, j::Int, v::Any) = GAP.Globals.ASS_LIST(x, i, j, v)::Nothing
@gapwrap ASS_REC(x::Any, y::Int, v::Any) = GAP.Globals.ASS_REC(x, y, v)::Nothing
@gapwrap AsSet(x::Any) = GAP.Globals.AsSet(x)::Any
@gapwrap ASSS_LIST(x::Any, y::Any, v::Any) = GAP.Globals.ASSS_LIST(x, y, v)::Any
@gapwrap CopyToStringRep(x::Any) = GAP.Globals.CopyToStringRep(x)::Any
@gapwrap DenominatorRat(x::Any) = GAP.Globals.DenominatorRat(x)::GapInt
@gapwrap DIFF(x::Any, y::Any) = GAP.Globals.DIFF(x, y)::Any
@gapwrap Difference(x::Any, y::Any) = GAP.Globals.Difference(x, y)::Any
@gapwrap DuplicateFreeList(x::Any) = GAP.Globals.DuplicateFreeList(x)::Any
@gapwrap ELM_LIST(x::Any, i::Int) = GAP.Globals.ELM_LIST(x, i)::Any
@gapwrap ELM_MAT(x::Any, i::Int, j::Int) = GAP.Globals.ELM_MAT(x, i, j)::Any
@gapwrap ELM_REC(x::Any, y::Int) = GAP.Globals.ELM_REC(x, y)::Any
@gapwrap ELMS_LIST(x::Any, y::Any) = GAP.Globals.ELMS_LIST(x, y)::Any
@gapwrap EQ(x::Any, y::Any) = GAP.Globals.EQ(x, y)::Bool
@gapwrap IN(x::Any, y::Any) = GAP.Globals.IN(x, y)::Bool
@gapwrap INT_CHAR(x::Any) = GAP.Globals.INT_CHAR(x)::Int
@gapwrap INV_MUT(x::Any) = GAP.Globals.INV_MUT(x)::Any
@gapwrap IS_JULIA_FUNC(x::Any) = GAP.Globals.IS_JULIA_FUNC(x)::Bool
@gapwrap ISB_LIST(x::Any, i::Int) = GAP.Globals.ISB_LIST(x, i)::Bool
@gapwrap ISB_REC(x::Any, y::Int) = GAP.Globals.ISB_REC(x, y)::Bool
@gapwrap IsBlist(x::Any) = GAP.Globals.IsBlist(x)::Bool
@gapwrap IsBlistRep(x::Any) = GAP.Globals.IsBlistRep(x)::Bool
@gapwrap IsChar(x::Any) = GAP.Globals.IsChar(x)::Bool
@gapwrap IsCollection(x::Any) = GAP.Globals.IsCollection(x)::Bool
@gapwrap IsDoneIterator(x::Any) = GAP.Globals.IsDoneIterator(x)::Bool
@gapwrap IsEmpty(x::Any) = GAP.Globals.IsEmpty(x)::Bool
@gapwrap IsList(x::Any) = GAP.Globals.IsList(x)::Bool
@gapwrap IsMatrixObj(x::Any) = GAP.Globals.IsMatrixObj(x)::Bool
@gapwrap IsRange(x::Any) = GAP.Globals.IsRange(x)::Bool
@gapwrap IsRangeRep(x::Any) = GAP.Globals.IsRangeRep(x)::Bool
@gapwrap IsRecord(x::Any) = GAP.Globals.IsRecord(x)::Bool
@gapwrap IsSSortedList(x::Any) = GAP.Globals.IsSSortedList(x)::Bool
@gapwrap IsString(x::Any) = GAP.Globals.IsString(x)::Bool
@gapwrap IsStringRep(x::Any) = GAP.Globals.IsStringRep(x)::Bool
@gapwrap IsVectorObj(x::Any) = GAP.Globals.IsVectorObj(x)::Bool
@gapwrap Iterator(x::Any) = GAP.Globals.Iterator(x)::Any
@gapwrap Length(x::Any) = GAP.Globals.Length(x)::GapInt
@gapwrap LQUO(x::Any, y::Any) = GAP.Globals.LQUO(x, y)::Any
@gapwrap LT(x::Any, y::Any) = GAP.Globals.LT(x, y)::Bool
@gapwrap MOD(x::Any, y::Any) = GAP.Globals.MOD(x, y)::Any
@gapwrap NextIterator(x::Any) = GAP.Globals.NextIterator(x)::Any
@gapwrap NumberColumns(x::Any) = GAP.Globals.NumberColumns(x)::GapInt
@gapwrap NumberRows(x::Any) = GAP.Globals.NumberRows(x)::GapInt
@gapwrap NumeratorRat(x::Any) = GAP.Globals.NumeratorRat(x)::GapInt
@gapwrap ONE_MUT(x::Any) = GAP.Globals.ONE_MUT(x)::Any
@gapwrap PopOptions() = GAP.Globals.PopOptions()::Nothing
@gapwrap POW(x::Any, y::Any) = GAP.Globals.POW(x, y)::Any
@gapwrap PROD(x::Any, y::Any) = GAP.Globals.PROD(x, y)::Any
@gapwrap PushOptions(x::Any) = GAP.Globals.PushOptions(x)::Nothing
@gapwrap QUO(x::Any, y::Any) = GAP.Globals.QUO(x, y)::Any
@gapwrap RecNames(x::Any) = GAP.Globals.RecNames(x)::Any
@gapwrap RNamObj(x::Any) = GAP.Globals.RNamObj(x)::Int
@gapwrap ShallowCopy(x::Any) = GAP.Globals.ShallowCopy(x)::Any
@gapwrap String(x::Any) = GAP.Globals.String(x)::Any
@gapwrap StringDisplayObj(x::Any) = GAP.Globals.StringDisplayObj(x)::Any
@gapwrap StringViewObj(x::Any) = GAP.Globals.StringViewObj(x)::Any
@gapwrap StructuralCopy(x::Any) = GAP.Globals.StructuralCopy(x)::Any
@gapwrap SUM(x::Any, y::Any) = GAP.Globals.SUM(x, y)::Any
@gapwrap ZERO(x::Any) = GAP.Globals.ZERO(x)::Any

end
