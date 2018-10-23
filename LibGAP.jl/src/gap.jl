import Base: convert, getindex, setindex!, length, show

const True = GAP.GAPFuncs.ReturnTrue()
const False = GAP.GAPFuncs.ReturnFalse()

const GAPInputType = Union{MPtr,Int64}

function GAPFunctionPointer( name :: String )
    return GAP.GapFunc( ValueGlobalVariable(name).ptr )
end

function Base.show( io::IO, obj::MPtr )
    str = GAP.GAPFuncs.String( obj )
    stri = CSTR_STRING( str )
    print(io,"GAP: $stri")
end

function Base.string( obj::MPtr )
    str = GAP.String( obj )
    return CSTR_STRING( str )
end

## List funcs
Base.getindex(x::MPtr, i::Int64) = GAP.GAPFuncs.ELM_LIST(x, i)
Base.setindex!(x::MPtr, i::Int64, v::GAPInputType ) = GAP.GAPFuncs.ASS_LIST( x, i, v )
Base.length(x::MPtr) = GAP.GAPFuncs.length(x)

# matrix
Base.getindex(x::MPtr, i::Int64, j::Int64) = GAP.GAPFuncs.ELM_LIST(x, i, j)
Base.setindex!(x::MPtr, v::GAPInputType, i::Int64, j::Int64) = GAP.GAPFuncs.ASS_LIST(x, to_gap(i), to_gap(j), to_gap(v))

# records
RNamObj(f::Symbol) = GAP.GAPFuncs.RNamObj(MakeString(string(f)))
Base.getproperty(x::MPtr, f::Symbol) = GAP.GAPFuncs.ELM_REC(x, RNamObj(f))
Base.setproperty!(x::MPtr, f::Symbol, v) = GAP.GAPFuncs.ASS_REC(x, RNamObj(f), to_gap(v))
