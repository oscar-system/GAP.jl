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

UInt gap_obj_gc_list_master;
UInt gap_obj_gc_list_positions_master;

// Internal Julia access functions

void SET_JULIA_FUNC(Obj, jl_function_t*);
void SET_JULIA_OBJ(Obj, jl_value_t*);

jl_function_t* GET_JULIA_FUNC(Obj);
jl_value_t* GET_JULIA_OBJ(Obj);
Obj JuliaFunctionTypeFunc(Obj);
Obj JuliaObjectTypeFunc(Obj);

#define IS_JULIA_FUNC(o) (TNUM_OBJ(o) == T_JULIA_FUNC)
#define IS_JULIA_OBJ(o) (TNUM_OBJ(o) == T_JULIA_OBJ)

UInt T_JULIA_FUNC = 0;
UInt T_JULIA_OBJ = 0;

Obj NewJuliaFunc(jl_function_t*);
Obj NewJuliaObj(jl_value_t* C);

/*
 * Returns the function with name <string> from the Julia main module.
 */
Obj __JuliaFunction( Obj self, Obj string );

/*
 * Returns the function with name <function_name> from the Julia module with name <module_name>.
 */
Obj __JuliaFunctionByModule( Obj self, Obj function_name, Obj module_name );

Obj __JuliaCallFunc0Arg( Obj self, Obj func );
Obj __JuliaCallFunc1Arg( Obj self, Obj func, Obj arg );
Obj __JuliaCallFunc2Arg( Obj self, Obj func, Obj arg1, Obj arg2 );
Obj __JuliaCallFunc3Arg( Obj self, Obj func, Obj arg1, Obj arg2, Obj arg3 );
Obj __JuliaCallFuncXArg( Obj self, Obj func, Obj args );


Obj JuliaEvalString( Obj self, Obj string );

Obj __JuliaUnbox_internal( jl_value_t* julia_obj );
Obj __JuliaUnbox( Obj self, Obj obj );

/*
 * dict: A GAP object, holding a pointer to a julia dict
 * returns: A list, consisting of two lists:
 *   1. A list containing the keys
 *   2. A list containing the values
 */
Obj __JuliaUnbox_record_dict( Obj self, Obj dict );


Obj __JuliaBox( Obj self, Obj obj );


Obj JuliaTuple( Obj self, Obj list );
Obj JuliaSymbol( Obj self, Obj name );

Obj JuliaModule( Obj self, Obj name );

Obj JuliaSetVal( Obj self, Obj name, Obj julia_val );

Obj __JuliaGetGlobalVariable( Obj self, Obj name );
Obj __JuliaGetGlobalVariableByModule( Obj self, Obj name, Obj module_name );

Obj JuliaGetFieldOfObject( Obj self, Obj super_obj, Obj field_name );

Obj __JuliaSetGAPFuncAsJuliaObjFunc( Obj self, Obj func, Obj name, Obj number_args );

Obj __JuliaBindCFunction( Obj self, Obj string_name, Obj cfunction_string,
                                           Obj number_args_gap, Obj arg_names_gap );

// From julia_macros.c

jl_module_t* get_module_from_string( char* name );

#endif