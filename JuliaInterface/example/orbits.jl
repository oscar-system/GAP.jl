function bahn( element, generators, action )
    work_set = [element]
    return_set = [element]
    action_func = GAP.GapFunc( action )
    generator_length = length(generators)
    while length(work_set) != 0
        current_element = pop!(work_set)
        for current_generator_number = 1:generator_length
            current_generator = generators[current_generator_number]
            current_result = action(current_element,current_generator)
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
    return ccall(:NewJuliaObj,Ptr{CVoid},(Ptr{CVoid},),pointer_from_objref(return_set))
end
