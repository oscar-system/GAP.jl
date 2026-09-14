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


static Obj DoCallJuliaFunc0Arg(Obj func);


typedef struct {
    FuncBag f;
    Obj     juliaFunc;
} JuliaFuncBag;


// Helper used to call GAP functions from Julia.
//
// This function is used by GAP.jl
Obj call_gap_func(Obj func, jl_value_t * args)
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
    return return_value;
}


inline Int IS_JULIA_FUNC(Obj obj)
{
    return IS_FUNC(obj) && (HDLR_FUNC(obj, 0) == DoCallJuliaFunc0Arg);
}

inline jl_value_t * GET_JULIA_FUNC(Obj func)
{
    GAP_ASSERT(IS_JULIA_FUNC(func));
    return GET_JULIA_OBJ(
        ((const JuliaFuncBag *)CONST_ADDR_OBJ(func))->juliaFunc);
}

// Calls from GAP into Julia that have not returned yet, innermost last.
//
// A GAP error raised in GAP code called from such a call must not longjmp
// across the Julia frames in between: that skips Julia's own exception
// handling and leaves it pointing at a dead frame. GAP.jl's throw observer
// asks gap_error_unwinds_into_julia whether that would happen, and if so
// raises a Julia exception instead. The GAP code between the error and the
// Julia code catching that exception is abandoned: GAP's recursion depth is
// reset when the exception is raised, and when the call into Julia returns,
// GAP's local variables are switched back to those of the GAP code that
// made it.
//
//   GAP_TRY          TryCatchDepth 1
//     BeginJuliaCall   records 1
//       Julia code
//         GAP code
//           error      TryCatchDepth still 1: the catch point is below the
//                      Julia frames, so raise a Julia exception
typedef struct {
    int tryCatchDepth;     // GAP's TryCatchDepth when the call was made
    Int recursionDepth;    // GAP's recursion depth when the call was made
} JuliaCall;

enum { MAX_JULIA_CALLS = 1 << 12 };
static JuliaCall JuliaCalls[MAX_JULIA_CALLS];
static int       JuliaCallCount = 0;

// Returns the local variables bag of the calling GAP code, to be passed to
// EndJuliaCall.
Obj BeginJuliaCall(void)
{
    if (JuliaCallCount >= MAX_JULIA_CALLS)
        ErrorMayQuit("too many nested calls from GAP into Julia", 0, 0);
    JuliaCalls[JuliaCallCount].tryCatchDepth = STATE(TryCatchDepth);
    JuliaCalls[JuliaCallCount].recursionDepth = GetRecursionDepth();
    JuliaCallCount++;
    return STATE(CurrLVars);
}

void EndJuliaCall(Obj lvars)
{
    JuliaCallCount--;
    SWITCH_TO_OLD_LVARS(lvars);
}

// Called by GAP.jl's throw observer when a GAP error is about to longjmp to
// the catch point at <tryCatchDepth>. Returns 1 if the innermost call into
// Julia was made after that catch point was entered, or if there is no catch
// point at all, so that the error must be raised as a Julia exception.
int gap_error_unwinds_into_julia(int tryCatchDepth)
{
    int callTryCatchDepth =
        JuliaCallCount > 0 ? JuliaCalls[JuliaCallCount - 1].tryCatchDepth : 0;
    return tryCatchDepth <= callTryCatchDepth;
}

// Called by GAP.jl's throw observer just before it raises a GAP error as a
// Julia exception. The GAP functions between the error and the Julia code
// catching the exception never return, so they never decrement GAP's
// recursion depth. Reset it to its value at the innermost call into Julia,
// where that Julia code runs, or to 0 if Julia called GAP from top level.
void restore_recursion_depth_for_julia(void)
{
    SetRecursionDepth(JuliaCallCount > 0
                          ? JuliaCalls[JuliaCallCount - 1].recursionDepth
                          : 0);
}

static ALWAYS_INLINE Obj DoCallJuliaFunc(Obj func, const int narg, Obj * a)
{
    jl_value_t * result;

    for (int i = 0; i < narg; i++) {
        a[i] = (Obj)julia_gap(a[i]);
    }

    Obj lvars = BeginJuliaCall();
    jl_value_t * f = (jl_value_t *)GET_JULIA_FUNC(func);
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
    EndJuliaCall(lvars);
    if (jl_exception_occurred()) {
        handle_jl_exception();
    }
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
Obj WrapJuliaFunc(jl_value_t * function)
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


//
//
//
jl_value_t * UnwrapJuliaFunc(Obj func)
{
    // if it is a wrapped Julia function, return that
    if (IS_JULIA_FUNC(func))
        return GET_JULIA_FUNC(func);

    // otherwise return the input object (all non-immediate GAP objects are
    // Julia objects)
    return (jl_value_t *)func;
}
