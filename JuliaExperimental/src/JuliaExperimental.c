/*
 * JuliaExperimental: Experimental code for the GAP Julia integration
 */

#include "JuliaInterface.h"          /* JuliaInterface header (includes all the gappy stuff) */

#include "gap_macros.c"


Obj JuliaGAPRatInt( Obj self, Obj integer )
{
    jl_module_t* module_t = get_module_from_string( "GAPRatModule" );
    jl_function_t* func = jl_get_function( module_t, "GAPRat" );
    jl_value_t* rat_obj = jl_call1( func, jl_box_voidpointer( (void*)integer ) );
    return NewJuliaObj( rat_obj );
}

Obj JuliaObjGAPRat( Obj self, Obj gap_rat )
{
    jl_module_t* module_t = get_module_from_string( "GAPRatModule" );
    jl_function_t* func = jl_get_function( module_t, "get_gaprat_ptr" );
    void* rat_obj = jl_unbox_voidpointer( jl_call1( func, GET_JULIA_OBJ( gap_rat ) ) );
    return (Obj)rat_obj;
}

typedef Obj (* GVarFunc)(/*arguments*/);

#define GVAR_FUNC_TABLE_ENTRY(srcfile, name, nparam, params) \
  {#name, nparam, \
   params, \
   (GVarFunc)name, \
   srcfile ":Func" #name }

// Table of functions to export
static StructGVarFunc GVarFuncs [] = {
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaGAPRatInt, 1, "number"),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaObjGAPRat, 1, "obj"),

	{ 0 } /* Finish with an empty entry */

};

/******************************************************************************
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel( StructInitInfo *module )
{
    /* init filters and functions                                          */
    InitHdlrFuncsFromTable( GVarFuncs );
    JuliaExperimentalInitializeGAPFunctionPointers();

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
 /* name        = */ "JuliaExperimental",
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
