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

using Documenter
using GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP, GAP.Random); recursive=true)

doctest(GAP; doctestfilters=GAP.GAP_doctestfilters)
