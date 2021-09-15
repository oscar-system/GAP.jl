#ifndef JULIAINTERFACE_H_
#define JULIAINTERFACE_H_

#include <src/compiled.h>    // GAP headers
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
