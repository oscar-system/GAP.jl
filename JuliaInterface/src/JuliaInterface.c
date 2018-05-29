/*
 * JuliaInterface: Test interface to julia
 */

#include "JuliaInterface.h"

#include "gap_macros.c"

Obj TheTypeJuliaFunction;
Obj TheTypeJuliaObject;

#include "julia_macros.c"

jl_function_t* julia_array_pop;
jl_function_t* julia_array_push;
jl_function_t* julia_array_setindex;
jl_value_t* GAP_MEMORY_STORAGE_INTS;
jl_value_t* GAP_MEMORY_STORAGE;

/*
 * utilities for wrapped Julia objects and functions
 */
Obj JuliaFuncCopyFunc(Obj obj, Int mut)
{
    /* always immutable, so nothing to do */
    return obj;
}
Obj JuliaObjCopyFunc(Obj obj, Int mut)
{
    /* always immutable in GAP, so nothing to do */
    return obj;
}
void JuliaFuncCleanFunc(Obj obj)
{
}
void JuliaObjCleanFunc(Obj obj)
{
}
Int JuliaFuncIsMutableFunc(Obj obj)
{
    /* always immutable */
    return 0L;
}
Int JuliaObjIsMutableFunc(Obj obj)
{
    /* always immutable as GAP object */
    return 0L;
}

jl_value_t* get_next_julia_position(){
    jl_value_t* position_jl = jl_call1( julia_array_pop, GAP_MEMORY_STORAGE_INTS );
    int position = jl_unbox_int64( position_jl );
    if(jl_unbox_int64(jl_eval_string("length(GAP_MEMORY_STORAGE_INTS)"))==0){
        jl_call2( julia_array_push, GAP_MEMORY_STORAGE, jl_box_int64( 0 ) );
        JULIAINTERFACE_EXCEPTION_HANDLER
        jl_value_t* new_position_jl = jl_box_int64( jl_unbox_int64(jl_eval_string("length(GAP_MEMORY_STORAGE)")) + 1 );
        jl_call2( julia_array_push, GAP_MEMORY_STORAGE_INTS, new_position_jl );
        JULIAINTERFACE_EXCEPTION_HANDLER
    }
    return position_jl;
}

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
    o = NewBag(T_JULIA_OBJ, 2 * sizeof(Obj));
    SET_JULIA_OBJ(o, C);
    jl_value_t* input_position_jl = get_next_julia_position();
    ADDR_OBJ(o)[1] = (Obj)jl_unbox_int64( input_position_jl );
    jl_call3( julia_array_setindex, GAP_MEMORY_STORAGE, C, input_position_jl );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return o;
}

void JuliaObjFreeFunc( Obj val )
{
    jl_value_t* list_number = jl_box_int64((long)(ADDR_OBJ(val)[1]));
    jl_call3( julia_array_setindex, GAP_MEMORY_STORAGE, jl_true, list_number );
    JULIAINTERFACE_EXCEPTION_HANDLER
    jl_call2( julia_array_push, GAP_MEMORY_STORAGE_INTS, list_number );
    JULIAINTERFACE_EXCEPTION_HANDLER
}

/*
 * Returns the function with name <string> from the Julia main module.
 */
Obj __JuliaFunction( Obj self, Obj string )
{
    jl_function_t* function = jl_get_function(jl_main_module, CSTR_STRING( string ) );
    if(function==0)
        ErrorMayQuit( "Function is not defined in julia", 0, 0 );
    return NewJuliaFunc( function );
}

/*
 * Returns the function with name <function_name> from the Julia module with name <module_name>.
 */
Obj __JuliaFunctionByModule( Obj self, Obj function_name, Obj module_name )
{
    jl_module_t* module_t = get_module_from_string( CSTR_STRING( module_name ) );
    jl_function_t* function = jl_get_function(module_t, CSTR_STRING( function_name ) );
    if(function==0)
        ErrorMayQuit( "Function is not defined in julia", 0, 0 );
    return NewJuliaFunc( function );
}

Obj __JuliaCallFunc0Arg( Obj self, Obj func )
{
    jl_value_t* return_value = jl_call0( GET_JULIA_FUNC( func ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( return_value );
}

Obj __JuliaCallFunc1Arg( Obj self, Obj func, Obj arg )
{
    jl_value_t* return_value = jl_call1( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( return_value );

}

Obj __JuliaCallFunc2Arg( Obj self, Obj func, Obj arg1, Obj arg2 )
{
    jl_value_t* return_value = jl_call2( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg1 ), GET_JULIA_OBJ( arg2 ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( return_value );
}

Obj __JuliaCallFunc3Arg( Obj self, Obj func, Obj arg1, Obj arg2, Obj arg3 )
{
    jl_value_t* return_value = jl_call3( GET_JULIA_FUNC( func ), GET_JULIA_OBJ( arg1 ),
                                                                 GET_JULIA_OBJ( arg2 ),
                                                                 GET_JULIA_OBJ( arg3 ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( return_value );
}

Obj __JuliaCallFuncXArg( Obj self, Obj func, Obj args )
{
    int32_t len = LEN_PLIST( args );
    Obj current_element;
    int32_t i;
    jl_value_t* arg_pointer[len];
    for(i=0;i<len;i++){
        current_element = ELM_PLIST( args, i + 1 );
        arg_pointer[ i ] = GET_JULIA_OBJ(current_element);
    }
    jl_value_t * return_val = jl_call( GET_JULIA_FUNC( func ), arg_pointer, len );
    JULIAINTERFACE_EXCEPTION_HANDLER
    current_element = NewJuliaObj( return_val );
    return current_element;
}

Obj JuliaEvalString( Obj self, Obj string )
{
    jl_value_t* result = jl_eval_string( CSTR_STRING( string ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    if(!jl_is_nothing(result)){
      return NewJuliaObj( result );
    }
    return 0;
}

Obj __JuliaUnbox_internal( jl_value_t* julia_obj )
{
    size_t i;

    // small int
    if(jl_typeis(julia_obj, jl_int64_type)){
        return INTOBJ_INT( jl_unbox_int64( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_int32_type)){
        return INTOBJ_INT( jl_unbox_int32( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_int16_type)){
        return INTOBJ_INT( jl_unbox_int16( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_int8_type)){
        return INTOBJ_INT( jl_unbox_int8( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint64_type)){
        return INTOBJ_INT( jl_unbox_uint64( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint32_type)){
        return INTOBJ_INT( jl_unbox_uint32( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint16_type)){
        return INTOBJ_INT( jl_unbox_uint16( julia_obj ) );
    }
    if(jl_typeis(julia_obj, jl_uint8_type)){
        return INTOBJ_INT( jl_unbox_uint8( julia_obj ) );
    }

    // float
    else if(jl_typeis(julia_obj, jl_float64_type)){
        return NEW_MACFLOAT( jl_unbox_float64( julia_obj ) );
    }
    else if(jl_typeis(julia_obj, jl_float32_type)){
        return NEW_MACFLOAT( jl_unbox_float32( julia_obj ) );
    }

    // string
    else if(jl_typeis(julia_obj, jl_string_type)){
        Obj return_string;
        C_NEW_STRING( return_string, jl_string_len( julia_obj ), jl_string_data( julia_obj ) );
        return return_string;
    }

    // bool
    else if(jl_typeis(julia_obj, jl_bool_type)){
        if(jl_unbox_bool(julia_obj)==0){
            return False;
        }
        else{
            return True;
        }
    }

    // array (1-dim)
    else if(jl_is_array(julia_obj)){
        Obj current_element;
        jl_array_t* array_ptr = (jl_array_t*)julia_obj;
        size_t len = jl_array_len(array_ptr);
        Obj return_list = NEW_PLIST( T_PLIST, len );
        SET_LEN_PLIST( return_list, len );
        for(i=0;i<len;i++){
            if(!jl_array_isassigned(array_ptr,i)){
                continue;
            }
            jl_value_t* current_jl_element = jl_arrayref( array_ptr, i );
            current_element = NewJuliaObj( current_jl_element );
            SET_ELM_PLIST( return_list, i+1, current_element );
            CHANGED_BAG( return_list );
        }
        return return_list;
    }

    else if(jl_is_symbol(julia_obj)){
      Obj return_string;
      char* symbol_name = jl_symbol_name((jl_sym_t*)julia_obj);
      C_NEW_STRING( return_string, strlen( symbol_name ), symbol_name );
      return return_string;
    }

    return Fail;
}

Obj __JuliaUnbox( Obj self, Obj obj )
{
    if(!IS_JULIA_OBJ(obj))
    {
        ErrorMayQuit( "<obj> is not a boxed julia obj", 0, 0 );
        return NULL;
    }
    jl_value_t* julia_obj = GET_JULIA_OBJ( obj );
    return __JuliaUnbox_internal( julia_obj );
}

jl_value_t* __ConvertedToJulia_internal( Obj obj )
{
    size_t i;
    Obj current;

    //integer, small and large
    if(IS_INTOBJ(obj)){
        return jl_box_int64( INT_INTOBJ( obj ) );
        // TODO: BIGINT
    }

    //float
    else if(IS_MACFLOAT(obj)){
        return jl_box_float64( VAL_MACFLOAT( obj ) );
    }

    //string
    else if(IS_STRING_REP(obj)){
        return jl_cstr_to_string( CSTR_STRING( obj ) );
    }

    //bool
    else if(obj == True){
        return jl_true;
    }
    else if(obj == False){
        return jl_false;
    }

    //perm
    else if(TNUM_OBJ(obj) == T_PERM2){
        jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_uint16_type,1);
        jl_array_t* new_perm_array = jl_alloc_array_1d(array_type, DEG_PERM2(obj));
        UInt2* perm_array = ADDR_PERM2(obj);
        for(i=0;i<DEG_PERM2(obj);i++){
            jl_arrayset(new_perm_array, jl_box_uint16( perm_array[ i ] ), i );
        }
        return (jl_value_t*)(new_perm_array);
    }

    else if(TNUM_OBJ(obj) == T_PERM4){
        jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_uint32_type,1);
        jl_array_t* new_perm_array = jl_alloc_array_1d(array_type, DEG_PERM4(obj));
        UInt4* perm_array = ADDR_PERM4(obj);
        for(i=0;i<DEG_PERM4(obj);i++){
            jl_arrayset(new_perm_array, jl_box_uint32( perm_array[ i ] ), i );
        }
        return (jl_value_t*)(new_perm_array);
    }

    // plist
    else if(IS_PLIST(obj)){
        size_t len = LEN_PLIST(obj);
        jl_value_t* array_type = jl_apply_array_type((jl_value_t*)jl_any_type,1);
        jl_array_t* new_array = jl_alloc_array_1d(array_type, len);
        for(i=0;i<len;i++){
            current = ELM_PLIST(obj,i+1);
            if(current == NULL){
                continue;
            }
            jl_arrayset(new_array,__ConvertedToJulia_internal(ELM_PLIST(obj,i+1)),i);
        }
        return (jl_value_t*)(new_array);
    }

    // Julia object/function: relevant in recursive situations
    else if ( IS_JULIA_OBJ(obj) ) {
        return GET_JULIA_OBJ(obj);
    }
    else if ( IS_JULIA_FUNC(obj) ) {
        return GET_JULIA_FUNC(obj);
    }

    return 0;
}

Obj __ConvertedToJulia( Obj self, Obj obj )
{
    if( IS_JULIA_OBJ(obj) || IS_JULIA_FUNC(obj) ){
        return obj;
    }
    jl_value_t* julia_ptr = __ConvertedToJulia_internal( obj );
    if( julia_ptr == 0)
        return Fail;
    return NewJuliaObj( julia_ptr );
}

// dict: A GAP object, holding a pointer to a julia dict
// returns: A list, consisting of two lists:
//   1. A list containing the keys
//   2. A list containing the values
Obj __JuliaUnbox_record_dict( Obj self, Obj dict )
{
    if(!IS_JULIA_OBJ(dict)){
        ErrorQuit( "input must be a boxed julia object", 0, 0 );
        return NULL;
    }
    // FIXME: Check for dict
    jl_value_t* julia_dict = GET_JULIA_OBJ( dict );

    // Currently, keys have offset 1, while values have offset 2.
    jl_array_t* dict_slots = (jl_array_t*)jl_get_field(julia_dict,"slots");
    jl_array_t* dict_indices = (jl_array_t*)jl_get_field(julia_dict,"keys");
    jl_array_t* dict_values = (jl_array_t*)jl_get_field(julia_dict,"vals");

    // Prepare lists of keys, values
    size_t len = jl_array_len(dict_indices);
    Obj indices_gap = NEW_PLIST( T_PLIST, len );
    Obj values_gap = NEW_PLIST( T_PLIST, len );

    // 
    Obj current_element;
    jl_value_t* current_value;
    jl_value_t* current_index;
    size_t real_index = 0;

    // Store keys and values in GAP list
    for(size_t i = 0; i < len; ++i )
    {
        if(! jl_unbox_uint8(jl_arrayref(dict_slots,i)))
        {
            continue;
        }
        real_index++;
        current_value = jl_arrayref( dict_values, i );
        current_index = jl_arrayref( dict_indices, i );
        SET_ELM_PLIST( values_gap, real_index, NewJuliaObj( current_value ) );
        CHANGED_BAG( values_gap );
        SET_ELM_PLIST( indices_gap, real_index, NewJuliaObj( current_index ) );
        CHANGED_BAG( indices_gap );
    }

    SET_LEN_PLIST( indices_gap, real_index );
    SET_LEN_PLIST( values_gap, real_index );

    // Construct and return list
    Obj return_list = NEW_PLIST( T_PLIST, 2 );
    SET_LEN_PLIST( return_list, 2 );
    SET_ELM_PLIST( return_list, 1, indices_gap );
    CHANGED_BAG( return_list );
    SET_ELM_PLIST( return_list, 2, values_gap );
    CHANGED_BAG( return_list );
    return return_list;
}

Obj JuliaTuple( Obj self, Obj list )
{
    jl_datatype_t* tuple_type = 0;
    jl_svec_t* params = 0;
    jl_svec_t* param_types = 0;
    jl_value_t* result = 0;
    JL_GC_PUSH4(&tuple_type, &params, &param_types, &result);

    if(!IS_PLIST(list)){
        ErrorMayQuit("argument is not a plain list",0,0);
    }
    int len = LEN_PLIST(list);
    params = jl_alloc_svec(len);
    param_types = jl_alloc_svec(len);
    for(int i=0;i<len;i++){
        jl_value_t* current_obj = __ConvertedToJulia_internal(ELM_PLIST(list,i+1));
        jl_svecset( params, i, current_obj );
        jl_svecset( param_types, i, jl_typeof(current_obj) );
    }
    tuple_type = jl_apply_tuple_type(param_types);
    JULIAINTERFACE_EXCEPTION_HANDLER
    result = jl_new_structv(tuple_type,jl_svec_data(params),len);
    JULIAINTERFACE_EXCEPTION_HANDLER
    JL_GC_POP();
    return NewJuliaObj( result );
}

Obj JuliaSymbol( Obj self, Obj name )
{
    jl_sym_t* julia_symbol = jl_symbol( CSTR_STRING( name ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( (jl_value_t*)julia_symbol );
}

Obj JuliaModule( Obj self, Obj name )
{
    jl_module_t* julia_module = get_module_from_string( CSTR_STRING( name ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( (jl_value_t*)julia_module );
}

Obj JuliaSetVal( Obj self, Obj name, Obj julia_val )
{
    jl_value_t* julia_obj= GET_JULIA_OBJ( julia_val );
    jl_sym_t* julia_symbol = jl_symbol( CSTR_STRING( name ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    jl_set_global( jl_main_module, julia_symbol, julia_obj );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return 0;
}

Obj __JuliaGetGlobalVariable( Obj self, Obj name )
{
    jl_sym_t* symbol = jl_symbol( CSTR_STRING( name ) );
    if(!jl_boundp(jl_main_module,symbol)){
        ErrorMayQuit( "variable is not bound in module main", 0, 0 );
        return NULL;
    }
    jl_value_t* value = jl_get_global( jl_main_module, symbol );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( value );
}

Obj __JuliaGetGlobalVariableByModule( Obj self, Obj name, Obj module_name )
{
    jl_sym_t* symbol = jl_symbol( CSTR_STRING( name ) );
    jl_module_t* module_t = get_module_from_string( CSTR_STRING( module_name ) );
    if(!jl_boundp(module_t,symbol)){
        ErrorMayQuit( "variable is not bound", 0, 0 );
        return NULL;
    }
    jl_value_t* value = jl_get_global( module_t, symbol );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( value );
}

Obj JuliaGetFieldOfObject( Obj self, Obj super_obj, Obj field_name )
{
    jl_value_t* extracted_superobj = GET_JULIA_OBJ( super_obj );
    jl_value_t* field_value = jl_get_field( extracted_superobj, CSTR_STRING( field_name ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( field_value );
}

Obj __JuliaSetGAPFuncAsJuliaObjFunc( Obj self, Obj func, Obj name, Obj number_args )
{
    jl_value_t* module_value = jl_eval_string( "GAP" );
    JULIAINTERFACE_EXCEPTION_HANDLER
    if(!jl_is_module(module_value))
      ErrorMayQuit("GAP module not yet defined",0,0);
    jl_module_t* module_t = (jl_module_t*)module_value;
    jl_function_t* set_gap_func_obj = jl_get_function( module_t, "GapFunc" );
    JULIAINTERFACE_EXCEPTION_HANDLER
    jl_value_t* gap_func_obj = jl_call1(set_gap_func_obj,
                                        jl_box_voidpointer(func));
    JULIAINTERFACE_EXCEPTION_HANDLER
    jl_sym_t* function_name = jl_symbol( CSTR_STRING( name ) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    jl_set_global( module_t, function_name, gap_func_obj );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NULL;
}

Obj JuliaSetAsJuliaPointer( Obj self, Obj obj )
{
    jl_value_t* module_value = jl_eval_string( "GAP" );
    JULIAINTERFACE_EXCEPTION_HANDLER
    if(!jl_is_module(module_value))
          ErrorMayQuit("GAP module not yet defined",0,0);
    jl_module_t* module_t = (jl_module_t*)module_value;
    jl_function_t* set_gap_obj = jl_get_function( module_t, "GapObj" );
    JULIAINTERFACE_EXCEPTION_HANDLER
    jl_value_t* gap_obj_ptr = jl_call1( set_gap_obj, jl_box_voidpointer(obj) );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return NewJuliaObj( gap_obj_ptr );
}

Obj JuliaGetFromJuliaPointer( Obj self, Obj obj )
{
    jl_value_t* julia_ptr = GET_JULIA_OBJ( obj );
    jl_value_t* gap_ptr = jl_get_field( julia_ptr, "ptr" );
    JULIAINTERFACE_EXCEPTION_HANDLER
    return (Obj)(jl_unbox_voidpointer(gap_ptr));
}

typedef Obj (* GVarFunc)(/*arguments*/);

#define GVAR_FUNC_TABLE_ENTRY_WITH_NAME(srcfile, name, nparam, params, string_name) \
 {string_name, nparam, \
  params, \
  (GVarFunc)name, \
  srcfile ":JuliaFunc" }
// FIXME: Provide better name


Obj __JuliaBindCFunction( Obj self, Obj cfunction_string,
                                           Obj number_args_gap, Obj arg_names_gap )
{
    void* ccall_pointer = jl_unbox_voidpointer( jl_eval_string( CSTR_STRING( cfunction_string ) ) );
    size_t number_args = INT_INTOBJ( number_args_gap );
    return NewFunction(0, number_args, arg_names_gap, ccall_pointer );
}

#define GVAR_FUNC_TABLE_ENTRY(srcfile, name, nparam, params) \
  {#name, nparam, \
   params, \
   (GVarFunc)name, \
   srcfile ":Func" #name }

// Table of functions to export
static StructGVarFunc GVarFuncs [] = {
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaFunction, 1, "string" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaFunctionByModule, 2, "function_name,module_name" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaCallFunc0Arg, 1, "func" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaCallFunc1Arg, 2, "func,obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaCallFunc2Arg, 3, "func,obj1,obj2" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaCallFunc3Arg, 4, "func,obj1,obj2,obj3" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaCallFuncXArg, 2, "func,arg_list" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaEvalString, 1, "string" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaUnbox, 1, "obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __ConvertedToJulia, 1, "obj" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaSetVal, 2, "name,val" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaGetGlobalVariable, 1, "name" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaGetGlobalVariableByModule, 2, "name,module" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaGetFieldOfObject, 2, "obj,name" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaBindCFunction, 3, "cfunction_string,number_args_gap,arg_names_gap" ),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaSetGAPFuncAsJuliaObjFunc, 2, "func,name"),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaTuple, 1, "list"),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaSymbol, 1, "name"),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaModule, 1, "name"),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", __JuliaUnbox_record_dict, 1, "dict"),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaSetAsJuliaPointer, 1, "obj"),
    GVAR_FUNC_TABLE_ENTRY("JuliaInterface.c", JuliaGetFromJuliaPointer, 1, "obj"),

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

    CopyObjFuncs[T_JULIA_FUNC] = &JuliaFuncCopyFunc;
    CleanObjFuncs[T_JULIA_FUNC] = &JuliaFuncCleanFunc;
    IsMutableObjFuncs[T_JULIA_FUNC] = &JuliaFuncIsMutableFunc;
    CopyObjFuncs[T_JULIA_OBJ] = &JuliaObjCopyFunc;
    CleanObjFuncs[T_JULIA_OBJ] = &JuliaObjCleanFunc;
    IsMutableObjFuncs[T_JULIA_OBJ] = &JuliaObjIsMutableFunc;

    InitFreeFuncBag(T_JULIA_OBJ, &JuliaObjFreeFunc );
    /* no free func for julia function objects ??? */

    // Initialize libjulia
    jl_init();

    // Initialize GAP function pointers in Julia
    JuliaInitializeGAPFunctionPointers( );

    julia_array_pop = jl_get_function( jl_base_module, "pop!" );
    julia_array_push = jl_get_function( jl_base_module, "push!" );
    julia_array_setindex = jl_get_function( jl_base_module, "setindex!" );
    GAP_MEMORY_STORAGE = jl_eval_string( "GAP_MEMORY_STORAGE = [ ]" );
    GAP_MEMORY_STORAGE_INTS = jl_eval_string( "GAP_MEMORY_STORAGE_INTS = [ 1 ]" );

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
