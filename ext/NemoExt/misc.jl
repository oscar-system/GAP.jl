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

# TODO: the following could be made faster for GAP.FFE by extracting the
# characteristic directly from the GAP FFE
characteristic(x::GAP.FFE) = ZZRingElem(Wrappers.CHAR_FFE_DEFAULT(x))
characteristic(x::GapObj) = ZZRingElem(Wrappers.Characteristic(x))
