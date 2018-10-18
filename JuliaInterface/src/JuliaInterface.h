#ifndef JULIAINTERFACE_H_
#define JULIAINTERFACE_H_

#include "src/compiled.h" /* GAP headers */
#include <julia.h>

extern void handle_jl_exception(void);

#define JULIAINTERFACE_EXCEPTION_HANDLER                                     \
    if (jl_exception_occurred()) {                                           \
        handle_jl_exception();                                               \
    }

#define INITIALIZE_JULIA_CPOINTER(name)                                      \
    {                                                                        \
        jl_value_t * gap_ptr;                                                \
        jl_sym_t *   gap_symbol;                                             \
        gap_ptr = jl_box_voidpointer(name);                                  \
        gap_symbol = jl_symbol("gap_" #name);                                \
        JULIAINTERFACE_EXCEPTION_HANDLER                                     \
        jl_set_const(jl_main_module, gap_symbol, gap_ptr);                   \
        JULIAINTERFACE_EXCEPTION_HANDLER                                     \
    }

// Internal Julia access functions

// SET_JULIA_OBJ(o,v)
//
// Sets the value of the julia object GAP object
// to the julia value pointer v.
void SET_JULIA_OBJ(Obj, jl_value_t *);

// GET_JULIA_OBJ(o)
//
// Returns the julia value pointer
// from the julia object GAP object o.
jl_value_t * GET_JULIA_OBJ(Obj);

// Internal
Obj JuliaFunctionTypeFunc(Obj);

// Internal
Obj JuliaObjectTypeFunc(Obj);

// IS_JULIA_OBJ(o)
//
// Checks if o is a julia object GAP object.
#define IS_JULIA_OBJ(o) (TNUM_OBJ(o) == T_JULIA_OBJ)

// Internal
extern UInt T_JULIA_OBJ;

// NewJuliaFunc(f,autoConvert)
//
// Creates a new julia function GAP object
// from the julia function pointer f.
Obj NewJuliaFunc(jl_function_t * f, int autoConvert);

// NewJuliaObj(v)
//
// Creates a new julia object GAP object
// from the julia value pointer v.
Obj NewJuliaObj(jl_value_t *);

// get_module_from_string( name )
//
// Returns a julia module pointer to the module <name>.
jl_module_t * get_module_from_string(char * name);

#endif
