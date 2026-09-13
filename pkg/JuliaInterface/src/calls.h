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

// Bracket every call from GAP into Julia, passing the result of
// BeginJuliaCall to EndJuliaCall; see calls.c.
extern Obj  BeginJuliaCall(void);
extern void EndJuliaCall(Obj lvars);

// Whether a GAP error about to longjmp to the catch point at <tryCatchDepth>
// must be raised as a Julia exception instead; used by GAP.jl.
extern int gap_error_unwinds_into_julia(int tryCatchDepth);

// Creates a new julia function GAP object from the julia function pointer f.
extern Obj WrapJuliaFunc(jl_value_t * f);

#endif
