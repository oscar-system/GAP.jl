#
# functions which directly interact with GAP objects, bypassing the GAP kernel
#
function TNUM_OBJ(obj::GapObj)
    mptr = Ptr{Ptr{Culonglong}}(pointer_from_objref(obj))
    bag_ptr = unsafe_load(mptr)
    header = unsafe_load(bag_ptr, 0)
    return Int(header & 0xFF)
end

function FLAGS_OBJ(obj::GapObj)
    mptr = Ptr{Ptr{Culonglong}}(pointer_from_objref(obj))
    bag_ptr = unsafe_load(mptr)
    header = unsafe_load(bag_ptr, 0)
    return Int((header >> 8) & 0xFF)
end

function SIZE_OBJ(obj::GapObj)
    mptr = Ptr{Ptr{Culonglong}}(pointer_from_objref(obj))
    bag_ptr = unsafe_load(mptr)
    header = unsafe_load(bag_ptr, 0)
    return Int((header >> 16))
end
