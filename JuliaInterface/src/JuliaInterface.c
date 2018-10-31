/*
 * JuliaInterface: Test interface to julia
 */

#include "JuliaInterface.h"

static jl_value_t *    JULIA_ERROR_IOBuffer;
static jl_function_t * JULIA_FUNC_take_inplace;
static jl_function_t * JULIA_FUNC_String_constructor;
static jl_function_t * JULIA_FUNC_showerror;
static jl_datatype_t * JULIA_GAPFFE_type;

Obj TheTypeJuliaObject;
UInt T_JULIA_OBJ;

static jl_value_t * _ConvertedToJulia_internal(Obj obj);


static Obj DoCallJuliaFunc0Arg(Obj func);
static Obj DoCallJuliaFunc0ArgConv(Obj func);

void handle_jl_exception(void)
{
    jl_call2(JULIA_FUNC_showerror, JULIA_ERROR_IOBuffer,
             jl_exception_occurred());
    jl_value_t * string_object =
        jl_call1(JULIA_FUNC_take_inplace, JULIA_ERROR_IOBuffer);
    string_object =
        jl_call1(JULIA_FUNC_String_constructor, string_object);
    ErrorMayQuit(jl_string_data(string_object), 0, 0);
}

jl_module_t * get_module_from_string(char * name)
{
    // It suffices to use JULIAINTERFACE_EXCEPTION_HANDLER here, as
    // jl_eval_string is part of the jlapi, so don't have to be wrapped in
    // JL_TRY/JL_CATCH.
    jl_value_t * module_value = jl_eval_string(name);
    JULIAINTERFACE_EXCEPTION_HANDLER
    if (!jl_is_module(module_value))
        ErrorQuit("Not a module", 0, 0);
    return (jl_module_t *)module_value;
}

// This function needs to be called after the `gaptypes.jl`
// file is loaded into Julia and the GAP module is present.
// Therefore we do not call in InitKernel, but in the `read.g` file.
Obj Func_InitializeGAPFFEType()
{
    JULIA_GAPFFE_type = (jl_datatype_t *)jl_new_primitivetype(
        (jl_value_t *)jl_symbol("GapFFE"), get_module_from_string("GAP"),
        jl_any_type, jl_emptysvec, sizeof(Obj) * 8);
    jl_set_const(get_module_from_string("GAP"), jl_symbol("GapFFE"),
                 (jl_value_t *)JULIA_GAPFFE_type);
    return NULL;
}

jl_value_t * gap_box_gapffe(Obj value)
{
    jl_ptls_t    ptls = jl_get_ptls_states();
    jl_value_t * v = jl_gc_alloc_typed(ptls, sizeof(Obj), JULIA_GAPFFE_type);
    *(Obj *)jl_data_ptr(v) = value;
    return v;
}

Obj gap_unbox_gapffe(jl_value_t * gapffe)
{
    return *(Obj *)jl_data_ptr(gapffe);
}

#include "gap_macros.c"

// FIXME: get rid of IS_JULIA_FUNC??
static inline Int IS_JULIA_FUNC(Obj obj)
{
    return IS_FUNC(obj) && (HDLR_FUNC(obj, 0) == DoCallJuliaFunc0Arg ||
                            HDLR_FUNC(obj, 0) == DoCallJuliaFunc0ArgConv);
}

static inline jl_function_t * GET_JULIA_FUNC(Obj obj)
{
    GAP_ASSERT(IS_JULIA_FUNC(obj));
    // TODO
    return (jl_function_t *)FEXS_FUNC(obj);
}

static ALWAYS_INLINE Obj DoCallJuliaFunc(Obj       func,
                                         const int narg,
                                         Obj *     a,
                                         const int autoConvert)
{
    jl_value_t * result;

    if (autoConvert) {
        for (int i = 0; i < narg; i++) {
            a[i] = (Obj)_ConvertedToJulia_internal(a[i]);
        }
    }
    else {
        for (int i = 0; i < narg; i++) {
            if (IS_INTOBJ(a[i]))
                a[i] = (Obj)jl_box_int64(INT_INTOBJ(a[i]));
            else if (IS_FFE(a[i]))
                ErrorQuit("TODO: implement conversion for T_FFE", 0, 0);
        }
    }
    jl_function_t * f = GET_JULIA_FUNC(func);
    switch (narg) {
    case 0:
        result = jl_call0(f);
        break;
    case 1:
        result = jl_call1(f, (jl_value_t *)a[0]);
        break;
    case 2:
        result = jl_call2(f, (jl_value_t *)a[0], (jl_value_t *)a[1]);
        break;
    case 3:
        result = jl_call3(f, (jl_value_t *)a[0], (jl_value_t *)a[1],
                          (jl_value_t *)a[2]);
        break;
    default:
        result = jl_call(f, (jl_value_t **)a, narg);
    }
    // It suffices to use JULIAINTERFACE_EXCEPTION_HANDLER here, as jl_call
    // and its variants are part of the jlapi, so don't have to be wrapped in
    // JL_TRY/JL_CATCH.
    JULIAINTERFACE_EXCEPTION_HANDLER
    if (IsGapObj(result))
        return (Obj)result;
    return NewJuliaObj(result);
}

static Obj DoCallJuliaFunc0ArgConv(Obj func)
{
    return DoCallJuliaFunc(func, 0, 0, 1);
}

static Obj DoCallJuliaFunc1ArgConv(Obj func, Obj arg1)
{
    Obj a[] = { arg1 };
    return DoCallJuliaFunc(func, 1, a, 1);
}

static Obj DoCallJuliaFunc2ArgConv(Obj func, Obj arg1, Obj arg2)
{
    Obj a[] = { arg1, arg2 };
    return DoCallJuliaFunc(func, 2, a, 1);
}

static Obj DoCallJuliaFunc3ArgConv(Obj func, Obj arg1, Obj arg2, Obj arg3)
{
    Obj a[] = { arg1, arg2, arg3 };
    return DoCallJuliaFunc(func, 3, a, 1);
}

static Obj
DoCallJuliaFunc4ArgConv(Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4)
{
    Obj a[] = { arg1, arg2, arg3, arg4 };
    return DoCallJuliaFunc(func, 4, a, 1);
}

static Obj DoCallJuliaFunc5ArgConv(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5)
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5 };
    return DoCallJuliaFunc(func, 5, a, 1);
}

static Obj DoCallJuliaFunc6ArgConv(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5, Obj arg6)
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5, arg6 };
    return DoCallJuliaFunc(func, 6, a, 1);
}

static Obj DoCallJuliaFuncXArgConv(Obj func, Obj args)
{
    const int len = LEN_PLIST(args);
    Obj       a[len];
    for (int i = 0; i < len; i++) {
        a[i] = ELM_PLIST(args, i + 1);
    }
    return DoCallJuliaFunc(func, len, a, 1);
}

//
//
//


static Obj DoCallJuliaFunc0Arg(Obj func)
{
    return DoCallJuliaFunc(func, 0, 0, 0);
}

static Obj DoCallJuliaFunc1Arg(Obj func, Obj arg1)
{
    Obj a[] = { arg1 };
    return DoCallJuliaFunc(func, 1, a, 0);
}

static Obj DoCallJuliaFunc2Arg(Obj func, Obj arg1, Obj arg2)
{
    Obj a[] = { arg1, arg2 };
    return DoCallJuliaFunc(func, 2, a, 0);
}

static Obj DoCallJuliaFunc3Arg(Obj func, Obj arg1, Obj arg2, Obj arg3)
{
    Obj a[] = { arg1, arg2, arg3 };
    return DoCallJuliaFunc(func, 3, a, 0);
}

static Obj
DoCallJuliaFunc4Arg(Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4)
{
    Obj a[] = { arg1, arg2, arg3, arg4 };
    return DoCallJuliaFunc(func, 4, a, 0);
}

static Obj DoCallJuliaFunc5Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5)
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5 };
    return DoCallJuliaFunc(func, 5, a, 0);
}

static Obj DoCallJuliaFunc6Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5, Obj arg6)
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5, arg6 };
    return DoCallJuliaFunc(func, 6, a, 0);
}

static Obj DoCallJuliaFuncXArg(Obj func, Obj args)
{
    const int len = LEN_PLIST(args);
    Obj       a[len];
    for (int i = 0; i < len; i++) {
        a[i] = ELM_PLIST(args, i + 1);
    }
    return DoCallJuliaFunc(func, len, a, 0);
}


//
//
//
Obj NewJuliaFunc(jl_function_t * function, int autoConvert)
{
    // TODO: set a sensible name?
    //     jl_datatype_t * dt = ...
    //     jl_typename_t * tname = dt->name;
    //     //    struct _jl_methtable_t *mt;
    //     jl_sym_t *name = tname->mt->name;

    Obj func = NewFunctionC("", -1, "arg", 0);

    SET_HDLR_FUNC(
        func, 0, autoConvert ? DoCallJuliaFunc0ArgConv : DoCallJuliaFunc0Arg);
    SET_HDLR_FUNC(
        func, 1, autoConvert ? DoCallJuliaFunc1ArgConv : DoCallJuliaFunc1Arg);
    SET_HDLR_FUNC(
        func, 2, autoConvert ? DoCallJuliaFunc2ArgConv : DoCallJuliaFunc2Arg);
    SET_HDLR_FUNC(
        func, 3, autoConvert ? DoCallJuliaFunc3ArgConv : DoCallJuliaFunc3Arg);
    SET_HDLR_FUNC(
        func, 4, autoConvert ? DoCallJuliaFunc4ArgConv : DoCallJuliaFunc4Arg);
    SET_HDLR_FUNC(
        func, 5, autoConvert ? DoCallJuliaFunc5ArgConv : DoCallJuliaFunc5Arg);
    SET_HDLR_FUNC(
        func, 6, autoConvert ? DoCallJuliaFunc6ArgConv : DoCallJuliaFunc6Arg);
    SET_HDLR_FUNC(
        func, 7, autoConvert ? DoCallJuliaFuncXArgConv : DoCallJuliaFuncXArg);

    // trick: fexs is unused for kernel functions, so we can store
    // the Julia function point in here
    SET_FEXS_FUNC(func, (Obj)function);

    return func;
}

/*
 * C function pointer calls
 */

static inline ObjFunc get_c_function_pointer(Obj func)
{
    return jl_unbox_voidpointer((jl_value_t *)FEXS_FUNC(func));
}

static Obj DoCallJuliaCFunc0Arg(Obj func)
{
    ObjFunc function = get_c_function_pointer(func);
    Obj     result;
    BEGIN_JULIA
        result = function();
    END_JULIA
    return result;
}

static Obj DoCallJuliaCFunc1Arg(Obj func, Obj arg1)
{
    ObjFunc function = get_c_function_pointer(func);
    Obj     result;
    BEGIN_JULIA
        result = function(arg1);
    END_JULIA
    return result;
}

static Obj DoCallJuliaCFunc2Arg(Obj func, Obj arg1, Obj arg2)
{
    ObjFunc function = get_c_function_pointer(func);
    Obj     result;
    BEGIN_JULIA
        result = function(arg1, arg2);
    END_JULIA
    return result;
}

static Obj DoCallJuliaCFunc3Arg(Obj func, Obj arg1, Obj arg2, Obj arg3)
{
    ObjFunc function = get_c_function_pointer(func);
    Obj     result;
    BEGIN_JULIA
        result = function(arg1, arg2, arg3);
    END_JULIA
    return result;
}

static Obj
DoCallJuliaCFunc4Arg(Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4)
{
    ObjFunc function = get_c_function_pointer(func);
    Obj     result;
    BEGIN_JULIA
        result = function(arg1, arg2, arg3, arg4);
    END_JULIA
    return result;
}

static Obj DoCallJuliaCFunc5Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5)
{
    ObjFunc function = get_c_function_pointer(func);
    Obj     result;
    BEGIN_JULIA
        result = function(arg1, arg2, arg3, arg4, arg5);
    END_JULIA
    return result;
}

static Obj DoCallJuliaCFunc6Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5, Obj arg6)
{
    ObjFunc function = get_c_function_pointer(func);
    Obj     result;
    BEGIN_JULIA
        result = function(arg1, arg2, arg3, arg4, arg5, arg6);
    END_JULIA
    return result;
}


Obj NewJuliaCFunc(void * function, Obj arg_names)
{
    ObjFunc handler;

    switch (LEN_PLIST(arg_names)) {
    case 0:
        handler = DoCallJuliaCFunc0Arg;
        break;
    case 1:
        handler = DoCallJuliaCFunc1Arg;
        break;
    case 2:
        handler = DoCallJuliaCFunc2Arg;
        break;
    case 3:
        handler = DoCallJuliaCFunc3Arg;
        break;
    case 4:
        handler = DoCallJuliaCFunc4Arg;
        break;
    case 5:
        handler = DoCallJuliaCFunc5Arg;
        break;
    case 6:
        handler = DoCallJuliaCFunc6Arg;
        break;
    default:
        ErrorQuit("Only 0-6 arguments are supported", 0, 0);
        break;
    }

    Obj func = NewFunction(0, LEN_PLIST(arg_names), arg_names, handler);

    // trick: fexs is unused for kernel functions, so we can store
    // the function pointer here. Since fexs gets marked by the GC, we
    // store it as a valid julia obj (i.e., void ptr).
    SET_FEXS_FUNC(func, (Obj)jl_box_voidpointer(function));

    return func;
}

static Obj Func_NewJuliaCFunc(Obj self,
                       Obj julia_function_ptr,
                       Obj arg_names)
{
    jl_value_t * func_ptr = GET_JULIA_OBJ(julia_function_ptr);
    void *       ptr = jl_unbox_voidpointer(func_ptr);
    return NewJuliaCFunc(ptr, arg_names);
}

/*
 * utilities for wrapped Julia objects and functions
 */
static Obj JuliaObjCopyFunc(Obj obj, Int mut)
{
    /* always immutable in GAP, so nothing to do */
    return obj;
}

static void JuliaObjCleanFunc(Obj obj)
{
}

static Int JuliaObjIsMutableFunc(Obj obj)
{
    /* always immutable as GAP object */
    return 0L;
}

void SET_JULIA_OBJ(Obj o, jl_value_t * p)
{
    ADDR_OBJ(o)[0] = (Obj)p;
}

jl_value_t * GET_JULIA_OBJ(Obj o)
{
    return (jl_value_t *)(ADDR_OBJ(o)[0]);
}

static Obj JuliaObjectTypeFunc(Obj o)
{
    return TheTypeJuliaObject;
}

Obj NewJuliaObj(jl_value_t * C)
{
    if (IsGapObj(C))
        return (Obj)C;
    Obj o;
    o = NewBag(T_JULIA_OBJ, 1 * sizeof(Obj));
    SET_JULIA_OBJ(o, C);
    return o;
}


jl_function_t * get_function_from_obj_or_string(Obj func)
{
    if (IS_JULIA_OBJ(func)) {
        return (jl_function_t *)GET_JULIA_OBJ(func);
    }
    if (IS_STRING_REP(func)) {
        // jl_get_function is a thin wrapper for jl_get_global and never
        // throws an exception
        jl_function_t * function =
            jl_get_function(jl_main_module, CSTR_STRING(func));
        if (function == 0) {
            ErrorMayQuit("Function is not defined in julia", 0, 0);
        }
        return function;
    }
    ErrorMayQuit("argument is not a julia object or string", 0, 0);
    return 0;
}


/*
 * Returns the function from the Object <func>
 * or the function with name <func> from
 * the Julia main module.
 */
static Obj Func_JuliaFunction(Obj self, Obj func, Obj autoConvert)
{
    jl_function_t * function = get_function_from_obj_or_string(func);
    return NewJuliaFunc(function, autoConvert == True);
}

/*
 * Returns the function with name <function_name> from the Julia module with
 * name <module_name>.
 */
static Obj Func_JuliaFunctionByModule(Obj self, Obj function_name, Obj module_name, Obj autoConvert)
{
    jl_module_t * module_t = get_module_from_string(CSTR_STRING(module_name));
    // jl_get_function is a thin wrapper for jl_get_global and never throws
    // an exception
    jl_function_t * function =
        jl_get_function(module_t, CSTR_STRING(function_name));
    if (function == 0)
        ErrorMayQuit("Function is not defined in julia", 0, 0);
    return NewJuliaFunc(function, autoConvert == True);
}

// Executes the string <string> in the current julia session.
static Obj FuncJuliaEvalString(Obj self, Obj string)
{
    char * current = CSTR_STRING(string);
    char   copy[strlen(current) + 1];
    strcpy(copy, current);

    // It suffices to use JULIAINTERFACE_EXCEPTION_HANDLER here, as
    // jl_eval_string is part of the jlapi, so don't have to be wrapped in
    // JL_TRY/JL_CATCH.
    jl_value_t * result = jl_eval_string(copy);
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj(result);
}

// Converts the julia value pointer <julia_obj> into a GAP object
// if possible.
Obj _ConvertedFromJulia_internal(jl_value_t * julia_obj)
{
    size_t i;

    // small int
    if (jl_typeis(julia_obj, jl_int64_type)) {
        return ObjInt_Int8(jl_unbox_int64(julia_obj));
    }
    if (jl_typeis(julia_obj, jl_int32_type)) {
        return ObjInt_Int(jl_unbox_int32(julia_obj));
    }
    if (jl_typeis(julia_obj, jl_int16_type)) {
        return INTOBJ_INT(jl_unbox_int16(julia_obj));
    }
    if (jl_typeis(julia_obj, jl_int8_type)) {
        return INTOBJ_INT(jl_unbox_int8(julia_obj));
    }
    if (jl_typeis(julia_obj, jl_uint64_type)) {
        return ObjInt_UInt8(jl_unbox_uint64(julia_obj));
    }
    if (jl_typeis(julia_obj, jl_uint32_type)) {
        return ObjInt_UInt(jl_unbox_uint32(julia_obj));
    }
    if (jl_typeis(julia_obj, jl_uint16_type)) {
        return INTOBJ_INT(jl_unbox_uint16(julia_obj));
    }
    if (jl_typeis(julia_obj, jl_uint8_type)) {
        return INTOBJ_INT(jl_unbox_uint8(julia_obj));
    }

    // float
    else if (jl_typeis(julia_obj, jl_float64_type)) {
        return NEW_MACFLOAT(jl_unbox_float64(julia_obj));
    }
    else if (jl_typeis(julia_obj, jl_float32_type)) {
        return NEW_MACFLOAT(jl_unbox_float32(julia_obj));
    }

    // string
    else if (jl_typeis(julia_obj, jl_string_type)) {
        Obj return_string;
        C_NEW_STRING(return_string, jl_string_len(julia_obj),
                     jl_string_data(julia_obj));
        return return_string;
    }

    // bool
    else if (jl_typeis(julia_obj, jl_bool_type)) {
        if (jl_unbox_bool(julia_obj) == 0) {
            return False;
        }
        else {
            return True;
        }
    }

    // array (1-dim)
    else if (jl_is_array(julia_obj)) {
        Obj          current_element;
        jl_array_t * array_ptr = (jl_array_t *)julia_obj;
        size_t       len = jl_array_len(array_ptr);
        Obj          return_list = NEW_PLIST(T_PLIST, len);
        SET_LEN_PLIST(return_list, len);
        for (i = 0; i < len; i++) {
            if (!jl_array_isassigned(array_ptr, i)) {
                continue;
            }
            jl_value_t * current_jl_element = jl_arrayref(array_ptr, i);
            current_element = NewJuliaObj(current_jl_element);
            SET_ELM_PLIST(return_list, i + 1, current_element);
            CHANGED_BAG(return_list);
        }
        return return_list;
    }

    else if (jl_is_symbol(julia_obj)) {
        Obj    return_string;
        char * symbol_name = jl_symbol_name((jl_sym_t *)julia_obj);
        C_NEW_STRING(return_string, strlen(symbol_name), symbol_name);
        return return_string;
    }

    else if (IsGapObj(julia_obj)) {
        return (Obj)(julia_obj);
    }

    return Fail;
}

// Converts the julia object GAP object <obj> into a GAP object
// if possible.
static Obj Func_ConvertedFromJulia(Obj self, Obj obj)
{
    if (!IS_JULIA_OBJ(obj)) {
        ErrorMayQuit("<obj> is not a boxed julia obj", 0, 0);
        return NULL;
    }
    jl_value_t * julia_obj = GET_JULIA_OBJ(obj);
    return _ConvertedFromJulia_internal(julia_obj);
}

static jl_value_t * _ConvertedToJulia_internal(Obj obj)
{
    size_t i;
    Obj    current;

    // integer, small and large
    if (IS_INTOBJ(obj)) {
        return jl_box_int64(INT_INTOBJ(obj));
        // TODO: BIGINT
    }

    // float
    else if (IS_MACFLOAT(obj)) {
        return jl_box_float64(VAL_MACFLOAT(obj));
    }

    // string
    else if (IS_STRING_REP(obj)) {
        return jl_cstr_to_string(CSTR_STRING(obj));
    }

    // bool
    else if (obj == True) {
        return jl_true;
    }
    else if (obj == False) {
        return jl_false;
    }

    // perm
    else if (TNUM_OBJ(obj) == T_PERM2) {
        jl_value_t * array_type =
            jl_apply_array_type((jl_value_t *)jl_uint16_type, 1);
        jl_array_t * new_perm_array =
            jl_alloc_array_1d(array_type, DEG_PERM2(obj));
        UInt2 * perm_array = ADDR_PERM2(obj);
        for (i = 0; i < DEG_PERM2(obj); i++) {
            jl_arrayset(new_perm_array, jl_box_uint16(perm_array[i]), i);
        }
        return (jl_value_t *)(new_perm_array);
    }

    else if (TNUM_OBJ(obj) == T_PERM4) {
        jl_value_t * array_type =
            jl_apply_array_type((jl_value_t *)jl_uint32_type, 1);
        jl_array_t * new_perm_array =
            jl_alloc_array_1d(array_type, DEG_PERM4(obj));
        UInt4 * perm_array = ADDR_PERM4(obj);
        for (i = 0; i < DEG_PERM4(obj); i++) {
            jl_arrayset(new_perm_array, jl_box_uint32(perm_array[i]), i);
        }
        return (jl_value_t *)(new_perm_array);
    }

    // plist
    else if (IS_PLIST(obj)) {
        size_t       len = LEN_PLIST(obj);
        jl_value_t * array_type =
            jl_apply_array_type((jl_value_t *)jl_any_type, 1);
        jl_array_t * new_array = jl_alloc_array_1d(array_type, len);
        for (i = 0; i < len; i++) {
            current = ELM_PLIST(obj, i + 1);
            if (current == NULL) {
                continue;
            }
            jl_arrayset(new_array,
                        _ConvertedToJulia_internal(ELM_PLIST(obj, i + 1)),
                        i);
        }
        return (jl_value_t *)(new_array);
    }

    // Julia object/function: relevant in recursive situations
    else if (IS_JULIA_OBJ(obj)) {
        return GET_JULIA_OBJ(obj);
    }
    else if (IS_JULIA_FUNC(obj)) {
        // TODO: do we really want this???
        return GET_JULIA_FUNC(obj);
    }

    return (jl_value_t *)(obj);
}

// Converts the GAP object <obj> into a suitable julia object GAP object, if
// possible, and returns that object. If the conversion is not possible, the
// function returns fail.
static Obj Func_ConvertedToJulia(Obj self, Obj obj)
{
    if (IS_JULIA_OBJ(obj) || IS_JULIA_FUNC(obj)) {
        return obj;
    }
    jl_value_t * julia_ptr = _ConvertedToJulia_internal(obj);
    if (julia_ptr == 0)
        return Fail;
    return NewJuliaObj(julia_ptr);
}

// <dict> must be a julia value GAP object,
// holding a pointer to a julia dict.
// The function returns a GAP list, consisting of two lists:
//  1. A list containing the keys
//  2. A list containing the values
static Obj Func_ConvertedFromJulia_record_dict(Obj self, Obj dict)
{
    if (!IS_JULIA_OBJ(dict)) {
        ErrorQuit("input must be a boxed julia object", 0, 0);
        return NULL;
    }
    // FIXME: Check for dict
    jl_value_t * julia_dict = GET_JULIA_OBJ(dict);

    // Currently, keys have offset 1, while values have offset 2.
    jl_array_t * dict_slots = (jl_array_t *)jl_get_field(julia_dict, "slots");
    jl_array_t * dict_indices =
        (jl_array_t *)jl_get_field(julia_dict, "keys");
    jl_array_t * dict_values = (jl_array_t *)jl_get_field(julia_dict, "vals");

    // Prepare lists of keys, values
    size_t len = jl_array_len(dict_indices);
    Obj    indices_gap = NEW_PLIST(T_PLIST, len);
    Obj    values_gap = NEW_PLIST(T_PLIST, len);

    //
    Obj          current_element;
    jl_value_t * current_value;
    jl_value_t * current_index;
    size_t       real_index = 0;

    // Store keys and values in GAP list
    for (size_t i = 0; i < len; ++i) {
        if (!jl_unbox_uint8(jl_arrayref(dict_slots, i))) {
            continue;
        }
        real_index++;
        current_value = jl_arrayref(dict_values, i);
        current_index = jl_arrayref(dict_indices, i);
        SET_ELM_PLIST(values_gap, real_index, NewJuliaObj(current_value));
        CHANGED_BAG(values_gap);
        SET_ELM_PLIST(indices_gap, real_index, NewJuliaObj(current_index));
        CHANGED_BAG(indices_gap);
    }

    SET_LEN_PLIST(indices_gap, real_index);
    SET_LEN_PLIST(values_gap, real_index);

    // Construct and return list
    Obj return_list = NEW_PLIST(T_PLIST, 2);
    SET_LEN_PLIST(return_list, 2);
    SET_ELM_PLIST(return_list, 1, indices_gap);
    CHANGED_BAG(return_list);
    SET_ELM_PLIST(return_list, 2, values_gap);
    CHANGED_BAG(return_list);
    return return_list;
}

// Converts the GAP list <list> into a julia tuple and returns the julia
// object GAP object which holds the pointer to that tuple.
static Obj FuncJuliaTuple(Obj self, Obj list)
{
    if (!IS_PLIST(list)) {
        ErrorMayQuit("argument is not a plain list", 0, 0);
    }

    jl_datatype_t * tuple_type = 0;
    jl_svec_t *     params = 0;
    jl_svec_t *     param_types = 0;
    jl_value_t *    result = 0;

    BEGIN_JULIA
        int len = LEN_PLIST(list);
        params = jl_alloc_svec(len);
        param_types = jl_alloc_svec(len);
        for (int i = 0; i < len; i++) {
            jl_value_t * current_obj =
                _ConvertedToJulia_internal(ELM_PLIST(list, i + 1));
            jl_svecset(params, i, current_obj);
            jl_svecset(param_types, i, jl_typeof(current_obj));
        }
        tuple_type = jl_apply_tuple_type(param_types);
        result = jl_new_structv(tuple_type, jl_svec_data(params), len);
    END_JULIA
    return NewJuliaObj(result);
}

// Returns a julia object GAP object that holds the pointer to a julia symbol
// :<name>.
static Obj FuncJuliaSymbol(Obj self, Obj name)
{
    if (!IS_STRING_REP(name)) {
        ErrorMayQuit("JuliaSymbol: <name> must be a string", 0, 0);
    }

    // jl_symbol never throws an exception and always returns a valid
    // result, so no need for extra checks.
    jl_sym_t * julia_symbol = jl_symbol(CSTR_STRING(name));
    return NewJuliaObj((jl_value_t *)julia_symbol);
}

// Returns a julia object GAP object that holds the pointer to the julia
// module <name>.
static Obj FuncJuliaModule(Obj self, Obj name)
{
    if (!IS_STRING_REP(name)) {
        ErrorMayQuit("JuliaModule: <name> must be a string", 0, 0);
    }

    jl_module_t * julia_module = get_module_from_string(CSTR_STRING(name));
    return NewJuliaObj((jl_value_t *)julia_module);
}

// Sets the value of the julia identifier <name> to the julia value the julia
// object GAP object <julia_val> points to.
// This function is for debugging purposes
static Obj FuncJuliaSetVal(Obj self, Obj name, Obj julia_val)
{
    jl_value_t * julia_obj = GET_JULIA_OBJ(julia_val);
    jl_sym_t *   julia_symbol = jl_symbol(CSTR_STRING(name));
    jl_set_global(jl_main_module, julia_symbol, julia_obj);
    return 0;
}

// Returns the julia object GAP object that holds a pointer to the value
// currently bound to the julia identifier <name>.
static Obj Func_JuliaGetGlobalVariable(Obj self, Obj name)
{
    if (!IS_STRING_REP(name)) {
        ErrorMayQuit("_JuliaGetGlobalVariable: <name> must be a string", 0, 0);
    }

    jl_sym_t * symbol = jl_symbol(CSTR_STRING(name));
    if (!jl_boundp(jl_main_module, symbol)) {
        return Fail;
    }
    jl_value_t * value = jl_get_global(jl_main_module, symbol);
    return NewJuliaObj(value);
}

// Returns the julia object GAP object that holds a pointer to the value
// currently bound to the julia identifier <module_name>.<name>.
static Obj Func_JuliaGetGlobalVariableByModule(Obj self, Obj name, Obj module)
{
    if (!IS_STRING_REP(name)) {
        ErrorMayQuit("_JuliaGetGlobalVariableByModule: <name> must be a string", 0, 0);
    }

    jl_module_t * m = 0;
    if (IS_JULIA_OBJ(module)) {
        m = (jl_module_t *)GET_JULIA_OBJ(module);
        if (!jl_is_module(m))
            m = 0;
    }
    else if (IS_STRING_REP(module)) {
        m = get_module_from_string(CSTR_STRING(module));
    }
    if (!m) {
        ErrorMayQuit("_JuliaGetGlobalVariableByModule: <module> must be a string or a Julia module", 0, 0);
    }
    jl_sym_t * symbol = jl_symbol(CSTR_STRING(name));
    if (!jl_boundp(m, symbol)) {
        return Fail;
    }
    jl_value_t * value = jl_get_global(m, symbol);
    return NewJuliaObj(value);
}

// Returns the julia object GAP object that holds a pointer to the value
// currently bound to <super_object>.<name>.
// <super_object> must be a julia object GAP object, and <name> a string.
static Obj FuncJuliaGetFieldOfObject(Obj self, Obj super_obj, Obj field_name)
{
    if (!IS_JULIA_OBJ(super_obj)) {
        ErrorMayQuit("JuliaGetFieldOfObject: <super_obj> must be a Julia object", 0, 0);
    }
    if (!IS_STRING_REP(field_name)) {
        ErrorMayQuit("JuliaGetFieldOfObject: <field_name> must be a string", 0, 0);
    }

    jl_value_t * extracted_superobj = GET_JULIA_OBJ(super_obj);

    // It suffices to use JULIAINTERFACE_EXCEPTION_HANDLER here, as
    // jl_get_field is part of the jlapi, so don't have to be wrapped in
    // JL_TRY/JL_CATCH.
    jl_value_t * field_value =
        jl_get_field(extracted_superobj, CSTR_STRING(field_name));
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj(field_value);
}


// Table of functions to export
static StructGVarFunc GVarFuncs[] = {
    GVAR_FUNC(_JuliaFunction, 2, "string, autoConvert"),
    GVAR_FUNC(
        _JuliaFunctionByModule, 3, "function_name, module_name, autoConvert"),
    GVAR_FUNC(JuliaEvalString, 1, "string"),
    GVAR_FUNC(_ConvertedFromJulia, 1, "obj"),
    GVAR_FUNC(_ConvertedToJulia, 1, "obj"),
    GVAR_FUNC(JuliaSetVal, 2, "name,val"),
    GVAR_FUNC(_JuliaGetGlobalVariable, 1, "name"),
    GVAR_FUNC(_JuliaGetGlobalVariableByModule, 2, "name,module"),
    GVAR_FUNC(JuliaGetFieldOfObject, 2, "obj,name"),
    GVAR_FUNC(JuliaTuple, 1, "list"),
    GVAR_FUNC(JuliaSymbol, 1, "name"),
    GVAR_FUNC(JuliaModule, 1, "name"),
    GVAR_FUNC(_ConvertedFromJulia_record_dict, 1, "dict"),
    GVAR_FUNC(_NewJuliaCFunc, 2, "ptr,arg_names"),
    GVAR_FUNC(_InitializeGAPFFEType, 0, ""),
    { 0 } /* Finish with an empty entry */

};

/****************************************************************************
**
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel(StructInitInfo * module)
{
    if (getenv("JULIA_TRACK_COVERAGE") != 0) {
        fprintf(stderr, "JULIA_TRACK_COVERAGE enabled\n");
        jl_options.code_coverage = JL_LOG_USER;
        jl_options.can_inline = 0;
    }

    // init filters and functions
    InitHdlrFuncsFromTable(GVarFuncs);

    InitCopyGVar("TheTypeJuliaObject", &TheTypeJuliaObject);

    T_JULIA_OBJ = RegisterPackageTNUM("JuliaObject", JuliaObjectTypeFunc);

    InitMarkFuncBags(T_JULIA_OBJ, &MarkOneSubBags);

    CopyObjFuncs[T_JULIA_OBJ] = &JuliaObjCopyFunc;
    CleanObjFuncs[T_JULIA_OBJ] = &JuliaObjCleanFunc;
    IsMutableObjFuncs[T_JULIA_OBJ] = &JuliaObjIsMutableFunc;

    // Initialize necessary variables for error handling
    JULIA_ERROR_IOBuffer =
        jl_eval_string("GAP_JULIA_ERROR_IO_BUFFER = Base.IOBuffer()");
    JULIA_FUNC_take_inplace = jl_get_function(jl_base_module, "take!");
    JULIA_FUNC_String_constructor = jl_get_function(jl_base_module, "String");
    JULIA_FUNC_showerror = jl_get_function(jl_base_module, "showerror");

    // return success
    return 0;
}

/****************************************************************************
**
*F  InitLibrary( <module> ) . . . . . . .  initialise library data structures
*/
static Int InitLibrary(StructInitInfo * module)
{
    // init filters and functions
    InitGVarFuncsFromTable(GVarFuncs);

    // return success
    return 0;
}

/****************************************************************************
**
*F  Init__Dynamic() . . . . . . . . . . . . . . . . . table of init functions
*/
StructInitInfo * Init__Dynamic(void)
{
    static StructInitInfo module = {
        .type = MODULE_DYNAMIC,
        .name = "JuliaInterface",
        .initKernel = InitKernel,
        .initLibrary = InitLibrary,
    };
    return &module;
}
