using Test, Documenter, GAP

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP); recursive = true)

include("basics.jl")
include("adapter.jl")
include("convenience.jl")
include("conversion.jl")
include("constructors.jl")
include("convert.jl")
include("macros.jl")
include("packages.jl")
include("help.jl")
# include("testmanual.jl")  # skip this for now, difficult to get to work on all Julia versions
