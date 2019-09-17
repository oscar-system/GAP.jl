## Basic list / matrix / "record" access as well as arithmetics,
## for GAP objects in Julia

import Base: getindex, setindex!, length, show

function Base.show( io::IO, obj::Union{GapObj,FFE} )
    str = Globals.StringView( obj )
    stri = CSTR_STRING( str )
    print(io,"GAP: $stri")
end

function Base.string( obj::Union{GapObj,FFE} )
    str = Globals.String( obj )
    return CSTR_STRING( str )
end

## implement indexing interface
Base.getindex(x::GapObj, i::Int64) = Globals.ELM_LIST(x, i)
Base.setindex!(x::GapObj, v::Any, i::Int64 ) = Globals.ASS_LIST( x, i, v )
Base.length(x::GapObj) = Globals.Length(x)
Base.firstindex(x::GapObj) = 1
Base.lastindex(x::GapObj) = Globals.Length(x)

# matrix
Base.getindex(x::GapObj, i::Int64, j::Int64) = Globals.ELM_LIST(x, i, j)
Base.setindex!(x::GapObj, v::Any, i::Int64, j::Int64) = Globals.ASS_LIST(x, i, j, v)

# records
RNamObj(f::Union{Symbol,Int64,AbstractString}) = Globals.RNamObj(MakeString(string(f)))
# note: we don't use Union{Symbol,Int64,AbstractString} below to avoid
# ambiguity between these methods and method `getproperty(x, f::Symbol)`
# from Julia's Base module
Base.getproperty(x::GapObj, f::Symbol) = Globals.ELM_REC(x, RNamObj(f))
Base.getproperty(x::GapObj, f::Union{AbstractString,Int64}) = Globals.ELM_REC(x, RNamObj(f))
Base.setproperty!(x::GapObj, f::Symbol, v) = Globals.ASS_REC(x, RNamObj(f), v)
Base.setproperty!(x::GapObj, f::Union{AbstractString,Int64}, v) = Globals.ASS_REC(x, RNamObj(f), v)

#
Base.zero(x::Union{GapObj,FFE}) = Globals.ZERO(x)
Base.one(x::Union{GapObj,FFE}) = Globals.ONE(x)
Base.:-(x::Union{GapObj,FFE}) = Globals.AINV(x)

#
typecombinations = ((:GapObj,:GapObj),
                    (:FFE,:FFE),
                    (:GapObj,:FFE),
                    (:FFE,:GapObj),
                    (:GapObj,:Int64),
                    (:Int64,:GapObj),
                    (:FFE,:Int64),
                    (:Int64,:FFE),
                    (:GapObj,:Bool),
                    (:Bool,:GapObj),
                    (:FFE,:Bool),
                    (:Bool,:FFE))
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
            Base.$(funcJ)(x::$left,y::$right) = Globals.$(funcC)(x,y)
        end
    end
end
