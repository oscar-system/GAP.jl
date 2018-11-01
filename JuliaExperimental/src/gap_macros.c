// Functions for accessing GAP macros
// This file should be completely obsolete
// once LibGap is completed

#include <src/compiled.h>

// Provide C functions that can call the functions
// in GAP's kernel tables (see GAP's 'src/ariths.h').
// (not yet: _MUT variants of ZERO, AINV, ONE, INV, and IN, LQUO, COMM)
Obj MyFuncZERO(Obj a)
{
    return ZERO(a);
}

Obj MyFuncAINV(Obj a)
{
    return AINV(a);
}

Obj MyFuncONE(Obj a)
{
    return ONE(a);
}

Obj MyFuncINV(Obj a)
{
    return INV(a);
}

int MyFuncEQ(Obj a, Obj b)
{
    return EQ(a, b);
}

int MyFuncLT(Obj a, Obj b)
{
    return LT(a, b);
}

Obj MyFuncSUM(Obj a, Obj b)
{
    return SUM(a, b);
}

Obj MyFuncDIFF(Obj a, Obj b)
{
    return DIFF(a, b);
}

Obj MyFuncPROD(Obj a, Obj b)
{
    return PROD(a, b);
}

Obj MyFuncQUO(Obj a, Obj b)
{
    return QUO(a, b);
}

Obj MyFuncPOW(Obj a, Obj b)
{
    return POW(a, b);
}

Obj MyFuncMOD(Obj a, Obj b)
{
    return MOD(a, b);
}

Obj create_rational(int numerator, int denominator)
{
    Obj numerator_obj = ObjInt_Int(numerator);
    Obj denominator_obj = ObjInt_Int(denominator);

    Obj rational_obj = NewBag(T_RAT, 2 * sizeof(Obj));

    SET_NUM_RAT(rational_obj, numerator_obj);
    SET_DEN_RAT(rational_obj, denominator_obj);

    return rational_obj;
}
