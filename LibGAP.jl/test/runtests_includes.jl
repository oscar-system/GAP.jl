
@test GAP.CSTR_STRING(GAP.GAPFuncs.String(GAP.GAPFuncs.PROD(2^59,2^59))) == "332306998946228968225951765070086144"

l = GAP.to_gap([1,2,3])

@test l[1] == 1
