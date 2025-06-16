//
//  This file is part of GAP.jl, a bidirectional interface between Julia and
//  the GAP computer algebra system.
//
//  Copyright of GAP.jl and its parts belongs to its developers.
//  Please refer to its README.md file for details.
//
//  SPDX-License-Identifier: LGPL-3.0-or-later
//
// Low-level conversion helpers

#include "convert.h"

#include "calls.h"
#include "sync.h"
#include "JuliaInterface.h"

// Turn a GAP object into a Julia object.
// This function is used by GAP.jl and also by `DoCallJuliaFunc`.
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
    jl_value_t * result = (jl_value_t *)obj;
    BEGIN_GAP_SYNC();
    if (TNUM_OBJ(obj) >= FIRST_EXTERNAL_TNUM &&
        CALL_1ARGS(JULIAINTERFACE_IsJuliaWrapper, obj) == True) {
        obj = CALL_1ARGS(JULIAINTERFACE_JuliaPointer, obj);
        if (IS_JULIA_OBJ(obj)) {
            result = GET_JULIA_OBJ(obj);
        }
        // to handle immediate integers, booleans, FFEs, IS_JULIA_FUNC, we
        // use recursion - but only for internal types; this prevents an
        // infinite recursion, e.g. if an object's JuliaPointer points to the
        // object itself
        else if (TNUM_OBJ(obj) < FIRST_EXTERNAL_TNUM) {
            result = julia_gap(obj);
        }
        else {
            ErrorMayQuit("JuliaPointer must be a Julia object or an internal "
                         "GAP object (not a %s)",
                         (Int)TNAM_OBJ(obj), 0);
        }
    }
    END_GAP_SYNC();
    return result;
}

// Turn a Julia object into a GAP object.
// This function is used by GAP.jl (via `call_gap_func`) and also by
// `DoCallJuliaFunc`.
Obj gap_julia(jl_value_t * julia_obj)
{
    if (jl_typeis(julia_obj, jl_int64_type)) {
        int64_t v = jl_unbox_int64(julia_obj);
        if (INT_INTOBJ_MIN <= v && v <= INT_INTOBJ_MAX) {
            return INTOBJ_INT(v);
        }
        return ObjInt_Int8(v);
    }
    if (is_gapobj(julia_obj)) {
        return (Obj)julia_obj;
    }
    if (is_gapffe(julia_obj)) {
        return gap_unbox_gapffe(julia_obj);
    }
    if (jl_typeis(julia_obj, jl_bool_type)) {
        return julia_obj == jl_true ? True : False;
    }
    return NewJuliaObj(julia_obj);
}
