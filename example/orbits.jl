function gap_LengthPlist(list::Ptr{Void})
    return ccall(gap_LengthList,Int64,(Ptr{Void},),list)
end

function gap_ListElement(list::Ptr{Void},pos::Int)
    return ccall(gap_Elm0_List,Ptr{Void},(Ptr{Void},Int),list,pos)
end

function gap_CallFunc2Args(func::Ptr{Void},arg1::Ptr{Void},arg2::Ptr{Void})
    return ccall( gap_Call2Args, Ptr{Void}, (Ptr{Void},Ptr{Void},Ptr{Void}), func,arg1,arg2 )
end

function bahn( self::Ptr{Void}, element::Ptr{Void}, generators::Ptr{Void},
                                action::Ptr{Void} )
    work_set = [element]
    return_set = [element]
    generator_length = gap_LengthPlist(generators)
    while length(work_set) != 0
        current_element = pop!(work_set)
        for current_generator_number = 1:generator_length
            current_generator = gap_ListElement(generators,current_generator_number)
            current_result = gap_CallFunc2Args(action,current_element,current_generator)
            is_in_set = false
            for  i in return_set
                if i == current_result
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
    return gap_True
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
    return gap_True
end
