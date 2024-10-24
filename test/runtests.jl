using Test
using Documenter
using GAP
using IOCapture

include("Aqua.jl")

include("basics.jl")
include("adapter.jl")
include("convenience.jl")
include("conversion.jl")
include("constructors.jl")
include("macros.jl")
include("packages.jl")
include("help.jl")

@static if VERSION < v"1.10-DEV" || Base.JLOptions().code_coverage == 0
  # REPL completion doesn't work in Julia >= 1.10 when code coverage
  # tracking is active. For more details see the discussions at
  # <https://github.com/oscar-system/GAP.jl/pull/914> and
  # <https://github.com/JuliaLang/julia/issues/49978>.
  include("replcompletions.jl")
end

@testset "manual examples" begin
  include("doctest.jl")
end

@testset "JuliaInterface tests" begin
  mktempdir() do tmpdir
    GAP.create_gap_sh(tmpdir)
    cmd = Cmd(`$(joinpath("etc", "ci_test.sh"))`; dir=dirname(dirname(pathof(GAP))))
    cmd = addenv(cmd, "GAP" => "$(joinpath(tmpdir, "gap.sh")) -A --quitonbreak --norepl")
    @test success(pipeline(cmd; stdout, stderr))
  end
end
