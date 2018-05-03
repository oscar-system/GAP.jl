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
    Obj numerator_obj = INTOBJ_INT( numerator );
    Obj denominator_obj = INTOBJ_INT( denominator );

    Obj rational_obj = NewBag( T_RAT, 2 * sizeof(Obj) );

    SET_NUM_RAT( rational_obj, numerator_obj );
    SET_DEN_RAT( rational_obj, denominator_obj );

    return rational_obj;
}


int pin_gap_obj( Obj obj )
{
    Obj pos;
    Obj gap_obj_gc_list_positions = ValGVar( GVarName( "gap_obj_gc_list_positions" ) );
    pos = PopPlist( gap_obj_gc_list_positions );
    Obj gap_obj_gc_list = ValGVar( GVarName( "gap_obj_gc_list" ) );
    AssPlist( gap_obj_gc_list, INT_INTOBJ( pos ), obj );
    gap_obj_gc_list = ValGVar( GVarName( "gap_obj_gc_list" ) );
    CHANGED_BAG(gap_obj_gc_list);
    gap_obj_gc_list_positions = ValGVar( GVarName( "gap_obj_gc_list_positions" ) );
    if(LEN_PLIST(gap_obj_gc_list_positions) == 0)
    {
        PushPlist( gap_obj_gc_list_positions, INTOBJ_INT( LEN_PLIST( gap_obj_gc_list ) + 1 ) );
    }
    return INT_INTOBJ( pos );
}

void unpin_gap_obj( int pos )
{
    Obj gap_obj_gc_list = ValGVar( GVarName( "gap_obj_gc_list" ) );
    AssPlist( gap_obj_gc_list, pos, True );
    Obj gap_obj_gc_list_positions = ValGVar( GVarName( "gap_obj_gc_list_positions" ) );
    PushPlist( gap_obj_gc_list_positions, INTOBJ_INT( pos ) );
}

void JuliaInitializeGAPFunctionPointers( )
{

    INITIALIZE_JULIA_CPOINTER(MakeGapArgList);
    INITIALIZE_JULIA_CPOINTER(pin_gap_obj);
    INITIALIZE_JULIA_CPOINTER(unpin_gap_obj);
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
}
