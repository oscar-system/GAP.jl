#include "calls.h"
#include "convert.h"
#include "JuliaInterface.h"

#include <src/compiled.h>    // GAP headers

static Obj DoCallJuliaFunc0Arg(Obj func);


typedef struct {
    FuncBag f;
    Obj     juliaFunc;
} JuliaFuncBag;


// Helper used to call GAP functions from Julia.
//
// This function is used by GAP.jl
jl_value_t * call_gap_func(Obj func, jl_value_t * args)
{
    if (!jl_is_tuple(args))
        jl_error("<args> must be a tuple");

    size_t len = jl_nfields(args);
    Obj    return_value = NULL;
    if (IS_FUNC(func) && len <= 6) {
        switch (len) {
        case 0:
            return_value = CALL_0ARGS(func);
            break;
        case 1:
            return_value = CALL_1ARGS(func, gap_julia(jl_fieldref(args, 0)));
            break;
        case 2:
            return_value = CALL_2ARGS(func, gap_julia(jl_fieldref(args, 0)),
                                      gap_julia(jl_fieldref(args, 1)));
            break;
        case 3:
            return_value = CALL_3ARGS(func, gap_julia(jl_fieldref(args, 0)),
                                      gap_julia(jl_fieldref(args, 1)),
                                      gap_julia(jl_fieldref(args, 2)));
            break;
        case 4:
            return_value = CALL_4ARGS(func, gap_julia(jl_fieldref(args, 0)),
                                      gap_julia(jl_fieldref(args, 1)),
                                      gap_julia(jl_fieldref(args, 2)),
                                      gap_julia(jl_fieldref(args, 3)));
            break;
        case 5:
            return_value = CALL_5ARGS(func, gap_julia(jl_fieldref(args, 0)),
                                      gap_julia(jl_fieldref(args, 1)),
                                      gap_julia(jl_fieldref(args, 2)),
                                      gap_julia(jl_fieldref(args, 3)),
                                      gap_julia(jl_fieldref(args, 4)));
            break;
        case 6:
            return_value = CALL_6ARGS(func, gap_julia(jl_fieldref(args, 0)),
                                      gap_julia(jl_fieldref(args, 1)),
                                      gap_julia(jl_fieldref(args, 2)),
                                      gap_julia(jl_fieldref(args, 3)),
                                      gap_julia(jl_fieldref(args, 4)),
                                      gap_julia(jl_fieldref(args, 5)));
            break;
        }
    }
    else {
        Obj arg_list = NEW_PLIST(T_PLIST, len);
        SET_LEN_PLIST(arg_list, len);
        for (size_t i = 0; i < len; i++) {
            SET_ELM_PLIST(arg_list, i + 1, gap_julia(jl_fieldref(args, i)));
            CHANGED_BAG(arg_list);
        }
        return_value = CallFuncList(func, arg_list);
    }
    if (return_value == NULL) {
        return jl_nothing;
    }
    return julia_gap(return_value);
}


inline Int IS_JULIA_FUNC(Obj obj)
{
    return IS_FUNC(obj) && (HDLR_FUNC(obj, 0) == DoCallJuliaFunc0Arg);
}

inline jl_function_t * GET_JULIA_FUNC(Obj func)
{
    GAP_ASSERT(IS_JULIA_FUNC(func));
    return (jl_function_t *)GET_JULIA_OBJ(
        ((const JuliaFuncBag *)CONST_ADDR_OBJ(func))->juliaFunc);
}

static ALWAYS_INLINE Obj DoCallJuliaFunc(Obj func, const int narg, Obj * a)
{
    jl_value_t * result;

    for (int i = 0; i < narg; i++) {
        a[i] = (Obj)julia_gap(a[i]);
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
    return gap_julia(result);
}

//
//
//


static Obj DoCallJuliaFunc0Arg(Obj func)
{
    return DoCallJuliaFunc(func, 0, 0);
}

static Obj DoCallJuliaFunc1Arg(Obj func, Obj arg1)
{
    Obj a[] = { arg1 };
    return DoCallJuliaFunc(func, 1, a);
}

static Obj DoCallJuliaFunc2Arg(Obj func, Obj arg1, Obj arg2)
{
    Obj a[] = { arg1, arg2 };
    return DoCallJuliaFunc(func, 2, a);
}

static Obj DoCallJuliaFunc3Arg(Obj func, Obj arg1, Obj arg2, Obj arg3)
{
    Obj a[] = { arg1, arg2, arg3 };
    return DoCallJuliaFunc(func, 3, a);
}

static Obj
DoCallJuliaFunc4Arg(Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4)
{
    Obj a[] = { arg1, arg2, arg3, arg4 };
    return DoCallJuliaFunc(func, 4, a);
}

static Obj DoCallJuliaFunc5Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5)
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5 };
    return DoCallJuliaFunc(func, 5, a);
}

static Obj DoCallJuliaFunc6Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5, Obj arg6)
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5, arg6 };
    return DoCallJuliaFunc(func, 6, a);
}

static Obj DoCallJuliaFuncXArg(Obj func, Obj args)
{
    const int len = LEN_PLIST(args);
    Obj       a[len];
    for (int i = 0; i < len; i++) {
        a[i] = ELM_PLIST(args, i + 1);
    }
    return DoCallJuliaFunc(func, len, a);
}


//
//
//
Obj NewJuliaFunc(jl_function_t * function)
{
    Obj name = MakeImmString(jl_symbol_name(jl_gf_name(function)));
    Obj func = NewFunctionT(T_FUNCTION, sizeof(JuliaFuncBag), name, -1,
                            ArgStringToList("arg"), 0);

    SET_HDLR_FUNC(func, 0, DoCallJuliaFunc0Arg);
    SET_HDLR_FUNC(func, 1, DoCallJuliaFunc1Arg);
    SET_HDLR_FUNC(func, 2, DoCallJuliaFunc2Arg);
    SET_HDLR_FUNC(func, 3, DoCallJuliaFunc3Arg);
    SET_HDLR_FUNC(func, 4, DoCallJuliaFunc4Arg);
    SET_HDLR_FUNC(func, 5, DoCallJuliaFunc5Arg);
    SET_HDLR_FUNC(func, 6, DoCallJuliaFunc6Arg);
    SET_HDLR_FUNC(func, 7, DoCallJuliaFuncXArg);

    // store the the Julia function pointer
    ((JuliaFuncBag *)ADDR_OBJ(func))->juliaFunc = NewJuliaObj(function);

    // add a function body so that we can store some meta data about the
    // origin of this function, for slightly more helpful printing of the
    // function.
    Obj body = NewBag(T_BODY, sizeof(BodyHeader));
    SET_FILENAME_BODY(body, MakeImmString("Julia"));
    SET_LOCATION_BODY(body, name);
    SET_BODY_FUNC(func, body);
    CHANGED_BAG(body);
    CHANGED_BAG(func);

    return func;
}

/*
 * C function pointer calls
 */

static inline ObjFunc get_c_function_pointer(Obj func)
{
    Obj ptr = ((const JuliaFuncBag *)CONST_ADDR_OBJ(func))->juliaFunc;
    return jl_unbox_voidpointer(GET_JULIA_OBJ(ptr));
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

    Obj func = NewFunctionT(T_FUNCTION, sizeof(JuliaFuncBag), 0,
                            LEN_PLIST(arg_names), arg_names, handler);

    // store function pointer in the bag; since it gets marked by the GC, we
    // store it as a valid julia obj (i.e., void ptr).
    ((JuliaFuncBag *)ADDR_OBJ(func))->juliaFunc =
        NewJuliaObj(jl_box_voidpointer(function));

    return func;
}
