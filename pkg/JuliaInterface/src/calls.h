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

extern Int          IS_JULIA_FUNC(Obj obj);
extern jl_value_t * GET_JULIA_FUNC(Obj obj);

// GAP's state at a call from GAP into Julia, kept in the C frame making the
// call for as long as it lasts. Bracket every call from GAP into Julia with
// BeginJuliaCall and EndJuliaCall; see calls.c.
typedef struct JuliaCall {
    struct JuliaCall * prev;              // the enclosing call, if any
    int                tryCatchDepth;     // GAP's TryCatchDepth
    Int                recursionDepth;    // GAP's recursion depth
    Obj                lvars;             // the caller's local variables
} JuliaCall;

extern void BeginJuliaCall(JuliaCall * call);
extern void EndJuliaCall(JuliaCall * call);

// Whether a GAP error about to longjmp to the catch point at <tryCatchDepth>
// must be raised as a Julia exception instead; used by GAP.jl.
extern int gap_error_unwinds_into_julia(int tryCatchDepth);

// Reset GAP's recursion depth before such an error is raised in Julia; used
// by GAP.jl.
extern void restore_recursion_depth_for_julia(void);

// Creates a new julia function GAP object from the julia function pointer f.
extern Obj WrapJuliaFunc(jl_value_t * f);

#endif
