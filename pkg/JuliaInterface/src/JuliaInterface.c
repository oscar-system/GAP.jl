/*
 * JuliaInterface: Interface to julia
 */

#include "JuliaInterface.h"

#include "calls.h"
#include "convert.h"
#include "sync.h"

#include <julia_gc.h>    // GAP header

#include <julia_gcext.h>    // Julia header

jl_module_t * gap_module;

static jl_value_t *    JULIA_ERROR_IOBuffer;
static jl_function_t * JULIA_FUNC_take_inplace;
static jl_function_t * JULIA_FUNC_showerror;
static jl_datatype_t * JULIA_GAPFFE_type;

static jl_datatype_t * gap_datatype_mptr;

static Obj  TheTypeOfJuliaModules;
static Obj  TheTypeJuliaObject;
static UInt T_JULIA_OBJ;

Obj JULIAINTERFACE_IsJuliaWrapper;
Obj JULIAINTERFACE_JuliaPointer;

void handle_jl_exception(void)
{
    jl_call2(JULIA_FUNC_showerror, JULIA_ERROR_IOBuffer,
             jl_exception_occurred());
    jl_value_t * string_object =
        jl_call1(JULIA_FUNC_take_inplace, JULIA_ERROR_IOBuffer);
    string_object = jl_array_to_string((jl_array_t *)string_object);
    BEGIN_GAP_SYNC();
    ErrorMayQuit("%s", (Int)jl_string_data(string_object), 0);
    END_GAP_SYNC();
}

jl_value_t * gap_box_gapffe(Obj value)
{
#if (JULIA_VERSION_MAJOR * 100 + JULIA_VERSION_MINOR) <= 106
    jl_ptls_t ptls = jl_get_ptls_states();
#else
    jl_ptls_t ptls = jl_get_current_task()->ptls;
#endif
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

static BOOL JuliaObjIsMutableFunc(Obj obj)
{
    /* always immutable as GAP object */
    return 0L;
}

inline int IS_JULIA_OBJ(Obj o)
{
    return TNUM_OBJ(o) == T_JULIA_OBJ;
}

jl_value_t * GET_JULIA_OBJ(Obj o)
{
    return (jl_value_t *)(CONST_ADDR_OBJ(o)[0]);
}

static Obj JuliaObjectTypeFunc(Obj o)
{
    if (jl_typeis(GET_JULIA_OBJ(o), jl_module_type))
        return TheTypeOfJuliaModules;
    else
        return TheTypeJuliaObject;
}

Obj NewJuliaObj(jl_value_t * v)
{
    if (is_gapobj(v))
        return (Obj)v;
    JL_GC_PUSH1(&v);
    Obj o = NewBag(T_JULIA_OBJ, 1 * sizeof(Obj));
    ADDR_OBJ(o)[0] = (Obj)v;
    JL_GC_POP();
    return o;
}


void ResetUserHasQUIT(void)
{
    STATE(UserHasQUIT) = 0;
}


/*
 * Wrap Julia object <func> into a GAP function.
 */
static Obj Func_WrapJuliaFunction(Obj self, Obj func)
{
    if (!IS_JULIA_OBJ(func))
        ErrorMayQuit("argument is not a julia object", 0, 0);

    jl_function_t * f = (jl_function_t *)GET_JULIA_OBJ(func);
    return WrapJuliaFunc(f);
}

// Export 'IS_JULIA_FUNC' to the GAP level.
static Obj FuncIS_JULIA_FUNC(Obj self, Obj obj)
{
    return IS_JULIA_FUNC(obj) ? True : False;
}

// Executes the string <string> in the current julia session.
static Obj FuncJuliaEvalString(Obj self, Obj string)
{
    BEGIN_GAP_SYNC();
    RequireStringRep("JuliaEvalString", string);

    jl_value_t * result = jl_eval_string(CONST_CSTR_STRING(string));
    END_GAP_SYNC();
    if (jl_exception_occurred()) {
        handle_jl_exception();
    }
    return gap_julia(result);
}

// internal wrapper for jl_boundp to deal with API change in Julia 1.12
static int gap_jl_boundp(jl_module_t * m, jl_sym_t * var)
{
#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR >= 12
    return jl_boundp(m, var, 1);
#else
    return jl_boundp(m, var);
#endif
}

// Returns the julia object GAP object that holds a pointer to the value
// currently bound to the julia identifier <moduleName>.<name>.
static Obj Func_JuliaGetGlobalVariableByModule(Obj self, Obj name, Obj module)
{
    BEGIN_GAP_SYNC();
    RequireStringRep("_JuliaGetGlobalVariableByModule", name);

    jl_module_t * m = 0;
    if (IS_JULIA_OBJ(module)) {
        m = (jl_module_t *)GET_JULIA_OBJ(module);
        if (!jl_is_module(m))
            m = 0;
    }
    if (!m) {
        ErrorMayQuit("_JuliaGetGlobalVariableByModule: <module> must be a "
                     "Julia module",
                     0, 0);
    }
    jl_sym_t * symbol = jl_symbol(CONST_CSTR_STRING(name));
    END_GAP_SYNC();

#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR >= 12
    // WORKAROUND issue #1132
    jl_task_t * ct = jl_get_current_task();
    size_t      last_world = ct->world_age;
    ct->world_age = jl_get_world_counter();
#endif

    Obj result;
    if (!gap_jl_boundp(m, symbol)) {
        result = Fail;
    }
    else {
        jl_value_t * value = jl_get_global(m, symbol);
        result = gap_julia(value);
    }
#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR >= 12
    ct->world_age = last_world;
#endif
    return result;
}

static Obj Func_JuliaGetGapModule(Obj self)
{
    return NewJuliaObj((jl_value_t *)gap_module);
}

static Obj Func_JuliaGetMainModule(Obj self)
{
    return NewJuliaObj((jl_value_t *)jl_main_module);
}

// Mark the Julia pointer inside the GAP JuliaObj
#ifdef GAP_MARK_FUNC_WITH_REF
// for GAP >= 4.13.0
static void MarkJuliaObject(Bag bag, void * ref)
{
#ifdef DEBUG_MASTERPOINTERS
    MarkJuliaObjSafe((void *)GET_JULIA_OBJ(bag), ref);
#else
    MarkJuliaObj((void *)GET_JULIA_OBJ(bag), ref);
#endif
}
#else
// for GAP <= 4.12.x
static void MarkJuliaObject(Bag bag)
{
#ifdef DEBUG_MASTERPOINTERS
    MarkJuliaObjSafe((void *)GET_JULIA_OBJ(bag));
#else
    MarkJuliaObj((void *)GET_JULIA_OBJ(bag));
#endif
}
#endif

// Table of functions to export
static StructGVarFunc GVarFuncs[] = {
    GVAR_FUNC(_WrapJuliaFunction, 1, "juliafunc"),
    GVAR_FUNC(IS_JULIA_FUNC, 1, "obj"),
    GVAR_FUNC(JuliaEvalString, 1, "string"),
    GVAR_FUNC(_JuliaGetGlobalVariableByModule, 2, "name, module"),
    GVAR_FUNC(_JuliaGetGapModule, 0, ""),
    GVAR_FUNC(_JuliaGetMainModule, 0, ""),
    { 0 } /* Finish with an empty entry */

};

/****************************************************************************
**
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel(StructInitInfo * module)
{
    if (!gap_module) {
        ErrorMayQuit("gap_module was not set", 0, 0);
    }

    JULIA_GAPFFE_type =
        (jl_datatype_t *)jl_get_global(gap_module, jl_symbol("FFE"));
    if (!JULIA_GAPFFE_type) {
        ErrorMayQuit("Could not locate the GAP.FFE datatype", 0, 0);
    }

    InitGapSync();

    // init filters and functions
    InitHdlrFuncsFromTable(GVarFuncs);

    InitCopyGVar("TheTypeOfJuliaModules", &TheTypeOfJuliaModules);
    InitCopyGVar("TheTypeJuliaObject", &TheTypeJuliaObject);

    T_JULIA_OBJ = RegisterPackageTNUM("JuliaObject", JuliaObjectTypeFunc);

    InitMarkFuncBags(T_JULIA_OBJ, &MarkJuliaObject);

    CopyObjFuncs[T_JULIA_OBJ] = &JuliaObjCopyFunc;
    CleanObjFuncs[T_JULIA_OBJ] = &JuliaObjCleanFunc;
    IsMutableObjFuncs[T_JULIA_OBJ] = &JuliaObjIsMutableFunc;

    // Initialize necessary variables for error handling
    JULIA_ERROR_IOBuffer =
        jl_call0(jl_get_function(jl_base_module, "IOBuffer"));
    GAP_ASSERT(JULIA_ERROR_IOBuffer);
    // store the IO buffer object to protect it from being garbage collected
    jl_set_const(gap_module, jl_symbol("error_buffer"), JULIA_ERROR_IOBuffer);

    JULIA_FUNC_take_inplace = jl_get_function(jl_base_module, "take!");
    GAP_ASSERT(JULIA_FUNC_take_inplace);

    JULIA_FUNC_showerror = jl_get_function(jl_base_module, "showerror");
    GAP_ASSERT(JULIA_FUNC_showerror);

    // paranoia: verify that Julia's GMP has the BITS_PER_LIMB we expect
    jl_module_t * gmp_module =
        (jl_module_t *)jl_get_global(jl_base_module, jl_symbol("GMP"));
    GAP_ASSERT(gmp_module);
    int bits_per_limb =
        jl_unbox_long(jl_get_global(gmp_module, jl_symbol("BITS_PER_LIMB")));
    if (sizeof(UInt) * 8 != bits_per_limb) {
        Panic("GMP limb size is %d in GAP and %d in Julia",
              (int)sizeof(UInt) * 8, bits_per_limb);
    }

    // import mptr type from GAP, by getting the Julia type of any GAP object
    gap_datatype_mptr = (jl_datatype_t *)jl_typeof(True);
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
