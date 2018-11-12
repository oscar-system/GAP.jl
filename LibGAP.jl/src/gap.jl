import Base: convert, getindex, setindex!, length, show

const True = GAP.Globals.ReturnTrue()
const False = GAP.Globals.ReturnFalse()

const GAPInputType_noint = Union{MPtr,GAP.GapFFE}
const GAPInputType = Union{GAPInputType_noint,Int64}

function Base.show( io::IO, obj::Union{MPtr,GAP.GapFFE} )
    str = GAP.Globals.String( obj )
    stri = CSTR_STRING( str )
    print(io,"GAP: $stri")
end

function Base.string( obj::Union{MPtr,GAP.GapFFE} )
    str = GAP.Globals.String( obj )
    return CSTR_STRING( str )
end

## implement indexing interface
Base.getindex(x::MPtr, i::Int64) = GAP.Globals.ELM_LIST(x, i)
Base.setindex!(x::MPtr, v::GAPInputType, i::Int64 ) = GAP.Globals.ASS_LIST( x, i, v )
Base.length(x::MPtr) = GAP.Globals.Length(x)
Base.firstindex(x::MPtr) = 1
Base.lastindex(x::MPtr) = GAP.Globals.Length(x)

# matrix
Base.getindex(x::MPtr, i::Int64, j::Int64) = GAP.Globals.ELM_LIST(x, i, j)
Base.setindex!(x::MPtr, v::GAPInputType, i::Int64, j::Int64) = GAP.Globals.ASS_LIST(x, i, j, v)

# records
RNamObj(f::Symbol) = GAP.Globals.RNamObj(MakeString(string(f)))
Base.getproperty(x::MPtr, f::Symbol) = GAP.Globals.ELM_REC(x, RNamObj(f))
Base.setproperty!(x::MPtr, f::Symbol, v) = GAP.Globals.ASS_REC(x, RNamObj(f), v)

#
Base.zero(x::GAPInputType_noint) = GAP.Globals.ZERO(x)
Base.one(x::GAPInputType_noint) = GAP.Globals.ONE(x)
Base.:-(x::GAPInputType_noint) = GAP.Globals.AINV(x)

#
typecombinations = ((:GAPInputType_noint,:GAPInputType_noint),
                    (:GAPInputType_noint,:Int64),
                    (:Int64,:GAPInputType_noint))
function_combinations = ((:+,:SUM),
                         (:-,:DIFF),
                         (:*,:PROD),
                         (:/,:QUO),
                         (:\,:LQUO),
                         (:^,:POW),
                         (:mod,:MOD),
                         (:<,:LT),
                         (:(==),:EQ))

for (left, right) in typecombinations
    for (funcJ, funcC) in function_combinations
        @eval begin
            Base.$(funcJ)(x::$left,y::$right) = GAP.Globals.$(funcC)(x,y)
        end
    end
end
