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

@testset "create_gap_sh" begin
  mktempdir() do tmpdir
    GAP.create_gap_sh(tmpdir; use_active_project=true)
    gap_sh = read(joinpath(tmpdir, "gap.sh"), String)

    if Base.JLOptions().code_coverage != 0
      @test occursin("--code-coverage", gap_sh)
    else
      @test !occursin("--code-coverage", gap_sh)
    end
  end

  mktempdir() do tmpdir
    GAP.create_gap_sh(tmpdir; use_active_project=true, code_coverage="user")
    gap_sh = read(joinpath(tmpdir, "gap.sh"), String)
    @test occursin("--code-coverage=user", gap_sh)
  end

  mktempdir() do tmpdir
    GAP.create_gap_sh(tmpdir; use_active_project=true, code_coverage="none")
    gap_sh = read(joinpath(tmpdir, "gap.sh"), String)
    @test occursin("--code-coverage=none", gap_sh)
  end
end

@testset "locate_JuliaInterface_so" begin
  mktempdir() do tmpdir
    override = joinpath(tmpdir, "JuliaInterface.so")
    write(override, "")
    withenv("GAP_JL_JULIAINTERFACE_SO" => override) do
      @test GAP.Setup.locate_JuliaInterface_so() == override
    end
  end
end
