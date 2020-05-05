#ifndef JULIAINTERFACE_H_
#define JULIAINTERFACE_H_

#include <src/compiled.h>    // GAP headers
#include <julia.h>
#include <libgap-api.h>

extern Obj JULIAINTERFACE_IsJuliaWrapper;
extern Obj JULIAINTERFACE_JuliaPointer;

// internal helper
NOINLINE void handle_jl_exception(void);

//
// Exception handler for a few high-level Julia functions, namely
// jl_eval_string, jl_call, jl_call0, ..., jl_call3, jl_get_field.
// For any other jl_FOO APIs, you must use BEGIN_JULIA / END_JULIA
// (see below).
//
#define JULIAINTERFACE_EXCEPTION_HANDLER                                     \
    if (jl_exception_occurred()) {                                           \
        handle_jl_exception();                                               \
    }

//
// Exception handling for code calling into Julia: wrap any code calling
// into Julia functions that might throw exceptions between BEGIN_JULIA
// and END_JULIA. This will insert code that catches Julia exceptions, and
// converts them into GAP errors.
//
// WARNING: You must not use 'return' inside a BEGIN_JULIA/END_JULIA block;
// likewise, you must not exit it prematurely via any other means, so don't
// use 'ErrorQuit' or 'longjmp' inside.
//
#define BEGIN_JULIA                                                          \
    JL_TRY                                                                   \
    {
#define END_JULIA                                                            \
    jl_exception_clear();                                                    \
    }                                                                        \
    JL_CATCH                                                                 \
    {                                                                        \
        jl_get_ptls_states()->previous_exception = jl_current_exception();   \
    }                                                                        \
    JULIAINTERFACE_EXCEPTION_HANDLER


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
