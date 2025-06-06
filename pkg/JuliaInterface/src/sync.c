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
// TODO: this is not actually fully implemented!!

#include "sync.h"
#include <pthread.h>
#include <stdlib.h>

#ifndef HPCGAP
static pthread_mutex_t GapLock;
static int             is_threaded;

void InitGapSync(void)
{
    extern int jl_n_threads;
    is_threaded = jl_n_threads > 1;
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&GapLock, &attr);
    pthread_mutexattr_destroy(&attr);
}

void BeginGapSync(void)
{
    if (is_threaded)
        pthread_mutex_lock(&GapLock);
}

void EndGapSync(void)
{
    if (is_threaded)
        pthread_mutex_unlock(&GapLock);
}
#endif
