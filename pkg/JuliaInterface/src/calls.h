//
// JuliaInterface package
//
// Wrap Julia functions for GAP, and implement function calls between Julia
// and GAP.
//
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
