function bahn( element, generators, action )
    orb = [ element ]
    dict = Dict(element=>1)
    for b in orb
        for g in generators
            c = action(b, g)
            x = get(dict, c, nothing)
            if x == nothing
                push!( orb, c )
                dict[c] = length(orb)
            end
        end
    end
    return orb
end
