#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

using Libdl

import Base: length, convert

const MPtr = Main.ForeignGAP.MPtr


include( "ccalls.jl" )
include( "gap.jl" )
include( "gap_to_julia.jl" )
include( "julia_to_gap.jl" )
