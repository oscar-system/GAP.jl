## Conversion to GAP

to_gap(v :: MPtr)       = v
to_gap(v :: GapFFE)     = v
to_gap(v :: String)     = MakeString(v)
to_gap(v :: Bool)       = v ? True : False

function to_gap(v :: Array{T, 1} where T) :: MPtr
    l = NewPlist(length(v))
    for i in 1:length(v)
        l[i] = v[i]
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


from_gap_string(obj :: MPtr) = CSTR_STRING(obj)
from_gap_symbol(obj :: MPtr) = Symbol(from_gap_string(obj))

function from_gap_list( obj :: MPtr)
    len = length( obj )
    array = Array{Any,1}( undef, len)
    for i in 1:len
        array[i] = obj[i]
    end
    return array
end

function from_gap_bool( obj :: MPtr ) :: Bool
    return obj == True
end

from_gap(x,::Type{Any})    = x
from_gap(x,::Type{String}) = from_gap_string( x )
from_gap(x,::Type{Symbol}) = from_gap_symbol( x )
from_gap(x,::Type{Bool})   = from_gap_bool( x )

function from_gap_list_type( obj :: MPtr, element_type :: DataType ) 
    len_list = length(obj)
    new_array = Array{element_type,1}( undef, len_list)
    for i in 1:len_list
        new_array[ i ] = from_gap(obj[i],element_type)
    end
    return new_array
end

from_gap_list_int16( x ) = from_gap_list_type( x, Int16 )
from_gap_list_int32( x ) = from_gap_list_type( x, Int32 )
from_gap_list_int64( x ) = from_gap_list_type( x, Int64 )
from_gap_list_string( x ) = from_gap_list_type( x, String )
from_gap_list_symbol( x ) = from_gap_list_type( x, Symbol )
