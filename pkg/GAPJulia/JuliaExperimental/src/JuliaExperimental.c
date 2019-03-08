/*
 * JuliaExperimental: Experimental code for the GAP Julia integration
 */

#include "JuliaInterface.h" /* JuliaInterface header (includes all the gappy stuff) */

#include <src/compiled.h>

// Table of functions to export
static StructGVarFunc GVarFuncs[] = {

    { 0 } /* Finish with an empty entry */

};

/****************************************************************************
**
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel(StructInitInfo * module)
{
    // init filters and functions
    InitHdlrFuncsFromTable(GVarFuncs);

    // return success
    return 0;
}

/****************************************************************************
**
*F  InitLibrary( <module> ) . . . . . . .  initialise library data structures
*/
static Int InitLibrary(StructInitInfo * module)
{
    // init filters and functions
    InitGVarFuncsFromTable(GVarFuncs);

    // return success
    return 0;
}

/****************************************************************************
**
*F  Init__Dynamic() . . . . . . . . . . . . . . . . . table of init functions
*/
StructInitInfo * Init__Dynamic(void)
{
    static StructInitInfo module = {
        .type = MODULE_DYNAMIC,
        .name = "JuliaExperimental",
        .initKernel = InitKernel,
        .initLibrary = InitLibrary,
    };
    return &module;
}
