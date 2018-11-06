#include "convert.h"

#include "JuliaInterface.h"

#include <src/compiled.h>    // GAP headers

// This function is used by LibGAP.jl
jl_value_t * julia_gap(Obj obj)
{
    if (obj == 0) {
        return jl_nothing;
    }
    if (IS_INTOBJ(obj)) {
        return jl_box_int64(INT_INTOBJ(obj));
    }
    if (IS_FFE(obj)) {
        return gap_box_gapffe(obj);
    }
    if (IS_JULIA_OBJ(obj)) {
        return GET_JULIA_OBJ(obj);
    }
    if (obj == True) {
        return jl_true;
    }
    if (obj == False) {
        return jl_false;
    }
    return (jl_value_t *)obj;
}

// This function is used by LibGAP.jl
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
    if (jl_typeis(julia_obj, jl_bool_type)) {
        return julia_obj == jl_true ? True : False;
    }
    return NewJuliaObj(julia_obj);
}
