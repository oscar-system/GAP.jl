#
# hardcoded TNUM values: these are unlikely to change, but to be
# safe, we check them in __init__ via some assertions
#
const T_INT      = 0    # integer
const T_INTPOS   = 1    # large positive integer
const T_INTNEG   = 2    # large negative integer
const T_RAT      = 3    # rational
const T_CYC      = 4    # cyclotomic
const T_FFE      = 5    # ffe
const T_MACFLOAT = 6    # macfloat
const T_PERM2    = 7    # permutation (small)
const T_PERM4    = 8    # permutation (large)
const T_TRANS2   = 9    # transformation (small)
const T_TRANS4   = 10   # transformation (large)
const T_PPERM2   = 11   # partial perm (small)
const T_PPERM4   = 12   # partial perm (large)
const T_BOOL     = 13   # boolean or fail
const T_CHAR     = 14   # character
const T_FUNCTION = 15   # function
const T_BODY     = 16   # function body bag
const T_FLAGS    = 17   # flags list
const T_LVARS    = 18   # values bag
const T_HVARS    = 19   # high variables bag

const FIRST_EXTERNAL_TNUM = 82

#
# functions which directly interact with GAP objects, bypassing the GAP kernel
#
function ADDR_OBJ(obj::GapObj)
    mptr = Ptr{Ptr{Csize_t}}(pointer_from_objref(obj))
    return unsafe_load(mptr)
end

function TNUM_OBJ(obj::GapObj)
    header = unsafe_load(ADDR_OBJ(obj), 0)
    return reinterpret(Int, header & 0xFF)
end

function TNUM_OBJ(ptr::Ptr)
    mptr = Ptr{Ptr{Csize_t}}(ptr)
    header = unsafe_load(unsafe_load(mptr), 0)
    return reinterpret(Int, header & 0xFF)
end

function FLAGS_OBJ(obj::GapObj)
    header = unsafe_load(ADDR_OBJ(obj), 0)
    return reinterpret(Int, (header >> 8) & 0xFF)
end

function SIZE_OBJ(obj::GapObj)
    header = unsafe_load(ADDR_OBJ(obj), 0)
    return reinterpret(Int, (header >> 16))
end

# given a GAP T_FUNCTION object, fetch its n-th function handler (handler 0-6
# are for calls with that many arguments, handler 7 is for any higher number
# of arguments)
function GET_FUNC_PTR(obj::GapObj, narg::Int)
    #@assert TNUM_OBJ(obj) == T_FUNCTION
    #@assert 0 <= narg && narg <= 7
    bag_ptr = Ptr{Ptr{Nothing}}(ADDR_OBJ(obj))
    unsafe_load(bag_ptr, narg + 1)
end
