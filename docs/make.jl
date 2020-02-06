using Documenter, GAP

makedocs(
         format   = Documenter.HTML(),
         sitename = "GAP.jl",
         modules = [GAP],
         clean = true,
         doctest = true,
         strict = false,
         checkdocs = :none,
         pages    = [
             "index.md",
         ]
)

deploydocs(
   repo   = "github.com/oscar-system/GAP.jl.git",
   target = "build",
)
