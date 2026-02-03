#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

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
include("rand.jl")

if Base.JLOptions().code_coverage == 0
  # REPL completion doesn't work in Julia >= 1.10 when code coverage
  # tracking is active. For more details see the discussions at
  # <https://github.com/oscar-system/GAP.jl/pull/914> and
  # <https://github.com/JuliaLang/julia/issues/49978>.
  include("replcompletions.jl")
else
  # If Julia tracks coverage, then let GAP also track coverage
  @show covdir = abspath(@__DIR__, "..", "coverage")
  Base.mkpath(covdir)
  covfile = GapObj(joinpath(covdir, "GAP.jl.coverage"))
  # HACK: workaround bug in CoverageLineByLine, see
  # <https://github.com/gap-system/gap/pull/6218>
  #GAP.Globals.CoverageLineByLine(covfile)
  GAP.Globals.ProfileLineByLine(covfile, GapObj(Dict(:coverage=>true, :recordMem=>true)))
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

using Nemo

include("NemoExt/misc.jl")
include("NemoExt/gap_to_nemo.jl")
include("NemoExt/nemo_to_gap.jl")

if Base.JLOptions().code_coverage != 0
  GAP.Globals.UncoverageLineByLine()
end
