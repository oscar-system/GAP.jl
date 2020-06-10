using Documenter, GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP); recursive = true)

makedocs(
    format = Documenter.HTML(),
    sitename = "GAP.jl",
    modules = [GAP],
    clean = true,
    doctest = true,
    strict = false,
    checkdocs = :none,
    pages = ["index.md"],
)

# Compute the links to GAP manuals.
GAP.compute_links_to_GAP_manuals(@__DIR__)

deploydocs(repo = "github.com/oscar-system/GAP.jl.git", target = "build")
