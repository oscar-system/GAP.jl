#include "convert.h"

jl_value_t * julia_gap(Obj obj)
{
    if (IS_INTOBJ(obj)) {
        return jl_box_int64(INT_INTOBJ(obj));
    }
    if (IS_FFE(obj)) {
        return gap_box_gapffe(obj);
    }
    if (IS_JULIA_OBJ(obj)) {
        return GET_JULIA_OBJ(obj);
    }
    return (jl_value_t *)obj;
}

Obj gap_julia(jl_value_t * julia_obj)
{
    if (jl_typeis(julia_obj, jl_int64_type)) {
        return ObjInt_Int8(jl_unbox_int64(julia_obj));
    }
    if (IsGapObj(julia_obj)) {
        return (Obj)(julia_obj);
    }
    if (is_gapffe(julia_obj)) {
        return gap_unbox_gapffe(julia_obj);
    }
    return NewJuliaObj(julia_obj);
}

