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

#ifndef JULIAINTERFACE_CALLS_H
#define JULIAINTERFACE_CALLS_H

#include <gap_all.h>    // GAP headers
#include <julia.h>
#include <libgap-api.h>

#include "gc_compat.h"

extern Int          IS_JULIA_FUNC(Obj obj) GAP_GC_NOTSAFEPOINT;
// the function object keeps the Julia function alive
extern jl_value_t * GET_JULIA_FUNC(Obj obj GAP_GC_PROPAGATES_ROOT) GAP_GC_NOTSAFEPOINT;

// GAP's state at a call from GAP into Julia, kept in the C frame making the
// call for as long as it lasts. Bracket every call from GAP into Julia with
// BeginJuliaCall and EndJuliaCall; see calls.c.
//
// TODO: collect the GAP and Julia backtraces of each call an error passes, so
// that it can show them interleaved; GAPError holds one of each.
typedef struct JuliaCall {
    struct JuliaCall * prev;              // the enclosing call, if any
    int                tryCatchDepth;     // GAP's TryCatchDepth
    Int                recursionDepth;    // GAP's recursion depth
    Obj                lvars;             // the caller's local variables
} JuliaCall;

extern void BeginJuliaCall(JuliaCall * call) GAP_GC_NOTSAFEPOINT;
extern void EndJuliaCall(JuliaCall * call) GAP_GC_NOTSAFEPOINT;

// Whether a GAP error longjmping to the catch point at <tryCatchDepth> would
// skip the Julia frames of a call from GAP into Julia; used by GAP.jl.
extern int gap_error_skips_julia_call(int tryCatchDepth) GAP_GC_NOTSAFEPOINT;

// Reset GAP's recursion depth before such an error is raised in Julia; used
// by GAP.jl.
extern void restore_recursion_depth_for_julia(void) GAP_GC_NOTSAFEPOINT;

// Creates a new julia function GAP object from the julia function pointer f.
extern Obj WrapJuliaFunc(jl_value_t * f) GAP_GC_CANSAFEPOINT;

#endif
