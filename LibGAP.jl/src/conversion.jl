## Conversion to GAP

to_gap(v :: Int64)      = v
to_gap(v :: MPtr)       = v
to_gap(v :: GapFFE)     = v
to_gap(v :: String)     = MakeString(v)
to_gap(v :: Symbol)     = to_gap(string(v))
to_gap(v :: Bool)       = v

function to_gap(v :: Array{T, 1} where T) :: MPtr
    l = NewPlist(length(v))
    for i in 1:length(v)
        l[i] = to_gap(v[i])
    end
    return l
end

## Conversion from GAP
##
## FIXME: these are not very user friendly (user has to know type of the GAP
## object in advanced), and some may even crash. It is not even clear that
## here is the right place to perform most of these conversions, maybe they
## should be done on the GAP and/or in the JuliaInterface GAP kernel
## extension instead. We need to work this out...


from_gap(obj        , ::Any)                  = obj
from_gap(obj :: MPtr, ::Type{AbstractString}) = CSTR_STRING(obj)
from_gap(obj :: MPtr, ::Type{Symbol})         = Symbol(from_gap(obj,AbstractString))

function from_gap( obj :: MPtr, ::Type{Array{T,1}} ) where T
    len_list = length(obj)
    new_array = Array{T,1}( undef, len_list)
    for i in 1:len_list
        new_array[ i ] = from_gap(obj[i],T)
    end
    return new_array
end
