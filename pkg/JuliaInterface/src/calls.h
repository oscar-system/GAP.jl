#ifndef JULIAINTERFACE_CALLS_H
#define JULIAINTERFACE_CALLS_H

#include <src/compiled.h>    // GAP headers
#include <julia.h>
#include <libgap-api.h>

extern Int             IS_JULIA_FUNC(Obj obj);
extern jl_function_t * GET_JULIA_FUNC(Obj obj);

// Creates a new julia function GAP object from the julia function pointer f.
extern Obj NewJuliaFunc(jl_function_t * f);

#endif
