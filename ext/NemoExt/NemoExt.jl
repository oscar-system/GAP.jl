#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

module NemoExt

using GAP
using Nemo

import GAP: GapObj, Wrappers

import Nemo:
  QQMatrix,
  QQFieldElem,
  ZZMatrix,
  ZZRingElem,
  characteristic,
  matrix

include("misc.jl")
include("gap_to_nemo.jl")
include("nemo_to_gap.jl")

end # module
