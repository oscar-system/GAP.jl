import Base: convert

const True = GAP.GAPFuncs.ReturnTrue()
const False = GAP.GAPFuncs.ReturnFalse()

to_gap(str :: String)         = StringObj_String(str)
to_gap(v :: Int32)            = IntObj_Int(v)
to_gap(v :: Int64)            = IntObj_Int(v)
to_gap(v :: GAP.GapObj)       = v

function to_gap( v :: Bool ) :: GAP.GapObj
    if v
        return True
    else
        return False
    end
end

function to_gap(v :: Array{GAP.GapObj, 1}) :: GAP.GapObj
    l = NewPList(length(v))
    SetLenPList(l, length(v))
    for i in 1:length(v)
        SetElmPList(l, i, v[i])
    end
    return l
end

convert(::Type{GAP.GapObj},m::Array{GAP.GapObj,1}) = to_gap(m)

function to_gap(v :: AbstractArray) :: Array{GAP.GapObj, 1}
    return map(to_gap, v)
end

function GAPFunctionPointer( name :: String )
    return GAP.GapFunc( ValGVar(name).ptr )
end

function Base.show( io::IO, obj::GAP.GapObj )
    str = GAP.String( obj )
    stri = LibGAP.from_gap_string( str )
    print(io,"GAP: $stri")
end
