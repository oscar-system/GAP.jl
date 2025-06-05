//
//  This file is part of GAP.jl, a bidirectional interface between Julia and
//  the GAP computer algebra system.
//
//  Copyright of GAP.jl and its parts belongs to its developers.
//  Please refer to its README.md file for details.
//
//  SPDX-License-Identifier: LGPL-3.0-or-later
//
// Contains GAP wrapper objects for Julia objects, and GAP kernel functions
// used by the GAP code of JuliaInterface.

#ifndef JULIAINTERFACE_H_
#define JULIAINTERFACE_H_

#include <gap_all.h>    // GAP headers
#include <julia.h>
#include <libgap-api.h>

extern Obj JULIAINTERFACE_IsJuliaWrapper;
extern Obj JULIAINTERFACE_JuliaPointer;

// internal helper
NOINLINE void handle_jl_exception(void);

// Internal Julia access functions

// GET_JULIA_OBJ(o)
//
// Returns the julia value pointer
// from the julia object GAP object o.
jl_value_t * GET_JULIA_OBJ(Obj);

// IS_JULIA_OBJ(o)
//
// Checks if o is a julia object GAP object.
int IS_JULIA_OBJ(Obj o);

// NewJuliaObj(v)
//
// Creates a new julia object GAP object
// from the julia value pointer v.
Obj NewJuliaObj(jl_value_t *);

//
jl_value_t * gap_box_gapffe(Obj value);

//
Obj gap_unbox_gapffe(jl_value_t * gapffe);

//
int is_gapffe(jl_value_t * v);

//
int is_gapobj(jl_value_t * v);

#endif
