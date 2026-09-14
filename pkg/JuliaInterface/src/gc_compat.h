//
//  This file is part of GAP.jl, a bidirectional interface between Julia and
//  the GAP computer algebra system.
//
//  Copyright of GAP.jl and its parts belongs to its developers.
//  Please refer to its README.md file for details.
//
//  SPDX-License-Identifier: LGPL-3.0-or-later
//
// Rooting macros and analyzer annotations for kernels that lack them.

#ifndef JULIAINTERFACE_GC_COMPAT_H
#define JULIAINTERFACE_GC_COMPAT_H

#include <gap_all.h>    // GAP headers
#include <julia.h>

// GAP 4.16 roots C locals explicitly when built with --enable-precise-gc
// and provides these macros for it, together with annotations for Julia's
// GC analyzer; without precise mode they compile away, except that
// GAP_GC_PUSHARGS still supplies its array. Older kernels find the locals by
// scanning the C stack, so against their headers the same holds.
#ifndef GAP_GC_PUSH1
#define GAP_GC_PUSH1(a) ((void)0)
#define GAP_GC_PUSH2(a, b) ((void)0)
#define GAP_GC_PUSH5(a, b, c, d, e) ((void)0)
#define GAP_GC_PUSH6(a, b, c, d, e, f) ((void)0)
#define GAP_GC_PUSHARGS(rts, n) (rts) = (jl_value_t **)alloca(sizeof(void *) * (n))
#define GAP_GC_POP() ((void)0)
#define GAP_GC_GLOBALLY_ROOTED
#define GAP_GC_MAYBE_UNROOTED
#define GAP_GC_PROPAGATES_ROOT
#define GAP_GC_NOTSAFEPOINT
#define GAP_GC_CANSAFEPOINT
#endif

#endif
