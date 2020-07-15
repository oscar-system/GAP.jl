using Documenter, GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP); recursive = true)

makedocs(
    format = Documenter.HTML(),
    sitename = "GAP.jl",
    modules = [GAP],
    clean = true,
    doctest = true,
    doctestfilters = Regex[
      r"BitVector|BitArray\{1\}",
      r"Matrix\{Int64\}|Array\{Int64,2\}",
      r"Vector\{Any\}|Array\{Any,1\}",
      r"Vector\{Int64\}|Array\{Int64,1\}",
      r"Vector\{UInt8\}|Array\{UInt8,1\}",
    ],
    strict = false,
    checkdocs = :none,
    pages = ["index.md"],
)

# Compute the links to GAP manuals.
GAP.compute_links_to_gap_manuals(@__DIR__)

deploydocs(repo = "github.com/oscar-system/GAP.jl.git", target = "build")
