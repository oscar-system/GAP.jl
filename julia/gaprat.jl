###############################################################################
##
##  gaprat.jl
##
##  (copied from Nemo/src/flint/fmpq.jl, and adjusted ...)
##

module GAPRatModule

import Base: zero, -, one, inv, ==, isless, +, *, //, ^, mod, iszero

import GAP: GapObj

export GAPRat, get_gaprat_ptr

struct GAPRat
    obj::GapObj
end

function GAPRat(ptr::Ptr{Void})
    return GAPRat(GapObj(ptr))
end

function GAPRat(numerator::Int,denominator::Int)
    x = ccall(Main.gap_create_rational,Ptr{Void},(Cint,Cint),numerator,denominator)
    return GAPRat(x)
end

function get_gaprat_ptr(a::GAPRat)
    return a.obj.ptr
end

#T These are currently in julia/gaptypes.jl,
#T they should better be defined here, but then GAP crashes ...


##############################################################################
##
##  Julia arithmetic for GAPRats
##

function zero( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncZERO, Ptr{Void},
                (Ptr{Void},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function -( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncAINV, Ptr{Void},
                (Ptr{Void},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function one( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncONE, Ptr{Void},
                (Ptr{Void},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function inv( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncINV, Ptr{Void},
                (Ptr{Void},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function ==( a::GAPRat, b::GAPRat )
    return Bool( ccall( Main.gap_MyFuncEQ, Int,
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr ) )
end

function isless( a::GAPRat, b::GAPRat )
    return Bool( ccall( Main.gap_MyFuncLT, Int,
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr ) )
end

function +( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncSUM, Ptr{Void},
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function -( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncDIFF, Ptr{Void},
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function *( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncPROD, Ptr{Void},
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function //( a::GAPRat, b::GAPRat )
    iszero( b ) && throw( DivideError() )
    ptr = ccall( Main.gap_MyFuncQUO, Ptr{Void},
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function ^( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncPOW, Ptr{Void},
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function ^( a::GAPRat, b::Int )
# TODO: turn 'b' into a GAP integer object!
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Void}, (Int,), b )
    ptr = ccall( Main.gap_MyFuncPOW, Ptr{Void},
                (Ptr{Void}, Int), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end

function mod( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncMOD, Ptr{Void},
                (Ptr{Void}, Ptr{Void}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function iszero( a::GAPRat )
    return Bool( ccall( Main.gap_MyFuncZERO, Ptr{Void},
                (Ptr{Void},), a.obj.ptr ) == a.obj.ptr )
end


#T defined in Nemo
# function isone( a::GAPRat )
#     return GAPRat( ccall( Main.gap_MyFuncONE, Ptr{Void},(Ptr{Void},), a.obj.ptr ) == a
# end

#T defined in Nemo
#T isunit( a::GAPRat ) = ! iszero( a )


#T TODO:
#T - Once we can create GAPRat objects from Julia integers/rationals,
#T   install ``ad hoc methods'' for binary operations:
#T     function +( a::GAPRat, b::Int )
#T     function +( a::GAPRat, b::Rational{T} ) where {T <: Integer}
#T     function +( a::GAPRat, b::fmpq )  ?
#T     function +( a::GAPRat, b::fmpz )  ?
#T   and install conversion based on types:
#T     convert( ::Type{GAPRat}, a::Integer ) = GAPRat( a )
#T     convert( ::Type{GAPRat}, a::fmpz ) = GAPRat( a )
#T     Base.promote_rule(::Type{GAPRat}, ::Type{T}) where {T <: Integer} = GAPRat
#T     Base.promote_rule(::Type{GAPRat}, ::Type{Rational{T}}) where {T <: Integer} = GAPRat
#T - Support the conversion from GAPRat to Rational{BigInt}:
#T     function Rational( a::GAPRat ) ... end
#T     convert( ::Type{Rational{BigInt}}, a::GAPRat ) = Rational( a )
#T - Support more functions for GAP integers/rationals:
#T     function gcd( a::GAPRat, b::GAPRat ) ... end
#T     function abs( a::GAPRat ) ... end
#T     function numerator( a::GAPRat ) ... end
#T     function denominator( a::GAPRat ) ... end
#T     function <<( a::GAPRat, b::Int ) ... end
#T     function >>( a::GAPRat, b::Int ) ... end
#T     function Base.hash( a::GAPRat, h::UInt )
#T         return _hash_integer( numerator( a ),
#T                    _hash_integer( denominator( a ), h ) )
#T     end
#T     ...
#T - Does it make sense to support a 'show' method?
#T - If we want to put GAPRat objects into Nemo metrices
#T   then support also 'divexact' (add ad hoc methods)

end
