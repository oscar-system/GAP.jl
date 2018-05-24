#ifndef JULIAINTERFACE_H_
#define JULIAINTERFACE_H_

#include "src/compiled.h"          /* GAP headers */
#include <julia.h>

#undef PACKAGE_BUGREPORT
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_URL
#undef PACKAGE_VERSION
#include "pkgconfig.h"

#define JULIAINTERFACE_EXCEPTION_HANDLER if (jl_exception_occurred()) \
    ErrorMayQuit( jl_typeof_str(jl_exception_occurred()), 0, 0 );

#define INITIALIZE_JULIA_CPOINTER(name)\
{\
jl_value_t* gap_ptr;\
jl_sym_t * gap_symbol;\
gap_ptr = jl_box_voidpointer( name );\
gap_symbol = jl_symbol( "gap_" #name );\
JULIAINTERFACE_EXCEPTION_HANDLER \
jl_set_const( jl_main_module, gap_symbol, gap_ptr );\
JULIAINTERFACE_EXCEPTION_HANDLER\
}

UInt gap_obj_gc_list_master;
UInt gap_obj_gc_list_positions_master;

// Internal Julia access functions

// SET_JULIA_FUNC(o,f)
//
// Sets the value of the julia function GAP object
// to the julia function pointer f.
void SET_JULIA_FUNC(Obj, jl_function_t*);

// SET_JULIA_OBJ(o,v)
//
// Sets the value of the julia object GAP object
// to the julia value pointer v.
void SET_JULIA_OBJ(Obj, jl_value_t*);

// GET_JULIA_FUNC(o)
//
// Returns the julia function pointer
// from the julia function GAP object o.
jl_function_t* GET_JULIA_FUNC(Obj);

// GET_JULIA_OBJ(o)
//
// Returns the julia value pointer
// from the julia object GAP object o.
jl_value_t* GET_JULIA_OBJ(Obj);

// Internal
Obj JuliaFunctionTypeFunc(Obj);

// Internal
Obj JuliaObjectTypeFunc(Obj);

// IS_JULIA_FUNC(o)
//
// Checks if o is a julia function GAP object.
#define IS_JULIA_FUNC(o) (TNUM_OBJ(o) == T_JULIA_FUNC)

// IS_JULIA_OBJ(o)
//
// Checks if o is a julia object GAP object.
#define IS_JULIA_OBJ(o) (TNUM_OBJ(o) == T_JULIA_OBJ)

// Internal
UInt T_JULIA_FUNC = 0;
UInt T_JULIA_OBJ = 0;

// NewJuliaFunc(f)
//
// Creates a new julia function GAP object
// from the julia function pointer f.
Obj NewJuliaFunc(jl_function_t*);

// NewJuliaObj(v)
//
// Creates a new julia object GAP object
// from the julia value pointer v.
Obj NewJuliaObj(jl_value_t*);

// __JuliaFunction( NULL, string )
//
// Returns the function with name <string> from the Julia `Main` module.
Obj __JuliaFunction( Obj self, Obj string );

// __JuliaFunctionByModule( NULL, function_name, module_name )
//
// Returns the function with name <function_name> from
// the Julia module with name <module_name>.
Obj __JuliaFunctionByModule( Obj self, Obj function_name, Obj module_name );

// __JuliaCallFunc0Arg( NULL, func )
//
// Calls the function in the julia function GAP object <func>
// without arguments.
Obj __JuliaCallFunc0Arg( Obj self, Obj func );

// __JuliaCallFunc1Arg( NULL, func, arg )
//
// Calls the function in the julia function GAP object <func>
// on the julia object GAP object <arg>.
Obj __JuliaCallFunc1Arg( Obj self, Obj func, Obj arg );

// __JuliaCallFunc2Arg( NULL, func, arg1, arg2 )
//
// Calls the function in the julia function GAP object <func>
// on the julia object GAP objecta <arg1> and <arg2>.
Obj __JuliaCallFunc2Arg( Obj self, Obj func, Obj arg1, Obj arg2 );

// __JuliaCallFunc3Arg( NULL, func, arg1, arg2, arg3 )
//
// Calls the function in the julia function GAP object <func>
// on the julia object GAP object <arg1>, <arg2>, and <arg3>.
Obj __JuliaCallFunc3Arg( Obj self, Obj func, Obj arg1, Obj arg2, Obj arg3 );

// __JuliaCallFuncXArg( NULL, func, args )
//
// Calls the function in the julia function GAP object <func>
// on the julia object GAP objects in the GAP plain list <args>.
Obj __JuliaCallFuncXArg( Obj self, Obj func, Obj args );

// JuliaEvalString( NULL, string )
//
// Executes the string <string> in the current julia session.
Obj JuliaEvalString( Obj self, Obj string );

// __JuliaUnbox_internal( julia_obj )
//
// Converts the julia value pointer <julia_obj> into a GAP object
// if possible.
Obj __JuliaUnbox_internal( jl_value_t* julia_obj );

// __JuliaUnbox( NULL, obj )
//
// Converts the julia object GAP object <obj> into a GAP object
// if possible.
Obj __JuliaUnbox( Obj self, Obj obj );

// __JuliaUnbox_record_dict( NULL, dict )
//
// <dict> must be a julia value GAP object,
// holding a pointer to a julia dict.
// The function returns a GAP list, consisting of two lists:
//  1. A list containing the keys
//  2. A list containing the values
Obj __JuliaUnbox_record_dict( Obj self, Obj dict );

// __JuliaBox( NULL, obj )
//
// Converts the GAP object <obj> into a suitable
// julia object GAP object, if possible, and returns that
// object. If the conversion is not possible, the function returns fail.
Obj __JuliaBox( Obj self, Obj obj );

// JuliaTuple( NULL, list )
//
// Converts the GAP list <list> into a julia tuple
// and returns the julia object GAP object which holds
// the pointer to that tuple.
Obj JuliaTuple( Obj self, Obj list );

// JuliaSymbol( NULL, name )
//
// Returns a julia object GAP object that holds
// the pointer to a julia symbol :<name>.
Obj JuliaSymbol( Obj self, Obj name );

// JuliaModule( NULL, name )
//
// Returns a julia object GAP object that holds
// the pointer to the julia module <name>.
Obj JuliaModule( Obj self, Obj name );

// JuliaSetVal( NULL, name, julia_val )
//
// Sets the value of the julia identifier <name>
// to the julia value the julia object GAP object <julia_val>
// points to.
Obj JuliaSetVal( Obj self, Obj name, Obj julia_val );

// __JuliaGetGlobalVariable( NULL, name )
//
// Returns the julia object GAP object that holds a pointer
// to the value currently bound to the julia identifier <name>.
Obj __JuliaGetGlobalVariable( Obj self, Obj name );

// __JuliaGetGlobalVariableByModule( NULL, name, module_name )
//
// Returns the julia object GAP object that holds a pointer
// to the value currently bound to the julia identifier <module_name>.<name>.
Obj __JuliaGetGlobalVariableByModule( Obj self, Obj name, Obj module_name );

// JuliaGetFieldOfObject( NULL, super_object, field_name )
//
// Returns the julia object GAP object that holds a pointer
// to the value currently bound to <super_object>.<name>.
// <super_object> must be a julia object GAP object, and <name> a string.
Obj JuliaGetFieldOfObject( Obj self, Obj super_obj, Obj field_name );

// __JuliaSetGAPFuncAsJuliaObjFunc( NULL, func, name, number_args )
//
// Sets the GAP function <func> as a GAP.GapFunc object to GAP.<name>.
// <number_args> must be the number of arguments of <func>. Is is then callable
// on GAP.GapObj's from julia.
Obj __JuliaSetGAPFuncAsJuliaObjFunc( Obj self, Obj func, Obj name, Obj number_args );

// INTERNAL
Obj __JuliaBindCFunction( Obj self, Obj cfunction_string,
                                           Obj number_args_gap, Obj arg_names_gap );

// From julia_macros.c

// get_module_from_string( name )
//
// Returns a julia module pointer to the module <name>.
jl_module_t* get_module_from_string( char* name );

#endif