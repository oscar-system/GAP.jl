# ATM, this causes more problems than it serves.
# There is no arithmetic installed for Ptr{Void}

# struct GapObj
#     ptr::Ptr{Void}
# end

module GAP

gap_funcs = Array{Any,1}();

gap_object_finalizer = function(obj)
    ccall(Main.gap_unpin_gap_obj,Void,(Cint,),obj.index)
end

mutable struct GapObj
    ptr::Ptr{Void}
    index
    function GapObj(ptr::Ptr{Void})
        index = ccall(Main.gap_pin_gap_obj,Cint,(Ptr{Void},),ptr)
        new_obj = new(ptr,index)
        finalizer(new_obj,gap_object_finalizer)
        return new_obj
    end
end

struct GapFunc
    ptr::Ptr{Void}
end

function(func::GapFunc)(args...)
    arg_array = collect(args)
    arg_array = map(i->i.ptr,arg_array)
    length_array = length(arg_array)
    gap_arg_list = GapObj(ccall(Main.gap_MakeGapArgList,Ptr{Void},
                                (Cint,Ptr{Ptr{Void}}),length_array,arg_array))
    return GapObj(ccall(Main.gap_CallFuncList,Ptr{Void},
                        (Ptr{Void},Ptr{Void}),func.ptr,gap_arg_list.ptr))
end

function prepare_func_for_gap(gap_func)
    return_func = function(self,args...)
        new_args = map(GapObj,args)
        return_value = gap_func(new_args...)
        return return_value.ptr
    end
    push!(gap_funcs,return_func)
    return return_func
end

export gap_funcs, prepare_func_for_gap, GapObj, GapFunc, gap_object_finalizer

end
