function gap_LengthPlist(list)
    return ccall(:LengthList,Int64,(Ptr{Void},),list.ptr)
end

function gap_ListElement(list,pos::Int)
    return GAP.GapObj(ccall(:Elm0_List,Ptr{Void},(Ptr{Void},Int),list.ptr,pos))
end

function gap_CallFunc2Args(func,arg1,arg2)
    return GAP.GapObj(ccall( :Call2Args, Ptr{Void}, (Ptr{Void},Ptr{Void},Ptr{Void}), func.ptr,arg1.ptr,arg2.ptr ))
end

function bahn( element, generators, action )
    work_set = [element]
    return_set = [element]
    generator_length = gap_LengthPlist(generators)
    while length(work_set) != 0
        current_element = pop!(work_set)
        for current_generator_number = 1:generator_length
            current_generator = gap_ListElement(generators,current_generator_number)
            current_result = gap_CallFunc2Args(action,current_element,current_generator)
            is_in_set = false
            for i in return_set
                if i.ptr == current_result.ptr
                    is_in_set = true
                    break
                end
            end
            if ! is_in_set
                push!( work_set, current_result )
                push!( return_set, current_result )
            end
        end
    end
    pointer = ccall(:NewJuliaObj,Ptr{Void},(Ptr{Void},),pointer_from_objref(return_set))
    return GAP.GapObj(pointer)
end

function bahn_with_any( self::Ptr{Void}, element::Ptr{Void}, generators::Ptr{Void},
                                action::Ptr{Void} )
    work_set = [reinterpret(Int,element)]
    return_set = [reinterpret(Int,element)]
    generator_length = gap_LengthPlist(generators)
    function eq(comparator)
        return function( i ) return i == comparator end
    end
    while length(work_set) != 0
        current_element = pop!(work_set)
        for current_generator_number = 1:generator_length
            current_generator = gap_ListElement(generators,current_generator_number)
            current_result = reinterpret(Int,gap_CallFunc2Args(action,
                                        reinterpret(Ptr{Void},current_element),current_generator))::Int
            if ! any( eq(current_result), return_set )
                push!( work_set, current_result )
                push!( return_set, current_result )
            end
        end
    end
    return GAP.True
end
