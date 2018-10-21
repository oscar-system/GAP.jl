import Base: convert

const True = GAP.GAPFuncs.ReturnTrue()
const False = GAP.GAPFuncs.ReturnFalse()


function GAPFunctionPointer( name :: String )
    return GAP.GapFunc( ValGVar(name).ptr )
end

function Base.show( io::IO, obj::GAP.GapObj )
    str = GAP.String( obj )
    stri = LibGAP.from_gap_string( str )
    print(io,"GAP: $stri")
end
