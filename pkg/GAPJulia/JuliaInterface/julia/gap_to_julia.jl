## Converters
"""
    gap_to_julia(type,x,recursion_dict=nothing)

Tries to convert the GAP object `x` to an julia
object of type `type`.

The parameter `recursion_dict` is meant to preseve egality
of converted objects and should never be given by the user.
"""

## Default for conversion:
## Base case for conversion (least specialized method): Allow converting any
## Julia object x to type T, provided that the type of x is a subtype of T;
## otherwise, explicitly reject the conversion.
## As an example why this is useful, suppose you have a GAP list x (i.e., an
## object of type MPtr) containing a bunch of Julia tuples. Then this method
## enables conversion of that list to a Julia array of type Array{Tuple,1},
## like this:
##    gap_to_julia(Array{Tuple{Int64},1},xx)
## This works because first the gap_to_julia method with signature
## (::Type{Array{T,1}}, :: MPtr) is invoked, with T = Tuple{Int64}; this then
## invokes gap_to_julia recursively with signature (::Tuple{Int64},::Any),
## which ends up selecting the method below.
function gap_to_julia(t::T, x::Any) where T <: Type
    if ! (typeof(x) <: t)
        throw(MethodError("Wrong type: expected " * string(t) * ","))
    end
    return x
end

## Default
gap_to_julia(::Type{Any},         x::GAPInputType) = gap_to_julia(x)
gap_to_julia(::Type{Any},         x::Any         ) = x
gap_to_julia(::T,                 x::Nothing     ) where T <: Type = nothing
gap_to_julia(::Type{Any},         x::Nothing     ) = nothing

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

## BigInts
gap_to_julia(::Type{BigInt}, x::Int64) = BigInt( x )

function gap_to_julia(::Type{BigInt}, x::MPtr)
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

## Rationals
function gap_to_julia(::Type{Rational{T}}, x::Int64) where T <: Integer
    numerator = gap_to_julia(T,x)
    return numerator // T(1)
end

function gap_to_julia(::Type{Rational{T}}, x::MPtr) where T <: Integer
    if Globals.IsInt(x)
        return gap_to_julia(T,x) // T(1)
    end
    if ! Globals.IsRat(x)
        throw(ArgumentError("obj is not a rational"))
    end
    numer = Globals.NumeratorRat(x)
    denom = Globals.DenominatorRat(x)
    return gap_to_julia(T,numer) // gap_to_julia(T,denom)
end

## Floats
function gap_to_julia( ::Type{Float64}, obj::MPtr)
    if ! Globals.IsFloat(obj)
        throw(ArgumentError("<obj> is not a MacFloat"))
    end
    return ValueMacFloat(obj)
end

gap_to_julia( ::Type{Float32}, obj::MPtr)  = Float32(gap_to_julia(Float64,obj))
gap_to_julia( ::Type{Float16}, obj::MPtr)  = Float16(gap_to_julia(Float64,obj))
gap_to_julia( ::Type{BigFloat}, obj::MPtr) = BigFloat(gap_to_julia(Float64,obj))

## Chars
function gap_to_julia( ::Type{Cuchar}, obj::MPtr)
    if ! Globals.IsChar( obj )
        throw(ArgumentError("argument is not a character object"))
    end
    return trunc( Cuchar, Globals.INT_CHAR(obj ) )
end

## Strings and symbols
function gap_to_julia(::Type{String},obj::MPtr)
    if ! Globals.IsStringRep(obj)
        throw(ArgumentError("<obj> is not a string"))
    end
    return CSTR_STRING(obj)
end
gap_to_julia(::Type{AbstractString},obj::MPtr) = gap_to_julia(String,obj)
gap_to_julia(::Type{Symbol},obj::MPtr) = Symbol(gap_to_julia(String,obj))

gap_to_julia(type_obj,obj,recursion_dict) = gap_to_julia(type_obj,obj)

## Convert GAP string to Array{UInt8,1}
function gap_to_julia( ::Type{Array{UInt8,1}}, obj :: MPtr )
    ## convert strings to uint8 lists, if requested
    if Globals.IsStringRep( obj )
        array = UNSAFE_CSTR_STRING( obj )
        return deepcopy(array)
    elseif Globals.IsList( obj )
        return Array{UInt8,1}(map(i->gap_to_julia(UInt8,obj[i]),1:length(obj)))
    else
        throw(ArgumentError("<obj> is not a list"))
    end
end

## Arrays
function gap_to_julia( ::Type{Array{Obj,1}}, obj :: MPtr , recursion_dict = IdDict() )
    if ! Globals.IsList( obj )
        throw(ArgumentError("<obj> is not a list"))
    end
    if haskey(recursion_dict,obj)
        return recursion_dict[obj]
    end
    len_list = length(obj)
    new_array = Array{Any,1}( undef, len_list)
    recursion_dict[obj] = new_array
    for i in 1:len_list
        current_obj = ElmList(obj,i)  # returns 'nothing' for holes in the list
        if haskey(recursion_dict,current_obj)
            new_array[ i ] = recursion_dict[current_obj]
        else
            new_array[ i ] = current_obj
            recursion_dict[ current_obj ] = new_array[ i ]
        end
    end
    return new_array
end

function gap_to_julia( ::Type{Array{T,1}}, obj :: MPtr, recursion_dict = IdDict() ) where T
    if ! Globals.IsList( obj )
        throw(ArgumentError("<obj> is not a list"))
    end
    if haskey(recursion_dict,obj)
        return recursion_dict[obj]
    end
    len_list = length(obj)
    new_array = Array{T,1}( undef, len_list)
    recursion_dict[obj] = new_array
    for i in 1:len_list
        current_obj = ElmList(obj,i)
        if haskey(recursion_dict,current_obj)
            new_array[ i ] = recursion_dict[current_obj]
        else
            new_array[ i ] = gap_to_julia(T,current_obj,recursion_dict)
            recursion_dict[ current_obj ] = new_array[ i ]
        end
    end
    return new_array
end

## Special case for conversion of lists with holes; these are converted into 'nothing'
function gap_to_julia( ::Type{Array{Union{Nothing,T},1}}, obj :: MPtr, recursion_dict = IdDict() ) where T
    if ! Globals.IsList( obj )
        throw(ArgumentError("<obj> is not a list"))
    end
    if haskey(recursion_dict,obj)
        return recursion_dict[obj]
    end
    len_list = length(obj)
    new_array = Array{Union{Nothing,T},1}( undef, len_list)
    recursion_dict[obj] = new_array
    for i in 1:len_list
        current_obj = ElmList(obj,i)
        if haskey(recursion_dict,current_obj)
            new_array[ i ] = recursion_dict[current_obj]
        else
            new_array[ i ] = gap_to_julia(T,current_obj,recursion_dict)
            recursion_dict[ current_obj ] = new_array[ i ]
        end
    end
    return new_array
end

function gap_to_julia( ::Type{Array{T,2}}, obj :: MPtr, recursion_dict = IdDict() ) where T
    if ! Globals.IsList( obj )
        throw(ArgumentError("<obj> is not a list"))
    end
    if haskey(recursion_dict, obj)
        return recursion_dict[obj]
    end
    len_list_outer = length(obj)
    len_list_inner = len_list_outer == 0 ? 0 : length(obj[1])
    new_array = Array{T,2}( undef, len_list_outer, len_list_inner )
    recursion_dict[obj] = new_array
    for i in 1:len_list_outer
        for j in 1:len_list_inner
            current_obj = ElmList(ElmList(obj,i), j)
            if haskey(recursion_dict,current_obj)
                new_array[ i, j ] = recursion_dict[current_obj]
            else
                new_array[ i, j ] = gap_to_julia(T,current_obj,recursion_dict)
                recursion_dict[current_obj] = new_array[ i, j ]
            end
        end
    end
    return new_array
end

function gap_to_julia( ::Type{Array{Union{Nothing,T},2}}, obj :: MPtr, recursion_dict = IdDict() ) where T
    if ! Globals.IsList( obj )
        throw(ArgumentError("<obj> is not a list"))
    end
    if haskey(recursion_dict, obj)
        return recursion_dict[obj]
    end
    len_list_outer = length(obj)
    len_list_inner = len_list_outer == 0 ? 0 : length(obj[1])
    new_array = Array{Union{Nothing,T},2}( undef, len_list_outer, len_list_inner )
    recursion_dict[obj] = new_array
    for i in 1:len_list_outer
        for j in 1:len_list_inner
            current_obj = ElmList(ElmList(obj,i), j)
            if haskey(recursion_dict,current_obj)
                new_array[ i, j ] = recursion_dict[current_obj]
            else
                new_array[ i, j ] = gap_to_julia(Union{Nothing,T},current_obj,recursion_dict)
                recursion_dict[current_obj] = new_array[ i, j ]
            end
        end
    end
    return new_array
end

## Tuples
function gap_to_julia( ::Type{T}, obj::MPtr, recursion_dict = IdDict() ) where T <: Tuple
    if ! Globals.IsList(obj)
        throw(ArgumentError("<obj> is not a list"))
    end
    list_translated = gap_to_julia(Array{Obj,1},obj)
    parameters = T.parameters
    list = Array{Any,1}(undef,length(parameters))
    for i in 1:length(parameters)
        list[i] = gap_to_julia(parameters[i],list_translated[i])
    end
    return T(list)
end

## Dictionaries
function gap_to_julia( ::Type{Dict{Symbol,T}}, obj :: MPtr, recursion_dict = IdDict() ) where T
    if ! Globals.IsRecord( obj )
        throw(ArgumentError("first argument is not a record"))
    end
    if haskey(recursion_dict,obj)
        return recursion_dict[obj]
    end
    names = Globals.RecNames( obj )
    names_list = gap_to_julia(Array{Symbol,1},names)
    dict = Dict{Symbol,T}()
    recursion_dict[obj] = dict
    for i in names_list
        current_obj = getproperty(obj,i)
        if haskey(recursion_dict,current_obj)
            dict[ i ] = recursion_dict[current_obj]
        else
            translated_obj = gap_to_julia(T,current_obj,recursion_dict)
            dict[ i ] = translated_obj
            recursion_dict[ current_obj ] = translated_obj
        end
    end
    return dict
end

## TODO: BitArray <-> blist; ranges; ...

## Generic conversions

gap_to_julia(x::Any)  = x

function gap_to_julia(x::MPtr)
    if Globals.IsInt(x)
        return gap_to_julia(BigInt,x)
    elseif Globals.IsRat(x)
        return gap_to_julia(Rational{BigInt},x)
    elseif Globals.IsFloat(x)
        return gap_to_julia(Float64,x)
    elseif Globals.IsChar(x)
        return gap_to_julia(Cuchar,x)
    elseif Globals.IsString(x)
        return gap_to_julia(AbstractString,x)
    elseif Globals.IsList(x)
        return gap_to_julia(Array{Union{Any,Nothing},1},x)
    elseif Globals.IsRecord(x)
        return gap_to_julia(Dict{Symbol,Any},x)
    end
    return x
end
