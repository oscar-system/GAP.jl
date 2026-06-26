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

@testset "gap package artifact overrides" begin
  mktempdir() do tmpdir
    artifacts_toml = joinpath(tmpdir, "Artifacts.toml")
    override_dir = joinpath(tmpdir, "override", "alnuth")
    mkpath(override_dir)
    write(joinpath(override_dir, "PackageInfo.g"), "")
    write(
      artifacts_toml,
      """
      [GAP_pkg_alnuth]
      git-tree-sha1 = "809593e819b916279aa515bc8644a9c1e5ab2a96"
      """,
    )

    depot = joinpath(tmpdir, "depot")
    overrides_toml = joinpath(depot, "artifacts", "Overrides.toml")
    mkpath(dirname(overrides_toml))
    write(
      overrides_toml,
      """
      [c863536a-3901-11e9-33e7-d5cd0df7b904]
      GAP_pkg_alnuth = "$(override_dir)"
      """,
    )

    old_depot_path = copy(DEPOT_PATH)
    artifact_stdlib = Base.require(
      Base.PkgId(
        Base.UUID("56f22d72-fd6d-98f1-02f0-08ddc0907c33"),
        "Artifacts",
      ),
    )
    old_artifact_overrides = deepcopy(artifact_stdlib.ARTIFACT_OVERRIDES[])

    try
      empty!(DEPOT_PATH)
      push!(DEPOT_PATH, depot)
      artifact_stdlib.ARTIFACT_OVERRIDES[] = nothing

      @test GAP.gap_pkg_artifact_dir("alnuth") == override_dir
    finally
      empty!(DEPOT_PATH)
      append!(DEPOT_PATH, old_depot_path)
      artifact_stdlib.ARTIFACT_OVERRIDES[] = old_artifact_overrides
    end
  end
end
