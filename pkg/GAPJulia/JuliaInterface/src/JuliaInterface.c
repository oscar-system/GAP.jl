/*
 * JuliaInterface: Test interface to julia
 */

#include "JuliaInterface.h"

#include "calls.h"
#include "convert.h"

#include <src/compiled.h>    // GAP headers
#include <src/julia_gc.h>

#include <julia_gcext.h>


static jl_value_t *    JULIA_ERROR_IOBuffer;
static jl_function_t * JULIA_FUNC_take_inplace;
static jl_function_t * JULIA_FUNC_String_constructor;
static jl_function_t * JULIA_FUNC_showerror;
static jl_datatype_t * JULIA_GAPFFE_type;

static jl_value_t * jl_bigint_type = NULL;

jl_datatype_t * gap_datatype_mptr;

Obj  TheTypeJuliaObject;
UInt T_JULIA_OBJ;

Obj JULIAINTERFACE_IsJuliaWrapper;
Obj JULIAINTERFACE_JuliaPointer;

void handle_jl_exception(void)
{
    jl_call2(JULIA_FUNC_showerror, JULIA_ERROR_IOBuffer,
             jl_exception_occurred());
    jl_value_t * string_object =
        jl_call1(JULIA_FUNC_take_inplace, JULIA_ERROR_IOBuffer);
    string_object = jl_call1(JULIA_FUNC_String_constructor, string_object);
    ErrorMayQuit(jl_string_data(string_object), 0, 0);
}

jl_module_t * get_module_from_string(char * name)
{
    // It suffices to use JULIAINTERFACE_EXCEPTION_HANDLER here, as
    // jl_eval_string is part of the jlapi, so don't have to be wrapped in
    // JL_TRY/JL_CATCH.
    jl_value_t * module_value = jl_eval_string(name);
    JULIAINTERFACE_EXCEPTION_HANDLER
    if (!jl_is_module(module_value))
        ErrorQuit("Not a module", 0, 0);
    return (jl_module_t *)module_value;
}

// This function needs to be called after GAP.jl is loaded into julia.
// Therefore we do not call in InitKernel, but in the `read.g` file.
Obj Func_JULIAINTERFACE_INTERNAL_INIT(Obj self)
{
    jl_module_t * gap_module = get_module_from_string("__JULIAGAPMODULE");
    JULIA_GAPFFE_type =
        (jl_datatype_t *)jl_get_global(gap_module, jl_symbol("FFE"));
    if (!JULIA_GAPFFE_type)
        ErrorMayQuit("Could not locate the GAP.FFE datatype", 0, 0);
    return NULL;
}

jl_value_t * gap_box_gapffe(Obj value)
{
    jl_ptls_t    ptls = jl_get_ptls_states();
    jl_value_t * v = jl_gc_alloc_typed(ptls, sizeof(Obj), JULIA_GAPFFE_type);
    *(Obj *)jl_data_ptr(v) = value;
    return v;
}

Obj gap_unbox_gapffe(jl_value_t * gapffe)
{
    return *(Obj *)jl_data_ptr(gapffe);
}

//
int is_gapffe(jl_value_t * v)
{
    return jl_typeis(v, JULIA_GAPFFE_type);
}

//
int is_gapobj(jl_value_t * v)
{
    return jl_typeis(v, gap_datatype_mptr);
}

static Obj Func_NewJuliaCFunc(Obj self, Obj julia_function_ptr, Obj arg_names)
{
    if (!IS_JULIA_OBJ(julia_function_ptr)) {
        ErrorMayQuit("NewJuliaCFunc: <ptr> must be a Julia object", 0, 0);
    }
    if (!IS_PLIST(arg_names)) {
        ErrorMayQuit("NewJuliaCFunc: <arg_names> must be plain list", 0, 0);
    }

    jl_value_t * func_ptr = GET_JULIA_OBJ(julia_function_ptr);
    void *       ptr = jl_unbox_voidpointer(func_ptr);
    return NewJuliaCFunc(ptr, arg_names);
}

/*
 * utilities for wrapped Julia objects and functions
 */
static Obj JuliaObjCopyFunc(Obj obj, Int mut)
{
    /* always immutable in GAP, so nothing to do */
    return obj;
}

static void JuliaObjCleanFunc(Obj obj)
{
}

static Int JuliaObjIsMutableFunc(Obj obj)
{
    /* always immutable as GAP object */
    return 0L;
}

inline int IS_JULIA_OBJ(Obj o)
{
    return TNUM_OBJ(o) == T_JULIA_OBJ;
}

void SET_JULIA_OBJ(Obj o, jl_value_t * p)
{
    ADDR_OBJ(o)[0] = (Obj)p;
}

jl_value_t * GET_JULIA_OBJ(Obj o)
{
    return (jl_value_t *)(ADDR_OBJ(o)[0]);
}

static Obj JuliaObjectTypeFunc(Obj o)
{
    return TheTypeJuliaObject;
}

Obj NewJuliaObj(jl_value_t * v)
{
    if (is_gapobj(v))
        return (Obj)v;
    Obj o = NewBag(T_JULIA_OBJ, 1 * sizeof(Obj));
    SET_JULIA_OBJ(o, v);
    return o;
}


jl_function_t * get_function_from_obj_or_string(Obj func)
{
    if (IS_JULIA_OBJ(func)) {
        return (jl_function_t *)GET_JULIA_OBJ(func);
    }
    if (IsStringConv(func)) {
        // jl_get_function is a thin wrapper for jl_get_global and never
        // throws an exception
        jl_function_t * function =
            jl_get_function(jl_main_module, CSTR_STRING(func));
        if (function == 0) {
            ErrorMayQuit("Function is not defined in julia", 0, 0);
        }
        return function;
    }
    ErrorMayQuit("argument is not a julia object or string", 0, 0);
    return 0;
}


/*
 * Returns the function from the Object <func>
 * or the function with name <func> from
 * the Julia main module.
 */
static Obj Func_JuliaFunction(Obj self, Obj func)
{
    jl_function_t * function = get_function_from_obj_or_string(func);
    return NewJuliaFunc(function);
}

/*
 * Returns the function with name <function_name> from the Julia module with
 * name <module_name>.
 */
static Obj
Func_JuliaFunctionByModule(Obj self, Obj function_name, Obj module_name)
{
    if (!IsStringConv(function_name)) {
        ErrorMayQuit(
            "_JuliaFunctionByModule: <function_name> must be a string", 0, 0);
    }

    if (!IsStringConv(module_name)) {
        ErrorMayQuit("_JuliaFunctionByModule: <module_name> must be a string",
                     0, 0);
    }

    jl_module_t * module_t = get_module_from_string(CSTR_STRING(module_name));
    // jl_get_function is a thin wrapper for jl_get_global and never throws
    // an exception
    jl_function_t * function =
        jl_get_function(module_t, CSTR_STRING(function_name));
    if (function == 0)
        ErrorMayQuit("Function is not defined in julia", 0, 0);
    return NewJuliaFunc(function);
}

// Executes the string <string> in the current julia session.
static Obj FuncJuliaEvalString(Obj self, Obj string)
{
    if (!IsStringConv(string)) {
        ErrorMayQuit("JuliaEvalString: <string> must be a string", 0, 0);
    }

    char * current = CSTR_STRING(string);
    char   copy[strlen(current) + 1];
    strcpy(copy, current);

    // It suffices to use JULIAINTERFACE_EXCEPTION_HANDLER here, as
    // jl_eval_string is part of the jlapi, so don't have to be wrapped in
    // JL_TRY/JL_CATCH.
    jl_value_t * result = jl_eval_string(copy);
    JULIAINTERFACE_EXCEPTION_HANDLER
    return gap_julia(result);
}

// Returns a julia object GAP object that holds the pointer to a julia symbol
// :<name>.
static Obj FuncJuliaSymbol(Obj self, Obj name)
{
    if (!IsStringConv(name)) {
        ErrorMayQuit("JuliaSymbol: <name> must be a string", 0, 0);
    }

    // jl_symbol never throws an exception and always returns a valid
    // result, so no need for extra checks.
    jl_sym_t * julia_symbol = jl_symbol(CSTR_STRING(name));
    return NewJuliaObj((jl_value_t *)julia_symbol);
}

// Sets the value of the julia identifier <name> to the <val>.
// This function is for debugging purposes.
static Obj FuncJuliaSetVal(Obj self, Obj name, Obj val)
{
    if (!IsStringConv(name)) {
        ErrorMayQuit("JuliaSetVal: <name> must be a string", 0, 0);
    }
    jl_value_t * julia_obj = julia_gap(val);
    jl_sym_t *   julia_symbol = jl_symbol(CSTR_STRING(name));
    jl_set_global(jl_main_module, julia_symbol, julia_obj);
    return 0;
}

// Returns the julia object GAP object that holds a pointer to the value
// currently bound to the julia identifier <name>.
static Obj Func_JuliaGetGlobalVariable(Obj self, Obj name)
{
    if (!IsStringConv(name)) {
        ErrorMayQuit("_JuliaGetGlobalVariable: <name> must be a string", 0,
                     0);
    }

    jl_sym_t * symbol = jl_symbol(CSTR_STRING(name));
    if (!jl_boundp(jl_main_module, symbol)) {
        return Fail;
    }
    jl_value_t * value = jl_get_global(jl_main_module, symbol);
    return gap_julia(value);
}

// Returns the julia object GAP object that holds a pointer to the value
// currently bound to the julia identifier <module_name>.<name>.
static Obj Func_JuliaGetGlobalVariableByModule(Obj self, Obj name, Obj module)
{
    if (!IsStringConv(name)) {
        ErrorMayQuit(
            "_JuliaGetGlobalVariableByModule: <name> must be a string", 0, 0);
    }

    jl_module_t * m = 0;
    if (IS_JULIA_OBJ(module)) {
        m = (jl_module_t *)GET_JULIA_OBJ(module);
        if (!jl_is_module(m))
            m = 0;
    }
    else if (IsStringConv(module)) {
        m = get_module_from_string(CSTR_STRING(module));
    }
    if (!m) {
        ErrorMayQuit("_JuliaGetGlobalVariableByModule: <module> must be a "
                     "string or a Julia module",
                     0, 0);
    }
    jl_sym_t * symbol = jl_symbol(CSTR_STRING(name));
    if (!jl_boundp(m, symbol)) {
        return Fail;
    }
    jl_value_t * value = jl_get_global(m, symbol);
    return gap_julia(value);
}

// Returns the julia object GAP object that holds a pointer to the value
// currently bound to <super_object>.<name>.
// <super_object> must be a julia object GAP object, and <name> a string.
static Obj FuncJuliaGetFieldOfObject(Obj self, Obj super_obj, Obj field_name)
{
    if (!IS_JULIA_OBJ(super_obj)) {
        ErrorMayQuit(
            "JuliaGetFieldOfObject: <super_obj> must be a Julia object", 0,
            0);
    }
    if (!IsStringConv(field_name)) {
        ErrorMayQuit("JuliaGetFieldOfObject: <field_name> must be a string",
                     0, 0);
    }

    jl_value_t * extracted_superobj = GET_JULIA_OBJ(super_obj);

    // It suffices to use JULIAINTERFACE_EXCEPTION_HANDLER here, as
    // jl_get_field is part of the jlapi, so don't have to be wrapped in
    // JL_TRY/JL_CATCH.
    jl_value_t * field_value =
        jl_get_field(extracted_superobj, CSTR_STRING(field_name));
    JULIAINTERFACE_EXCEPTION_HANDLER
    return gap_julia(field_value);
}

// Mark the Julia pointer inside the GAP JuliaObj
static void MarkJuliaObject(Bag bag)
{
#ifdef DEBUG_MASTERPOINTERS
    MarkJuliaObjSafe((void *)GET_JULIA_OBJ(bag));
#else
    MarkJuliaObj((void *)GET_JULIA_OBJ(bag));
#endif
}

// Table of functions to export
static StructGVarFunc GVarFuncs[] = {
    GVAR_FUNC(_JuliaFunction, 1, "string"),
    GVAR_FUNC(_JuliaFunctionByModule, 2, "function_name, module_name"),
    GVAR_FUNC(JuliaEvalString, 1, "string"),
    GVAR_FUNC(JuliaSetVal, 2, "name,val"),
    GVAR_FUNC(_JuliaGetGlobalVariable, 1, "name"),
    GVAR_FUNC(_JuliaGetGlobalVariableByModule, 2, "name,module"),
    GVAR_FUNC(JuliaGetFieldOfObject, 2, "obj,name"),
    GVAR_FUNC(JuliaSymbol, 1, "name"),
    GVAR_FUNC(_NewJuliaCFunc, 2, "ptr,arg_names"),
    GVAR_FUNC(_JULIAINTERFACE_INTERNAL_INIT, 0, ""),
    { 0 } /* Finish with an empty entry */

};

/****************************************************************************
**
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel(StructInitInfo * module)
{
    if (getenv("JULIA_TRACK_COVERAGE") != 0) {
        fprintf(stderr, "JULIA_TRACK_COVERAGE enabled\n");
        jl_options.code_coverage = JL_LOG_USER;
        jl_options.can_inline = 0;
    }

    // init filters and functions
    InitHdlrFuncsFromTable(GVarFuncs);

    InitCopyGVar("TheTypeJuliaObject", &TheTypeJuliaObject);

    T_JULIA_OBJ = RegisterPackageTNUM("JuliaObject", JuliaObjectTypeFunc);

    InitMarkFuncBags(T_JULIA_OBJ, &MarkJuliaObject);

    CopyObjFuncs[T_JULIA_OBJ] = &JuliaObjCopyFunc;
    CleanObjFuncs[T_JULIA_OBJ] = &JuliaObjCleanFunc;
    IsMutableObjFuncs[T_JULIA_OBJ] = &JuliaObjIsMutableFunc;

    // Initialize necessary variables for error handling
    JULIA_ERROR_IOBuffer =
        jl_eval_string("GAP_JULIA_ERROR_IO_BUFFER = Base.IOBuffer()");
    JULIA_FUNC_take_inplace = jl_get_function(jl_base_module, "take!");
    JULIA_FUNC_String_constructor = jl_get_function(jl_base_module, "String");
    JULIA_FUNC_showerror = jl_get_function(jl_base_module, "showerror");

    // import bigint type from Julia
    jl_bigint_type = jl_base_module
                         ? jl_get_global(jl_base_module, jl_symbol("BigInt"))
                         : NULL;
    if (jl_bigint_type) {
        jl_module_t * gmp_module =
            (jl_module_t *)jl_get_global(jl_base_module, jl_symbol("GMP"));
        GAP_ASSERT(gmp_module);
        int bits_per_limb = jl_unbox_long(
            jl_get_global(gmp_module, jl_symbol("BITS_PER_LIMB")));
        if (sizeof(UInt) * 8 != bits_per_limb) {
            Panic("GMP limb size is %d in GAP and %d in Julia",
                  sizeof(UInt) * 8, bits_per_limb);
        }
    }

    // import mptr type from GAP
    jl_module_t * gap_module =
        (jl_module_t *)jl_get_global(jl_main_module, jl_symbol("ForeignGAP"));
    GAP_ASSERT(gap_module);
    gap_datatype_mptr =
        (jl_datatype_t *)jl_get_global(gap_module, jl_symbol("MPtr"));
    GAP_ASSERT(gap_datatype_mptr);

    ImportFuncFromLibrary("IsJuliaWrapper", &JULIAINTERFACE_IsJuliaWrapper);
    ImportFuncFromLibrary("JuliaPointer", &JULIAINTERFACE_JuliaPointer);

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
        .name = "JuliaInterface",
        .initKernel = InitKernel,
        .initLibrary = InitLibrary,
    };
    return &module;
}
