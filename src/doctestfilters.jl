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

# Regular expressions that `docs/make.jl` and `test/doctest.jl` apply to both
# the expected and the actual output of `jldoctest` blocks before comparing
# them; matching text is removed on both sides. Use this when some supported
# Julia version prints a type occurring in the examples differently.
GAP_doctestfilters = Regex[]

GAP_docs_pages = [
        "index.md",
        "basics.md",
        "conversion.md",
        "packages.md",
        "other.md",
        "examples.md",
        "internal.md",
        "manualindex.md",
        ]
