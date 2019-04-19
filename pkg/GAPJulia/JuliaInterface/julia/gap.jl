import Base: convert, getindex, setindex!, length, show

const True = Globals.ReturnTrue()
const False = Globals.ReturnFalse()

const GAPInputType_internal = Union{MPtr,FFE}
const GAPInputType = Union{GAPInputType_internal,Int64,Bool}

const Obj = Union{GAPInputType,Nothing}

function Base.show( io::IO, obj::Union{MPtr,FFE} )
    str = Globals.String( obj )
    stri = CSTR_STRING( str )
    print(io,"GAP: $stri")
end

function Base.string( obj::Union{MPtr,FFE} )
    str = Globals.String( obj )
    return CSTR_STRING( str )
end

## implement indexing interface
Base.getindex(x::MPtr, i::Int64) = Globals.ELM_LIST(x, i)
Base.setindex!(x::MPtr, v::Any, i::Int64 ) = Globals.ASS_LIST( x, i, v )
Base.length(x::MPtr) = Globals.Length(x)
Base.firstindex(x::MPtr) = 1
Base.lastindex(x::MPtr) = Globals.Length(x)

# matrix
Base.getindex(x::MPtr, i::Int64, j::Int64) = Globals.ELM_LIST(x, i, j)
Base.setindex!(x::MPtr, v::Any, i::Int64, j::Int64) = Globals.ASS_LIST(x, i, j, v)

# records
RNamObj(f::Union{Symbol,Int64,AbstractString}) = Globals.RNamObj(MakeString(string(f)))
# note: we don't use Union{Symbol,Int64,AbstractString} below to avoid
# ambiguity between these methods and method `getproperty(x, f::Symbol)`
# from Julia's Base module
Base.getproperty(x::MPtr, f::Symbol) = Globals.ELM_REC(x, RNamObj(f))
Base.getproperty(x::MPtr, f::Union{AbstractString,Int64}) = Globals.ELM_REC(x, RNamObj(f))
Base.setproperty!(x::MPtr, f::Symbol, v) = Globals.ASS_REC(x, RNamObj(f), v)
Base.setproperty!(x::MPtr, f::Union{AbstractString,Int64}, v) = Globals.ASS_REC(x, RNamObj(f), v)

#
Base.zero(x::GAPInputType_internal) = Globals.ZERO(x)
Base.one(x::GAPInputType_internal) = Globals.ONE(x)
Base.:-(x::GAPInputType_internal) = Globals.AINV(x)

#
typecombinations = ((:GAPInputType_internal,:GAPInputType_internal),
                    (:GAPInputType_internal,:Int64),
                    (:Int64,:GAPInputType_internal),
                    (:GAPInputType_internal,:Bool),
                    (:Bool,:GAPInputType_internal))
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


"""
    @gap <obj>
    @gap(<obj>)

Executes <obj> directly in GAP, as if `GAP.EvalString("<obj>")` was called.
Can be used for creating GAP literals directly from Julia.

    julia> @gap (1,2,3)
    GAP: (1,2,3)
    julia> @gap SymmetricGroup(3)
    GAP: SymmetricGroup( [ 1 .. 3 ] )
    julia> @gap(SymmetricGroup)(3)
    GAP: SymmetricGroup( [ 1 .. 3 ] )

Note that the last two examples have a slight syntactical, and therefore also
a semantical difference. The first one executes the string `SymmetricGroup(3)`
directly inside GAP. The second example returns the function `SymmetricGroup`
via `@gap(SymmetricGroup)`, then calls that function with the argument `3`.
"""
macro gap(str)
    return EvalString(string(str))
end

export @gap
