import Base: convert, getindex, setindex!, length, show

const True = GAP.GAPFuncs.ReturnTrue()
const False = GAP.GAPFuncs.ReturnFalse()

const GAPInputType_noint = Union{MPtr,GAP.GapFFE}
const GAPInputType = Union{GAPInputType_noint,Int64}

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
Base.setindex!(x::MPtr, v::GAPInputType, i::Int64, j::Int64) = GAP.GAPFuncs.ASS_LIST(x, i, j, v)

# records
RNamObj(f::Symbol) = GAP.GAPFuncs.RNamObj(MakeString(string(f)))
Base.getproperty(x::MPtr, f::Symbol) = GAP.GAPFuncs.ELM_REC(x, RNamObj(f))
Base.setproperty!(x::MPtr, f::Symbol, v) = GAP.GAPFuncs.ASS_REC(x, RNamObj(f), v)


import Base: *, +, -, /, ^, mod, <, ==

typecombinations = [(:GAPInputType_noint,:GAPInputType_noint),
                    (:GAPInputType_noint,:Int64),
                    (:Int64,:GAPInputType_noint)]
function_combinations = [(:(+),:SUM),
                         (:(-),:DIFF),
                         (:(*),:PROD),
                         (:(/),:QUO),
                         (:(^),:POW),
                         (:(mod),:MOD),
                         (:(<),:LT),
                         (:(==),:EQ)]

for (t1,t2) in typecombinations
    for (f1,f2) in function_combinations
        @eval $f1(x::$t1,y::$t2) = GAP.GAPFuncs.$f2(x,y)
    end
end
