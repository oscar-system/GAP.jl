//
//  This file is part of GAP.jl, a bidirectional interface between Julia and
//  the GAP computer algebra system.
//
//  Copyright of GAP.jl and its parts belongs to its developers.
//  Please refer to its README.md file for details.
//
//  SPDX-License-Identifier: LGPL-3.0-or-later
//
// Ensure not more than one Julia thread calls into the GAP kernel at a time.
//

#ifndef JULIAINTERFACE_SYNC_H
#define JULIAINTERFACE_SYNC_H

// #define THREADSAFE_GAP_JL 1

#include <gap_all.h>

#if defined(HPCGAP) || !defined(THREADSAFE_GAP_JL)
#define BEGIN_GAP_SYNC() ((void)0)
#define END_GAP_SYNC() ((void)0)
#else
void BeginGapSync(void);
void EndGapSync(void);
#define BEGIN_GAP_SYNC() BeginGapSync()
#define END_GAP_SYNC() EndGapSync()
#endif

void InitGapSync(void);

#endif
