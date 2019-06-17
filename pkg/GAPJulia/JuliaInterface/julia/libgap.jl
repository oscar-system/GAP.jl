#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

using Libdl

import Base: length, convert

const MPtr = Main.ForeignGAP.MPtr

const Obj = Union{MPtr,FFE,Int64,Bool,Nothing}


include( "ccalls.jl" )
include( "gap.jl" )
include( "macros.jl" )
include( "gap_to_julia.jl" )
include( "julia_to_gap.jl" )
