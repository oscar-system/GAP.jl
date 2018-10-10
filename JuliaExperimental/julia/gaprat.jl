###############################################################################
##
##  gaprat.jl
##
##  (copied from Nemo/src/flint/fmpq.jl, and adjusted ...)
##

module GAPRatModule

import Base: zero, -, one, inv, ==, isless, +, *, //, ^, mod, iszero, string,
             numerator, denominator, abs, gcd

import GAP: GapObj, SUM

export GAPRat, get_gaprat_ptr

struct GAPRat
    obj::GapObj
end

function GAPRat(ptr::Ptr{Cvoid})
    return GAPRat(GapObj(ptr))
end

function GAPRat(numerator::Int,denominator::Int)
    x = ccall(Main.gap_create_rational,Ptr{Cvoid},(Cint,Cint),numerator,denominator)
    return GAPRat(x)
end

function get_gaprat_ptr(a::GAPRat)
    return a.obj.ptr
end
#T shall this be used everywhere instead of accessing .obj.ptr?


##############################################################################
##
##  Julia arithmetic for GAPRats
##

function zero( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncZERO, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function -( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncAINV, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function one( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncONE, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function inv( a::GAPRat )
    ptr = ccall( Main.gap_MyFuncINV, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function ==( a::GAPRat, b::GAPRat )
    return Bool( ccall( Main.gap_MyFuncEQ, Int,
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr ) )
end

function isless( a::GAPRat, b::GAPRat )
    return Bool( ccall( Main.gap_MyFuncLT, Int,
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr ) )
end

function +( a::GAPRat, b::GAPRat )
  # ptr = ccall( Main.gap_MyFuncSUM, Ptr{Cvoid},
  #             (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr )
  # return GAPRat( GapObj(ptr) )
    return GAPRat( SUM( a.obj, b.obj ) )
end

function -( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncDIFF, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function *( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncPROD, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function //( a::GAPRat, b::GAPRat )
    iszero( b ) && throw( DivideError() )
    ptr = ccall( Main.gap_MyFuncQUO, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function ^( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncPOW, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function ^( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    ptr = ccall( Main.gap_MyFuncPOW, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end

function mod( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_MyFuncMOD, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function iszero( a::GAPRat )
    return Bool( ccall( Main.gap_MyFuncZERO, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr ) == a.obj.ptr )
end


#T defined in Nemo, can we assume that Nemo is loaded? (then add 'using'?)
# function isone( a::GAPRat )
#     return GAPRat( ccall( Main.gap_MyFuncONE, Ptr{Cvoid},(Ptr{Cvoid},), a.obj.ptr ) == a
# end

#T defined in Nemo
#T isunit( a::GAPRat ) = ! iszero( a )


##############################################################################
##
##  ad hoc methods for arithmetic operations with GAPRats and Julia rationals
##

function ==( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    return Bool( ccall( Main.gap_MyFuncEQ, Int,
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, int_ptr ) )
end

function ==( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    return Bool( ccall( Main.gap_MyFuncEQ, Int,
                (Ptr{Cvoid}, Ptr{Cvoid}), int_ptr, b.obj.ptr ) )
end

function ==( a::GAPRat, b::Rational{T} ) where {T <: Integer}
    return a == GAPRat( numerator(b), denominator(b) )
end

function ==( a::Rational{T}, b::GAPRat ) where {T <: Integer}
    return GAPRat( numerator(a), denominator(a) ) == b
end


function isless( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    return Bool( ccall( Main.gap_MyFuncLT, Int,
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, int_ptr ) )
end

function isless( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    return Bool( ccall( Main.gap_MyFuncLT, Int,
                (Ptr{Cvoid}, Ptr{Cvoid}), int_ptr, a.obj.ptr ) )
end

function isless( a::GAPRat, b::Rational{T} ) where {T <: Integer}
    return isless( a, GAPRat( numerator(b), denominator(b) ) )
end

function isless( a::Rational{T}, b::GAPRat ) where {T <: Integer}
    return isless( GAPRat( numerator(a), denominator(a) ), b )
end


function +( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    ptr = ccall( Main.gap_MyFuncSUM, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end

function +( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    ptr = ccall( Main.gap_MyFuncSUM, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), int_ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function +( a::GAPRat, b::Rational{T} ) where {T <: Integer}
    return a + GAPRat( numerator(b), denominator(b) )
end

function +( a::Rational{T}, b::GAPRat ) where {T <: Integer}
    return GAPRat( numerator(a), denominator(a) ) + b
end


function -( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    ptr = ccall( Main.gap_MyFuncDIFF, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end

function -( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    ptr = ccall( Main.gap_MyFuncDIFF, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), int_ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function -( a::GAPRat, b::Rational{T} ) where {T <: Integer}
    return a - GAPRat( numerator(b), denominator(b) )
end

function -( a::Rational{T}, b::GAPRat ) where {T <: Integer}
    return GAPRat( numerator(a), denominator(a) ) - b
end


function *( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    ptr = ccall( Main.gap_MyFuncPROD, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end

function *( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    ptr = ccall( Main.gap_MyFuncPROD, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), int_ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function *( a::GAPRat, b::Rational{T} ) where {T <: Integer}
    return a * GAPRat( numerator(b), denominator(b) )
end

function *( a::Rational{T}, b::GAPRat ) where {T <: Integer}
    return GAPRat( numerator(a), denominator(a) ) * b
end


function //( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    ptr = ccall( Main.gap_MyFuncQUO, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end 

function //( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    ptr = ccall( Main.gap_MyFuncQUO, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), int_ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end    

function //( a::GAPRat, b::Rational{T} ) where {T <: Integer}
    return a // GAPRat( numerator(b), denominator(b) )
end

function //( a::Rational{T}, b::GAPRat ) where {T <: Integer}
    return GAPRat( numerator(a), denominator(a) ) // b
end


function mod( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    ptr = ccall( Main.gap_MyFuncMOD, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end

function mod( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    ptr = ccall( Main.gap_MyFuncMOD, Ptr{Cvoid},
                (Ptr{Cvoid}, Int), int_ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

#T why does the following cause a LoadError?
# (GAP provides this kind of 'mod')
# function mod( a::GAPRat, b::Rational{T} ) where {T <: Integer}
#     return a mod GAPRat( numerator(b), denominator(b) )
# end
# 
# function mod( a::Rational{T}, b::GAPRat ) where {T <: Integer}
#     return GAPRat( numerator(a), denominator(a) ) mod b
# end



#T     function +( a::GAPRat, b::fmpq )  ?
#T     function +( a::GAPRat, b::fmpz )  ?

#T   and install conversion based on types:
#T     convert( ::Type{GAPRat}, a::Integer ) = GAPRat( a, 1 )
#T     convert( ::Type{GAPRat}, a::fmpz ) = GAPRat( a )
#T     Base.promote_rule(::Type{GAPRat}, ::Type{T}) where {T <: Integer} = GAPRat
#T     Base.promote_rule(::Type{GAPRat}, ::Type{Rational{T}}) where {T <: Integer} = GAPRat

#T - Support the conversion from GAPRat to Rational{BigInt}:
#T     function Rational( a::GAPRat ) ... end
#T     convert( ::Type{Rational{BigInt}}, a::GAPRat ) = Rational( a )


##############################################################################
##
##  some functions for GAP rationals:
##

function numerator( a::GAPRat )
    ptr = ccall( Main.gap_NUM_RAT, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function denominator( a::GAPRat )
    ptr = ccall( Main.gap_DEN_RAT, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

#T This works only for GAP integers, GAP has no C function for GAP rationals?
function abs( a::GAPRat )
    ptr = ccall( Main.gap_AbsInt, Ptr{Cvoid},
                (Ptr{Cvoid},), a.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function gcd( a::GAPRat, b::GAPRat )
    ptr = ccall( Main.gap_GcdInt, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, b.obj.ptr )
    return GAPRat( GapObj(ptr) )
end

function gcd( a::GAPRat, b::Int )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), b )
    ptr = ccall( Main.gap_GcdInt, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), a.obj.ptr, int_ptr )
    return GAPRat( GapObj(ptr) )
end

function gcd( a::Int, b::GAPRat )
    int_ptr = ccall( Main.gap_INTOBJ_INT, Ptr{Cvoid}, (Int,), a )
    return ccall( Main.gap_GcdInt, Ptr{Cvoid},
                (Ptr{Cvoid}, Ptr{Cvoid}), int_ptr, b.obj.ptr )
end

#T     function <<( a::GAPRat, b::Int ) ... end
#T     function >>( a::GAPRat, b::Int ) ... end

function Base.hash( a::GAPRat, h::UInt )
    return _hash_integer( numerator( a ),
                          _hash_integer( denominator( a ), h ) )
end

#T - Does it make sense to support a 'show' method?

#T how to create a Julia string from the GAPRat?
function string( a::GAPRat )
   return "<a GAPRat object>"
end

#T - If we want to put GAPRat objects into Nemo matrices (?)
#T   then support also 'divexact' (add ad hoc methods)

end

