#include "libgap-api.h"

// Provide other access functions.
Int LengthList(Obj list)
{
    return LEN_PLIST(list);
}

Obj Elm0_List(Obj list, int pos)
{
    return ELM_PLIST(list, pos);
}

Obj Call2Args(Obj func, Obj a1, Obj a2)
{
    return CALL_2ARGS(func, a1, a2);
}

jl_value_t * julia_gap(Obj obj)
{
    if (IS_INT(obj)) {
        return jl_box_int64(INT_INTOBJ(obj));
    }
    if (IS_FFE(obj)) {
        // TODO
        return jl_nothing;
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
    return NewJuliaObj(julia_obj);
}

jl_value_t * call_gap_func(void * func, jl_value_t * arg_array)
{
    jl_array_t * array_ptr = (jl_array_t *)arg_array;
    size_t       len = jl_array_len(array_ptr);
    Obj          arg_list = NEW_PLIST(T_PLIST, len);
    SET_LEN_PLIST(arg_list, len);
    for (size_t i = 0; i < len; i++) {
        SET_ELM_PLIST(arg_list, i + 1, gap_julia(jl_arrayref(array_ptr, i)));
        CHANGED_BAG(arg_list);
    }
    Obj return_val = CallFuncList((Obj)(func), arg_list);
    if (return_val == NULL) {
        return jl_nothing;
    }
    return julia_gap(return_val);
}

void JuliaInitializeGAPFunctionPointers()
{
    // the following are used by orbits.jl
    INITIALIZE_JULIA_CPOINTER(LengthList);
    INITIALIZE_JULIA_CPOINTER(Elm0_List);
    INITIALIZE_JULIA_CPOINTER(True);
    INITIALIZE_JULIA_CPOINTER(False);
    INITIALIZE_JULIA_CPOINTER(Call2Args);
    INITIALIZE_JULIA_CPOINTER(NewJuliaObj);

    INITIALIZE_JULIA_CPOINTER(call_gap_func);
    INITIALIZE_JULIA_CPOINTER(julia_gap);

    // Used in LibGAP.jl's ccall file

    INITIALIZE_JULIA_CPOINTER(GAP_EvalString);
    INITIALIZE_JULIA_CPOINTER(GAP_ValueGlobalVariable);
    INITIALIZE_JULIA_CPOINTER(GAP_MakeString);
    INITIALIZE_JULIA_CPOINTER(GAP_CSTR_STRING);
    INITIALIZE_JULIA_CPOINTER(GAP_NewPlist);
}
