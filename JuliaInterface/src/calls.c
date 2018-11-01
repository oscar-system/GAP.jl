#include "calls.h"

#include "convert.h"

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
