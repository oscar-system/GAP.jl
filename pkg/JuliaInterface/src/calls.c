//
//  This file is part of GAP.jl, a bidirectional interface between Julia and
//  the GAP computer algebra system.
//
//  Copyright of GAP.jl and its parts belongs to its developers.
//  Please refer to its README.md file for details.
//
//  SPDX-License-Identifier: LGPL-3.0-or-later
//
// Wrap Julia functions for GAP, and implement function calls between Julia
// and GAP.

#include "calls.h"
#include "convert.h"
#include "JuliaInterface.h"


static Obj DoCallJuliaFunc0Arg(Obj func) GAP_GC_CANSAFEPOINT;


typedef struct {
    FuncBag f;
    Obj     juliaFunc;
} JuliaFuncBag;


// Helper used to call GAP functions from Julia.
//
// This function is used by GAP.jl
Obj call_gap_func(Obj func, jl_value_t * args) GAP_GC_CANSAFEPOINT
{
    if (!jl_is_tuple(args))
        jl_error("<args> must be a tuple");

    size_t len = jl_nfields(args);
    Obj    return_value = NULL;
    if (IS_FUNC(func) && len <= 6) {
        // converting one argument can collect, so the ones converted before
        // it must already be rooted
        Obj a[6] = { 0 };
        GAP_GC_PUSH6(&a[0], &a[1], &a[2], &a[3], &a[4], &a[5]);
        for (size_t i = 0; i < len; i++)
            a[i] = gap_julia(jl_fieldref(args, i));
        switch (len) {
        case 0:
            return_value = CALL_0ARGS(func);
            break;
        case 1:
            return_value = CALL_1ARGS(func, a[0]);
            break;
        case 2:
            return_value = CALL_2ARGS(func, a[0], a[1]);
            break;
        case 3:
            return_value = CALL_3ARGS(func, a[0], a[1], a[2]);
            break;
        case 4:
            return_value = CALL_4ARGS(func, a[0], a[1], a[2], a[3]);
            break;
        case 5:
            return_value = CALL_5ARGS(func, a[0], a[1], a[2], a[3], a[4]);
            break;
        case 6:
            return_value =
                CALL_6ARGS(func, a[0], a[1], a[2], a[3], a[4], a[5]);
            break;
        }
        GAP_GC_POP();
    }
    else {
        Obj arg_list = NEW_PLIST(T_PLIST, len);
        GAP_GC_PUSH1(&arg_list);
        SET_LEN_PLIST(arg_list, len);
        for (size_t i = 0; i < len; i++) {
            SET_ELM_PLIST(arg_list, i + 1, gap_julia(jl_fieldref(args, i)));
            CHANGED_BAG(arg_list);
        }
        return_value = CallFuncList(func, arg_list);
        GAP_GC_POP();
    }
    return return_value;
}


inline Int IS_JULIA_FUNC(Obj obj) GAP_GC_NOTSAFEPOINT
{
    return IS_FUNC(obj) && (HDLR_FUNC(obj, 0) == DoCallJuliaFunc0Arg);
}

inline jl_value_t * GET_JULIA_FUNC(Obj func GAP_GC_PROPAGATES_ROOT) GAP_GC_NOTSAFEPOINT
{
    GAP_ASSERT(IS_JULIA_FUNC(func));
    return GET_JULIA_OBJ(
        ((const JuliaFuncBag *)CONST_ADDR_OBJ(func))->juliaFunc);
}

// Calls from GAP into Julia that have not returned yet.
//
// A GAP error raised in GAP code called from such a call must not longjmp
// across the Julia frames in between: that skips Julia's own exception
// handling and leaves it pointing at a dead frame. GAP.jl's throw observer
// asks gap_error_skips_julia_call whether that would happen, and if so
// raises a Julia exception instead.
//
//   GAP_TRY          TryCatchDepth 1
//     BeginJuliaCall   records 1
//       Julia code
//         GAP code
//           error      TryCatchDepth still 1: the catch point is below the
//                      Julia frames, so raise a Julia exception
//
// The GAP code between the error and the Julia code catching that exception
// never returns. So GAP's recursion depth is reset when the exception is
// raised, and GAP's local variables are switched back when the call into
// Julia returns, both to their values at the call.
//
// Each call keeps its record in the C frame making it; the records form a
// list from the innermost call outwards.
static JuliaCall * InnermostJuliaCall = 0;

void BeginJuliaCall(JuliaCall * call) GAP_GC_NOTSAFEPOINT
{
    call->prev = InnermostJuliaCall;
    call->tryCatchDepth = STATE(TryCatchDepth);
    call->recursionDepth = GetRecursionDepth();
    call->lvars = STATE(CurrLVars);
    InnermostJuliaCall = call;
}

void EndJuliaCall(JuliaCall * call) GAP_GC_NOTSAFEPOINT
{
    GAP_ASSERT(call == InnermostJuliaCall);
    InnermostJuliaCall = call->prev;
    SWITCH_TO_OLD_LVARS(call->lvars);
}

// Called by GAP.jl's throw observer when a GAP error is about to longjmp to
// the catch point at <tryCatchDepth>. Returns 1 if the innermost call into
// Julia was made after that catch point was entered.
int gap_error_skips_julia_call(int tryCatchDepth) GAP_GC_NOTSAFEPOINT
{
    return InnermostJuliaCall &&
           tryCatchDepth <= InnermostJuliaCall->tryCatchDepth;
}

// Called by GAP.jl's throw observer just before it raises a GAP error as a
// Julia exception: resets GAP's recursion depth to its value at the
// innermost call into Julia, where the Julia code catching the exception
// runs, or to 0 if Julia called GAP from top level.
void restore_recursion_depth_for_julia(void) GAP_GC_NOTSAFEPOINT
{
    SetRecursionDepth(InnermostJuliaCall ? InnermostJuliaCall->recursionDepth
                                         : 0);
}

static ALWAYS_INLINE Obj
DoCallJuliaFunc(Obj func, const int narg, Obj * a) GAP_GC_CANSAFEPOINT
{
    // Converting an argument can allocate, and so collect, while the ones
    // converted before it are held nowhere else: convert into a GC frame.
    jl_value_t ** args;
    GAP_GC_PUSHARGS(args, narg);
    for (int i = 0; i < narg; i++) {
        args[i] = julia_gap(a[i]);
    }

    jl_value_t * f = (jl_value_t *)GET_JULIA_FUNC(func);
    jl_value_t * result;
    {
        // the caller's local variables bag can lose its other references
        // while Julia runs, if a GAP error abandons the GAP code in between
        JuliaCall call;
        BeginJuliaCall(&call);
        GAP_GC_PUSH1(&call.lvars);
        switch (narg) {
        case 0:
            result = jl_call0(f);
            break;
        case 1:
            result = jl_call1(f, args[0]);
            break;
        case 2:
            result = jl_call2(f, args[0], args[1]);
            break;
        case 3:
            result = jl_call3(f, args[0], args[1], args[2]);
            break;
        default:
            result = jl_call(f, args, narg);
        }
        EndJuliaCall(&call);
        GAP_GC_POP();
    }
    if (jl_exception_occurred()) {
        handle_jl_exception();
    }
    Obj ret = gap_julia(result);
    GAP_GC_POP();
    return ret;
}

//
//
//


static Obj DoCallJuliaFunc0Arg(Obj func) GAP_GC_CANSAFEPOINT
{
    return DoCallJuliaFunc(func, 0, 0);
}

static Obj DoCallJuliaFunc1Arg(Obj func, Obj arg1) GAP_GC_CANSAFEPOINT
{
    Obj a[] = { arg1 };
    return DoCallJuliaFunc(func, 1, a);
}

static Obj DoCallJuliaFunc2Arg(Obj func, Obj arg1, Obj arg2) GAP_GC_CANSAFEPOINT
{
    Obj a[] = { arg1, arg2 };
    return DoCallJuliaFunc(func, 2, a);
}

static Obj DoCallJuliaFunc3Arg(Obj func, Obj arg1, Obj arg2, Obj arg3)
    GAP_GC_CANSAFEPOINT
{
    Obj a[] = { arg1, arg2, arg3 };
    return DoCallJuliaFunc(func, 3, a);
}

static Obj
DoCallJuliaFunc4Arg(Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4)
    GAP_GC_CANSAFEPOINT
{
    Obj a[] = { arg1, arg2, arg3, arg4 };
    return DoCallJuliaFunc(func, 4, a);
}

static Obj DoCallJuliaFunc5Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5)
    GAP_GC_CANSAFEPOINT
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5 };
    return DoCallJuliaFunc(func, 5, a);
}

static Obj DoCallJuliaFunc6Arg(
    Obj func, Obj arg1, Obj arg2, Obj arg3, Obj arg4, Obj arg5, Obj arg6)
    GAP_GC_CANSAFEPOINT
{
    Obj a[] = { arg1, arg2, arg3, arg4, arg5, arg6 };
    return DoCallJuliaFunc(func, 6, a);
}

static Obj DoCallJuliaFuncXArg(Obj func, Obj args) GAP_GC_CANSAFEPOINT
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
Obj WrapJuliaFunc(jl_value_t * function) GAP_GC_CANSAFEPOINT
{
    Obj name = 0;
    Obj args = 0;
    Obj func = 0;
    Obj body = 0;
    Obj filename = 0;
    GAP_GC_PUSH5(&name, &args, &func, &body, &filename);
    name = MakeImmString(jl_symbol_name(jl_gf_name(function)));
    args = ArgStringToList("arg");
    func = NewFunctionT(T_FUNCTION, sizeof(JuliaFuncBag), name, -1, args, 0);

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
    body = NewBag(T_BODY, sizeof(BodyHeader));
    filename = MakeImmString("Julia");
    SET_FILENAME_BODY(body, filename);
    SET_LOCATION_BODY(body, name);
    SET_BODY_FUNC(func, body);
    CHANGED_BAG(body);
    CHANGED_BAG(func);

    GAP_GC_POP();
    return func;
}


//
//
//
jl_value_t * UnwrapJuliaFunc(Obj func) GAP_GC_NOTSAFEPOINT
{
    // if it is a wrapped Julia function, return that
    if (IS_JULIA_FUNC(func))
        return GET_JULIA_FUNC(func);

    // otherwise return the input object (all non-immediate GAP objects are
    // Julia objects)
    return (jl_value_t *)func;
}
