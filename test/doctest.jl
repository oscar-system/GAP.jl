using Documenter, GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP, Random); recursive = true)

doctest(GAP; doctestfilters = GAP.GAP_doctestfilters)
