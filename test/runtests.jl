using Test, Documenter, GAP

DocMeta.setdocmeta!( GAP, :DocTestSetup, :( using GAP ); recursive = true )

include("basics.jl")
include("convenience.jl")
include("conversion.jl")
include("constructors.jl")
include("macros.jl")
include("packages.jl")
include("help.jl")
include("testmanual.jl")
