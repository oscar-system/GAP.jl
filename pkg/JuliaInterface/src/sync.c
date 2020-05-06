#include "sync.h"
#include <pthread.h>
#include <stdlib.h>

#ifndef HPCGAP
static pthread_mutex_t GapLock;

void InitGapSync(void)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&GapLock, &attr);
    pthread_mutexattr_destroy(&attr);
}

void BeginGapSync(void)
{
    pthread_mutex_lock(&GapLock);
}

void EndGapSync(void)
{
    pthread_mutex_unlock(&GapLock);
}
#endif
