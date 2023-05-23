using Documenter
using GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP, GAP.Random); recursive=true)

doctest(GAP; doctestfilters=GAP.GAP_doctestfilters)
