## Converters

## Default
gap_to_julia(::Type{GAPInputType},x::GAPInputType) = x
gap_to_julia(::Type{Any},         x::GAPInputType) = gap_to_julia(x)

## Integers
gap_to_julia(::Type{Int128} ,x::Int64) = trunc(Int128 ,x)
gap_to_julia(::Type{Int64}  ,x::Int64) = x
gap_to_julia(::Type{Int32}  ,x::Int64) = trunc(Int32  ,x)
gap_to_julia(::Type{Int16}  ,x::Int64) = trunc(Int16  ,x)
gap_to_julia(::Type{Int8}   ,x::Int64) = trunc(Int8   ,x)

## Unsigned Integers
gap_to_julia(::Type{UInt128},x::Int64) = trunc(UInt128,x)
gap_to_julia(::Type{UInt64} ,x::Int64) = trunc(UInt64 ,x)
gap_to_julia(::Type{UInt32} ,x::Int64) = trunc(UInt32 ,x)
gap_to_julia(::Type{UInt16} ,x::Int64) = trunc(UInt16 ,x)
gap_to_julia(::Type{UInt8}  ,x::Int64) = trunc(UInt8  ,x)

function gap_to_julia(::Type{AbstractString},obj::MPtr)
    if ! Globals.IsStringRep(obj)
        throw(ArgumentError("<obj> is not a string"))
    end
    return CSTR_STRING(obj)
end
gap_to_julia(::Type{Symbol},obj::MPtr) = Symbol(gap_to_julia(AbstractString,obj))

## BigInts
gap_to_julia(::Type{BigInt}, x::Int64) = BigInt( x )

function gap_to_julia(::Type{BigInt}, x::MPtr )
    ## Check for correct type
    if ! Globals.IsInt(x)
        throw(ArgumentError("GAP object is not a large integer"))
    end
    ## get size of GAP BigInt (in limbs), multiply
    ## by 64 to get bits
    size_limbs = ccall(:GAP_SizeInt,Cint,(MPtr,),x)
    size = abs(size_limbs * sizeof(UInt) * 8)
    ## allocate new GMP
    new_bigint = Base.GMP.MPZ.realloc2(size)
    new_bigint.size = size_limbs
    ## Get limb address ptr
    addr = ccall(:GAP_AddrInt,Ptr{UInt},(MPtr,),x)
    ## Copy limbs
    unsafe_copyto!( new_bigint.d, addr, abs(size_limbs) )
    return new_bigint
end

function gap_to_julia( ::Type{Array{GAPObj,1}}, obj :: MPtr )
    len_list = length(obj)
    new_array = Array{GAPObj,1}( undef, len_list)
    for i in 1:len_list
        new_array[ i ] = obj[i]
    end
    return new_array
end

function gap_to_julia( ::Type{Array{T,1}}, obj :: MPtr ) where T
    len_list = length(obj)
    new_array = Array{T,1}( undef, len_list)
    for i in 1:len_list
        new_array[ i ] = gap_to_julia(T,obj[i])
    end
    return new_array
end

function gap_to_julia( ::Type{Dict{Symbol,T}}, obj :: MPtr ) where T
    if ! Globals.IsRecord( obj )
        throw(ArgumentError("first argument is not a record"))
    end
    names = Globals.RecNames( obj )
    names_list = gap_to_julia(Array{Symbol,1},names)
    dict = Dict{Symbol,T}()
    for i in names_list
        dict[ i ] = gap_to_julia(T,getproperty(obj,i))
    end
    return dict
end
