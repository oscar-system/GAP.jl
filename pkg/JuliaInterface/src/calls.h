//
//  This file is part of GAP.jl, a bidirectional interface between Julia and
//  the GAP computer algebra system.
//
//  Copyright of GAP.jl and its parts belongs to its developers.
//  Please refer to its README.md file for details.
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
// Wrap Julia functions for GAP, and implement function calls between Julia
// and GAP.

#ifndef JULIAINTERFACE_CALLS_H
#define JULIAINTERFACE_CALLS_H

#include <gap_all.h>    // GAP headers
#include <julia.h>
#include <libgap-api.h>

extern Int             IS_JULIA_FUNC(Obj obj);
extern jl_function_t * GET_JULIA_FUNC(Obj obj);

// Creates a new julia function GAP object from the julia function pointer f.
extern Obj WrapJuliaFunc(jl_function_t * f);

#endif
