#ifndef JULIAINTERFACE_SYNC_H
#define JULIAINTERFACE_SYNC_H

#include <src/compiled.h>

#if defined(HPCGAP)
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
