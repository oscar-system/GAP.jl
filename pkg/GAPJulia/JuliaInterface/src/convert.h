#ifndef JULIAINTERFACE_CONVERT_H
#define JULIAINTERFACE_CONVERT_H

#include <julia.h>
#include <libgap-api.h>

extern jl_value_t * julia_gap(Obj obj);
extern Obj          gap_julia(jl_value_t * julia_obj);

#endif
