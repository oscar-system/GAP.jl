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
UInt T_JULIA_OBJ = 0;

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

// FuncJuliaEvalString( NULL, string )
//
// Executes the string <string> in the current julia session.
Obj FuncJuliaEvalString(Obj self, Obj string);

// Func_ConvertedFromJulia_internal( julia_obj )
//
// Converts the julia value pointer <julia_obj> into a GAP object
// if possible.
Obj Func_ConvertedFromJulia_internal(jl_value_t * julia_obj);

// Func_ConvertedFromJulia( NULL, obj )
//
// Converts the julia object GAP object <obj> into a GAP object
// if possible.
Obj Func_ConvertedFromJulia(Obj self, Obj obj);

// Func_ConvertedFromJulia_record_dict( NULL, dict )
//
// <dict> must be a julia value GAP object,
// holding a pointer to a julia dict.
// The function returns a GAP list, consisting of two lists:
//  1. A list containing the keys
//  2. A list containing the values
Obj Func_ConvertedFromJulia_record_dict(Obj self, Obj dict);

// Func_ConvertedToJulia( NULL, obj )
//
// Converts the GAP object <obj> into a suitable
// julia object GAP object, if possible, and returns that
// object. If the conversion is not possible, the function returns fail.
Obj Func_ConvertedToJulia(Obj self, Obj obj);

// FuncJuliaTuple( NULL, list )
//
// Converts the GAP list <list> into a julia tuple
// and returns the julia object GAP object which holds
// the pointer to that tuple.
Obj FuncJuliaTuple(Obj self, Obj list);

// FuncJuliaSymbol( NULL, name )
//
// Returns a julia object GAP object that holds
// the pointer to a julia symbol :<name>.
Obj FuncJuliaSymbol(Obj self, Obj name);

// FuncJuliaModule( NULL, name )
//
// Returns a julia object GAP object that holds
// the pointer to the julia module <name>.
Obj FuncJuliaModule(Obj self, Obj name);

// FuncJuliaSetVal( NULL, name, julia_val )
//
// Sets the value of the julia identifier <name>
// to the julia value the julia object GAP object <julia_val>
// points to.
Obj FuncJuliaSetVal(Obj self, Obj name, Obj julia_val);

// Func_JuliaGetGlobalVariable( NULL, name )
//
// Returns the julia object GAP object that holds a pointer
// to the value currently bound to the julia identifier <name>.
Obj Func_JuliaGetGlobalVariable(Obj self, Obj name);

// Func_JuliaGetGlobalVariableByModule( NULL, name, module_name )
//
// Returns the julia object GAP object that holds a pointer
// to the value currently bound to the julia identifier <module_name>.<name>.
Obj Func_JuliaGetGlobalVariableByModule(Obj self, Obj name, Obj module_name);

// FuncJuliaGetFieldOfObject( NULL, super_object, field_name )
//
// Returns the julia object GAP object that holds a pointer
// to the value currently bound to <super_object>.<name>.
// <super_object> must be a julia object GAP object, and <name> a string.
Obj FuncJuliaGetFieldOfObject(Obj self, Obj super_obj, Obj field_name);

// Func_JuliaSetGAPFuncAsJuliaObjFunc( NULL, func, name, number_args )
//
// Sets the GAP function <func> as a GAP.GapFunc object to GAP.<name>.
// <number_args> must be the number of arguments of <func>. Is is then
// callable on GAP.GapObj's from julia.
Obj Func_JuliaSetGAPFuncAsJuliaObjFunc(Obj self,
                                       Obj func,
                                       Obj name,
                                       Obj number_args);

// INTERNAL
Obj Func_JuliaBindCFunction(Obj self,
                            Obj cfunction_string,
                            Obj number_args_gap,
                            Obj arg_names_gap);

// get_module_from_string( name )
//
// Returns a julia module pointer to the module <name>.
jl_module_t * get_module_from_string(char * name);

#endif
