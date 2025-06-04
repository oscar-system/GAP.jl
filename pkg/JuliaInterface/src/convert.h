//
//  This file is part of GAP.jl, a bidirectional interface between Julia and
//  the GAP computer algebra system.
//
//  Copyright of GAP.jl and its parts belongs to its developers.
//  Please refer to its README.md file for details.
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
// Low-level conversion helpers

#ifndef JULIAINTERFACE_CONVERT_H
#define JULIAINTERFACE_CONVERT_H

#include <gap_all.h>    // GAP headers
#include <julia.h>
#include <libgap-api.h>

extern jl_value_t * julia_gap(Obj obj);
extern Obj          gap_julia(jl_value_t * julia_obj);

#endif
