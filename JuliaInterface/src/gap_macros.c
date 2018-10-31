#include "libgap-api.h"

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
    if (jl_typeis(julia_obj, JULIA_GAPFFE_type)) {
        return gap_unbox_gapffe(julia_obj);
    }
    return NewJuliaObj(julia_obj);
}

jl_value_t * call_gap_func(void * func, jl_value_t * arg_array)
{
    jl_array_t * array_ptr = (jl_array_t *)arg_array;
    size_t       len = jl_array_len(array_ptr);
    Obj          return_value = NULL;
    if (IS_FUNC((Obj)func) && len <= 6) {
        switch (len) {
        case 0:
            return_value = CALL_0ARGS((Obj)func);
            break;
        case 1:
            return_value =
                CALL_1ARGS((Obj)func, gap_julia(jl_arrayref(array_ptr, 0)));
            break;
        case 2:
            return_value =
                CALL_2ARGS((Obj)func, gap_julia(jl_arrayref(array_ptr, 0)),
                           gap_julia(jl_arrayref(array_ptr, 1)));
            break;
        case 3:
            return_value =
                CALL_3ARGS((Obj)func, gap_julia(jl_arrayref(array_ptr, 0)),
                           gap_julia(jl_arrayref(array_ptr, 1)),
                           gap_julia(jl_arrayref(array_ptr, 2)));
            break;
        case 4:
            return_value =
                CALL_4ARGS((Obj)func, gap_julia(jl_arrayref(array_ptr, 0)),
                           gap_julia(jl_arrayref(array_ptr, 1)),
                           gap_julia(jl_arrayref(array_ptr, 2)),
                           gap_julia(jl_arrayref(array_ptr, 3)));
            break;
        case 5:
            return_value =
                CALL_5ARGS((Obj)func, gap_julia(jl_arrayref(array_ptr, 0)),
                           gap_julia(jl_arrayref(array_ptr, 1)),
                           gap_julia(jl_arrayref(array_ptr, 2)),
                           gap_julia(jl_arrayref(array_ptr, 3)),
                           gap_julia(jl_arrayref(array_ptr, 4)));
            break;
        case 6:
            return_value =
                CALL_6ARGS((Obj)func, gap_julia(jl_arrayref(array_ptr, 0)),
                           gap_julia(jl_arrayref(array_ptr, 1)),
                           gap_julia(jl_arrayref(array_ptr, 2)),
                           gap_julia(jl_arrayref(array_ptr, 3)),
                           gap_julia(jl_arrayref(array_ptr, 4)),
                           gap_julia(jl_arrayref(array_ptr, 5)));
            break;
        }
    }
    else {
        Obj arg_list = NEW_PLIST(T_PLIST, len);
        SET_LEN_PLIST(arg_list, len);
        for (size_t i = 0; i < len; i++) {
            SET_ELM_PLIST(arg_list, i + 1,
                          gap_julia(jl_arrayref(array_ptr, i)));
            CHANGED_BAG(arg_list);
        }
        return_value = CallFuncList((Obj)(func), arg_list);
    }
    if (return_value == NULL) {
        return jl_nothing;
    }
    return julia_gap(return_value);
}
