using Test, Documenter, GAP

include("basics.jl")
include("adapter.jl")
include("convenience.jl")
include("conversion.jl")
include("constructors.jl")
include("macros.jl")
include("packages.jl")
include("help.jl")
include("replcompletions.jl")

@testset "manual examples" begin
  include("doctest.jl")
end
