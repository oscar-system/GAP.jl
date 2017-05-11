/*
 * JuliaInterface: Test interface to julia
 */

#include "src/compiled.h"          /* GAP headers */
#include <julia.h>

#undef PACKAGE_BUGREPORT
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_URL
#undef PACKAGE_VERSION
#include "pkgconfig.h"


Obj TheTypeJuliaFunction;
Obj TheTypeJuliaObject;

void SET_JULIA_FUNC(Obj o, jl_function_t* f) {
    ADDR_OBJ(o)[0] = (Obj)f;
}

void SET_JULIA_OBJ(Obj o, jl_value_t* p) {
    ADDR_OBJ(o)[0] = (Obj)p;
}


jl_function_t* GET_JULIA_FUNC(Obj o) {
    return (jl_function_t*)(ADDR_OBJ(o)[0]);
}


jl_value_t* GET_JULIA_OBJ(Obj o) {
    return (jl_value_t*)(ADDR_OBJ(o)[0]);
}

Obj JuliaFunctionTypeFunc(Obj o)
{
    return TheTypeJuliaFunction;
}

Obj JuliaObjectTypeFunc(Obj o)
{
    return TheTypeJuliaObject;
}


#define IS_JULIA_FUNC(o) (TNUM_OBJ(o) == T_JULIA_FUNC)
#define IS_JULIA_OBJ(o) (TNUM_OBJ(o) == T_JULIA_OBJ)

UInt T_JULIA_FUNC = 0;
UInt T_JULIA_OBJ = 0;

Obj NewJuliaFunc(jl_function_t* C)
{
    Obj o;
    o = NewBag(T_JULIA_FUNC, 1 * sizeof(Obj));
    SET_JULIA_FUNC(o, C);
    return o;
}

Obj NewJuliaObj(jl_value_t* C)
{
    Obj o;
    o = NewBag(T_JULIA_OBJ, 1 * sizeof(Obj));
    SET_JULIA_OBJ(o, C);
    return o;
}

Obj JuliaFunction( Obj self, Obj string )
{
    
    return NewJuliaFunc( jl_get_function(jl_base_module, CSTR_STRING( string ) ) );
    
}

Obj JuliaCallFunc1Arg( Obj self, Obj func, Obj arg )
{
    return NewJuliaObj( jl_call1( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg ) ) );
}

Obj JuliaCallFunc2Arg( Obj self, Obj func, Obj arg1, Obj arg2 )
{
    return NewJuliaObj( jl_call2( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg1 ), GET_JULIA_OBJ( arg2 ) ) );
}

Obj JuliaEvalString( Obj self, Obj string )
{
    jl_value_t* result = jl_eval_string( CSTR_STRING( string ) );
    if(!jl_is_nothing(result)){
      return NewJuliaObj( result );
    }
    return 0;
}

Obj JuliaUnbox( Obj self, Obj obj )
{   
    jl_value_t* julia_obj=GET_JULIA_OBJ( obj );
    if(jl_typeis(julia_obj, jl_int64_type)){
        return INTOBJ_INT( jl_unbox_int64( julia_obj ) );
    }
    else if(jl_typeis(julia_obj, jl_float64_type)){
        return NEW_MACFLOAT( jl_unbox_float64( julia_obj ) );
    }
    return Fail;
}

Obj JuliaBox( Obj self, Obj obj )
{   
    if(IS_INTOBJ(obj)){
        return NewJuliaObj( jl_box_int64( INT_INTOBJ( obj ) ) );
    }
    else if(IS_MACFLOAT(obj)){
        return NewJuliaObj( jl_box_float64( VAL_MACFLOAT( obj ) ) );
    }
    return Fail;
}



typedef Obj (* GVarFunc)(/*arguments*/);

#define GVAR_FUNC_TABLE_ENTRY(srcfile, name, nparam, params) \
  {#name, nparam, \
   params, \
   (GVarFunc)name, \
   srcfile ":Func" #name }

// Table of functions to export
static StructGVarFunc GVarFuncs [] = {
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaFunction, 1, "string" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaCallFunc1Arg, 2, "func,obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaCallFunc2Arg, 3, "func,obj1,obj2" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaEvalString, 1, "string" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaUnbox, 1, "obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaBox, 1, "obj" ),

	{ 0 } /* Finish with an empty entry */

};

/******************************************************************************
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel( StructInitInfo *module )
{
    /* init filters and functions                                          */
    InitHdlrFuncsFromTable( GVarFuncs );
    
    InitCopyGVar( "TheTypeJuliaFunction", &TheTypeJuliaFunction );
    InitCopyGVar( "TheTypeJuliaObject", &TheTypeJuliaObject );
    
    T_JULIA_FUNC = RegisterPackageTNUM("JuliaFunction", JuliaFunctionTypeFunc );
    T_JULIA_OBJ = RegisterPackageTNUM("JuliaObject", JuliaObjectTypeFunc );
    
    InitMarkFuncBags(T_JULIA_FUNC, &MarkNoSubBags);
    InitMarkFuncBags(T_JULIA_OBJ, &MarkNoSubBags);

    // Initialize libjulia
//     jl_init(JULIA_LDPATH);
    jl_init();

    // HACK: disable the julia garbage collector for now
    jl_gc_enable(0);

    /* return success                                                      */
    return 0;
}

/******************************************************************************
*F  InitLibrary( <module> ) . . . . . . .  initialise library data structures
*/
static Int InitLibrary( StructInitInfo *module )
{
    /* init filters and functions */
    InitGVarFuncsFromTable( GVarFuncs );

    /* return success                                                      */
    return 0;
}

/******************************************************************************
*F  InitInfopl()  . . . . . . . . . . . . . . . . . table of init functions
*/
static StructInitInfo module = {
 /* type        = */ MODULE_DYNAMIC,
 /* name        = */ "JuliaInterface",
 /* revision_c  = */ 0,
 /* revision_h  = */ 0,
 /* version     = */ 0,
 /* crc         = */ 0,
 /* initKernel  = */ InitKernel,
 /* initLibrary = */ InitLibrary,
 /* checkInit   = */ 0,
 /* preSave     = */ 0,
 /* postSave    = */ 0,
 /* postRestore = */ 0
};

StructInitInfo *Init__Dynamic( void )
{
    return &module;
}
