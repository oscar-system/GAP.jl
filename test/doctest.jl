using Documenter, GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP); recursive = true)

doctest(GAP; doctestfilters = Regex[
  r"BitVector|BitArray\{1\}",
  r"Matrix\{Int64\}|Array\{Int64,2\}",
  r"Vector\{Any\}|Array\{Any,1\}",
  r"Vector\{Int64\}|Array\{Int64,1\}",
  r"Vector\{UInt8\}|Array\{UInt8,1\}",
])
