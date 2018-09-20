// Functions for accessing GAP macros
// This file should be completely obsolete
// once LibGap is completed


// Provide other access functions.
Int LengthList( Obj list ){
    return LEN_PLIST( list );
}

Obj Elm0_List( Obj list, int pos ){
    return ELM_PLIST( list, pos );
}

int MyTNUM_OBJ(Obj obj)
{
    return TNUM_OBJ( obj );
}

Obj Call0Args(Obj func)
{
    return CALL_0ARGS(func);
}

Obj Call1Args(Obj func, Obj a)
{
    return CALL_1ARGS(func,a);
}

Obj Call2Args(Obj func, Obj a1, Obj a2)
{
    return CALL_2ARGS(func,a1,a2);
}

Obj Call3Args(Obj func, Obj a1, Obj a2, Obj a3)
{
    return CALL_3ARGS(func,a1,a2,a3);
}

Obj Call4Args(Obj func, Obj a1, Obj a2, Obj a3, Obj a4)
{
    return CALL_4ARGS(func,a1,a2,a3,a4);
}

Obj Call5Args(Obj func, Obj a1, Obj a2, Obj a3, Obj a4, Obj a5)
{
    return CALL_5ARGS(func,a1,a2,a3,a4,a5);
}

Obj Call6Args(Obj func, Obj a1, Obj a2, Obj a3, Obj a4, Obj a5, Obj a6 )
{
    return CALL_6ARGS(func,a1,a2,a3,a4,a5,a6);
}

Obj CallXArgs(Obj func, Obj arg_list)
{
    return CALL_XARGS(func,arg_list);
}

Obj MakeGapArgList( int length, Obj* array )
{
  Obj list = NEW_PLIST(T_PLIST,length);
  SET_LEN_PLIST(list,0);
  for(int i=0;i<length;i++)
  {
    PushPlist(list,array[i]);
  }
  return list;
}

Obj create_rational( int numerator, int denominator )
{
    Obj numerator_obj = ObjInt_Int( numerator );
    Obj denominator_obj = ObjInt_Int( denominator );

    Obj rational_obj = NewBag( T_RAT, 2 * sizeof(Obj) );

    SET_NUM_RAT( rational_obj, numerator_obj );
    SET_DEN_RAT( rational_obj, denominator_obj );

    return rational_obj;
}

jl_value_t* julia_gap(Obj obj)
{
    if(IS_INT(obj)){
        return jl_box_int64(INT_INTOBJ(obj));
    }
    if(IS_FFE(obj)){
        //TODO
        return jl_nothing;
    }
    return (jl_value_t*)obj;
}

Obj gap_julia(jl_value_t* julia_obj)
{
    if(jl_typeis(julia_obj,jl_int64_type)) {
        return ObjInt_Int8(jl_unbox_int64(julia_obj));
    }
    if(IsGapObj(julia_obj)){
        return (Obj)(julia_obj);
    }
    return NewJuliaObj(julia_obj);
}

jl_value_t* call_gap_func(void* func, jl_value_t* arg_array){
    jl_array_t* array_ptr = (jl_array_t*)arg_array;
    size_t len = jl_array_len(array_ptr);
    Obj arg_list = NEW_PLIST( T_PLIST, len );
    SET_LEN_PLIST(arg_list, len);
    for(size_t i=0;i<len;i++){
        SET_ELM_PLIST( arg_list, i+1, gap_julia( jl_arrayref( array_ptr, i ) ) );
        CHANGED_BAG( arg_list );
    }
    Obj return_val = CallFuncList((Obj)(func),arg_list);
    if(return_val == NULL){
        return jl_nothing;
    }
    return julia_gap(return_val);
}

void JuliaInitializeGAPFunctionPointers( )
{

    INITIALIZE_JULIA_CPOINTER(MakeGapArgList);
    INITIALIZE_JULIA_CPOINTER(CallFuncList);
    INITIALIZE_JULIA_CPOINTER(RNamName);
    INITIALIZE_JULIA_CPOINTER(ElmPRec);
    INITIALIZE_JULIA_CPOINTER(INTOBJ_INT);

    INITIALIZE_JULIA_CPOINTER(INTOBJ_INT);
    INITIALIZE_JULIA_CPOINTER(create_rational);

// Those might not be necessary anymore

    INITIALIZE_JULIA_CPOINTER(AbsInt);
    INITIALIZE_JULIA_CPOINTER(DEN_RAT);
    INITIALIZE_JULIA_CPOINTER(GcdInt);
    INITIALIZE_JULIA_CPOINTER(NUM_RAT);

    INITIALIZE_JULIA_CPOINTER(LengthList);
    INITIALIZE_JULIA_CPOINTER(Elm0_List);
    INITIALIZE_JULIA_CPOINTER(True);
    INITIALIZE_JULIA_CPOINTER(False);
    INITIALIZE_JULIA_CPOINTER(MyTNUM_OBJ);
    INITIALIZE_JULIA_CPOINTER(Call2Args);
    INITIALIZE_JULIA_CPOINTER(NewJuliaObj);
    INITIALIZE_JULIA_CPOINTER(GET_JULIA_OBJ);

    INITIALIZE_JULIA_CPOINTER(call_gap_func);
    INITIALIZE_JULIA_CPOINTER(julia_gap);
    INITIALIZE_JULIA_CPOINTER(gap_julia);
}
