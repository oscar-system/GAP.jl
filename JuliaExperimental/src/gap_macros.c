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

int MyFuncEQ(Obj a, Obj b){
    return EQ(a,b);
}

int MyFuncLT(Obj a, Obj b){
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

void JuliaExperimentalInitializeGAPFunctionPointers( )
{
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
    INITIALIZE_JULIA_CPOINTER(AbsInt);
    INITIALIZE_JULIA_CPOINTER(DEN_RAT);
    INITIALIZE_JULIA_CPOINTER(GcdInt);
    INITIALIZE_JULIA_CPOINTER(NUM_RAT);
}
