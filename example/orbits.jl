function bahn( self::Ptr{Void}, element::Ptr{Void}, generators::Ptr{Void},
                                action::Ptr{Void}, comparison::Ptr{Void} )::Ptr{Void}
    work_set = [ element ]
    return_set = Array{Ptr{Void},1}([element])
    generator_length = ccall(gap_LengthList,Int64,(Ptr{Void},),generators)
    length_work_set = length(work_set)
    while length_work_set != 0
        current_element = pop!(work_set)
        for current_generator_number = 1:generator_length
            current_generator = ccall(gap_Elm0_List,Ptr{Void},(Ptr{Void},Int),generators,current_generator_number)
            current_result = ccall( gap_DoOperation2Args, Ptr{Void}, (Ptr{Void},Ptr{Void},Ptr{Void}),
                                                                      action, current_element, current_generator )
            if ! any( i -> i == current_result, return_set )
                push!( work_set, current_result )
                push!( return_set, current_result )
            end
        end
        length_work_set=length(work_set)
    end
    print( return_set )
    return gap_True
end
