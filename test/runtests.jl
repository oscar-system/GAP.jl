using Test
using Documenter
using GAP

include("Aqua.jl")

include("basics.jl")
include("adapter.jl")
include("convenience.jl")
include("conversion.jl")
include("constructors.jl")
include("macros.jl")
include("packages.jl")
include("help.jl")

@static if VERSION < v"1.10-DEV"
  # TODO: re-enable this test in Julia 1.10 once we get REPL completion
  # working there
  include("replcompletions.jl")
end

@testset "manual examples" begin
  include("doctest.jl")
end
