#
# This is a very hacky prototype calling libgap from julia
#
# It is intended to be a low level interface to the C functions
# the higher level API can be found in gap.jl
#

module LibGAP

using Libdl

import Main.GAP

import Base: length, convert

# export EvalString, IntObj_Int, Int_IntObj,
#        CallFuncList, ValGVar, String_StringObj, StringObj_String,
#        NewPList, SetElmPList, SetLenPList, ElmPList, LenPList


using Main.ForeignGAP: MPtr

include( "ccalls.jl" )
include( "gap.jl" )
# include( "conversion.jl" )

end
