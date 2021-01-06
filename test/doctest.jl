using Documenter, GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP); recursive = true)

doctest(GAP; doctestfilters = GAP.GAP_doctestfilters)
