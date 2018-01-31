// Functions for accessing GAP macros
// This file should be completely obsolete
// once LibGap is completed


// Provide C functions that can call the functions
// in GAP's kernel tables (see GAP's 'src/ariths.h').
// (not yet: _MUT variants of ZERO, AINV, ONE, INV, and IN, LQUO, COMM)
Obj MyFuncZERO(Obj a){
    return ZERO(a);
}

Obj MyFuncAINV(Obj a){
    return AINV(a);
}

Obj MyFuncONE(Obj a){
    return ONE(a);
}

Obj MyFuncINV(Obj a){
    return INV(a);
}

Obj MyFuncEQ(Obj a, Obj b){
    return EQ(a,b);
}

Obj MyFuncLT(Obj a, Obj b){
    return LT(a,b);
}

Obj MyFuncSUM(Obj a, Obj b){
    return SUM(a,b);
}

Obj MyFuncDIFF(Obj a, Obj b){
    return DIFF(a,b);
}

Obj MyFuncPROD(Obj a, Obj b){
    return PROD(a,b);
}

Obj MyFuncQUO(Obj a, Obj b){
    return QUO(a,b);
}

Obj MyFuncPOW(Obj a, Obj b){
    return POW(a,b);
}

Obj MyFuncMOD(Obj a, Obj b){
    return MOD(a,b);
}


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

#define INITIALIZE_JULIA_CPOINTER(name)\
gap_ptr = jl_box_voidpointer( name );\
gap_symbol = jl_symbol( "gap_" #name );\
JULIAINTERFACE_EXCEPTION_HANDLER \
jl_set_const( jl_main_module, gap_symbol, gap_ptr );\
JULIAINTERFACE_EXCEPTION_HANDLER

void JuliaInitializeGAPFunctionPointers( )
{
    jl_value_t* gap_ptr;
    jl_sym_t * gap_symbol;

    INITIALIZE_JULIA_CPOINTER(MakeGapArgList);
    INITIALIZE_JULIA_CPOINTER(pin_gap_obj);
    INITIALIZE_JULIA_CPOINTER(unpin_gap_obj);
    INITIALIZE_JULIA_CPOINTER(CallFuncList);
    INITIALIZE_JULIA_CPOINTER(RNamName);
    INITIALIZE_JULIA_CPOINTER(ElmPRec);

// Those might not be necessary anymore

    // arithmetic operations
    INITIALIZE_JULIA_CPOINTER(MyFuncZERO);
    INITIALIZE_JULIA_CPOINTER(MyFuncAINV);
    INITIALIZE_JULIA_CPOINTER(MyFuncONE);
    INITIALIZE_JULIA_CPOINTER(MyFuncINV);
    INITIALIZE_JULIA_CPOINTER(MyFuncEQ);
    INITIALIZE_JULIA_CPOINTER(MyFuncLT);
    INITIALIZE_JULIA_CPOINTER(MyFuncSUM);
    INITIALIZE_JULIA_CPOINTER(MyFuncDIFF);
    INITIALIZE_JULIA_CPOINTER(MyFuncPROD);
    INITIALIZE_JULIA_CPOINTER(MyFuncQUO);
    INITIALIZE_JULIA_CPOINTER(MyFuncPOW);
    INITIALIZE_JULIA_CPOINTER(MyFuncMOD);

    INITIALIZE_JULIA_CPOINTER(LengthList);
    INITIALIZE_JULIA_CPOINTER(Elm0_List);
    INITIALIZE_JULIA_CPOINTER(True);
    INITIALIZE_JULIA_CPOINTER(False);
    INITIALIZE_JULIA_CPOINTER(MyTNUM_OBJ);
}
