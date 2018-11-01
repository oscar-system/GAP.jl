import Base: convert, getindex, setindex!, length, show

const True = GAP.GAPFuncs.ReturnTrue()
const False = GAP.GAPFuncs.ReturnFalse()

const GAPInputType = Union{MPtr,Int64,GAP.GapFFE}

function GAPFunctionPointer( name :: String )
    return GAP.GapFunc( ValueGlobalVariable(name).ptr )
end

function Base.show( io::IO, obj::Union{MPtr,GAP.GapFFE} )
    str = GAP.GAPFuncs.String( obj )
    stri = CSTR_STRING( str )
    print(io,"GAP: $stri")
end

function Base.string( obj::Union{MPtr,GAP.GapFFE} )
    str = GAP.String( obj )
    return CSTR_STRING( str )
end

## List funcs
Base.getindex(x::MPtr, i::Int64) = GAP.GAPFuncs.ELM_LIST(x, i)
Base.setindex!(x::MPtr, i::Int64, v::GAPInputType ) = GAP.GAPFuncs.ASS_LIST( x, i, v )
Base.length(x::MPtr) = GAP.GAPFuncs.Length(x)

# matrix
Base.getindex(x::MPtr, i::Int64, j::Int64) = GAP.GAPFuncs.ELM_LIST(x, i, j)
Base.setindex!(x::MPtr, v::GAPInputType, i::Int64, j::Int64) = GAP.GAPFuncs.ASS_LIST(x, i, j, to_gap(v))

# records
RNamObj(f::Symbol) = GAP.GAPFuncs.RNamObj(MakeString(string(f)))
Base.getproperty(x::MPtr, f::Symbol) = GAP.GAPFuncs.ELM_REC(x, RNamObj(f))
Base.setproperty!(x::MPtr, f::Symbol, v) = GAP.GAPFuncs.ASS_REC(x, RNamObj(f), to_gap(v))


import Base: *, +, -, /, ^, mod, <, ==

#
+(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.SUM(x, y)
-(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.DIFF(x, y)
*(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.PROD(x, y)
/(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.QUO(x, y)
^(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.POW(x, y)
mod(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.MOD(x, y)

<(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.LT(x, y)
==(x::GAPInputType, y::GAPInputType) = GAP.GAPFuncs.EQ(x, y)


# TODO: do benchmarks to compare this with ccall:
#+(x::GAP.MPtr, y::GAP.MPtr) = ccall( :MyFuncSUM, GAP.MPtr, (GAP.MPtr, GAP.MPtr), x, y )
