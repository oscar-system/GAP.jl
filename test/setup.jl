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

    # the script must run in the active project, not in its own directory
    outfile = joinpath(tmpdir, "active_project.txt")
    gap_sh_cmd = `$(joinpath(tmpdir, "gap.sh")) -A -b --quitonbreak --norepl -c "FileString(\"$(outfile)\", JuliaToGAP(IsString, Julia.Base.active_project()));"`
    run(pipeline(gap_sh_cmd; stdout=devnull))
    @test read(outfile, String) == Base.active_project()
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

@testset "gap_jll_is_overridden" begin
  # The prebuilt JuliaInterface.so must not be reused against a GAP_jll that
  # has been overridden with a custom GAP build.
  mktempdir() do tmpdir
    depot = joinpath(tmpdir, "depot")
    overrides_toml = joinpath(depot, "artifacts", "Overrides.toml")
    mkpath(dirname(overrides_toml))
    write(
      overrides_toml,
      """
      [$(Base.PkgId(GAP.GAP_jll).uuid)]
      GAP = "$(joinpath(tmpdir, "gap_override"))"
      """,
    )

    artifacts = GAP.Setup.Artifacts
    old_depot_path = copy(DEPOT_PATH)
    old_artifact_overrides = deepcopy(artifacts.ARTIFACT_OVERRIDES[])

    try
      empty!(DEPOT_PATH)
      push!(DEPOT_PATH, depot)
      artifacts.ARTIFACT_OVERRIDES[] = nothing
      @test GAP.Setup.gap_jll_is_overridden()

      # same depot, but without the override
      rm(overrides_toml)
      artifacts.ARTIFACT_OVERRIDES[] = nothing
      @test !GAP.Setup.gap_jll_is_overridden()
    finally
      empty!(DEPOT_PATH)
      append!(DEPOT_PATH, old_depot_path)
      artifacts.ARTIFACT_OVERRIDES[] = old_artifact_overrides
    end
  end
end

@testset "sysinfo follows a GAP_jll override" begin
  # GAP.sysinfo must be read when GAP.jl is loaded, not baked in when it is
  # precompiled -- an artifact override does not invalidate the package image.
  mktempdir() do tmpdir
    gapdir = joinpath(tmpdir, "gap")
    cp(GAP.GAP_jll.find_artifact_dir(), gapdir)
    chmod(gapdir, 0o755; recursive=true)

    open(joinpath(gapdir, "lib", "gap", "sysinfo.gap"), "a") do f
      println(f, "GAP_JL_OVERRIDE_MARKER=\"42\"")
    end

    depot = joinpath(tmpdir, "depot")
    mkpath(joinpath(depot, "artifacts"))
    write(
      joinpath(depot, "artifacts", "Overrides.toml"),
      """
      [$(Base.PkgId(GAP.GAP_jll).uuid)]
      GAP = "$(gapdir)"
      """,
    )

    # GAP writes to stdout while starting up, so report via a file
    outfile = joinpath(tmpdir, "marker.txt")
    code = """using GAP; write("$(outfile)", get(GAP.sysinfo, "GAP_JL_OVERRIDE_MARKER", "missing"))"""
    withenv(
      "JULIA_DEPOT_PATH" => join([depot; DEPOT_PATH], ":"),
      # the override forces a JuliaInterface rebuild; reuse ours instead
      "GAP_JL_JULIAINTERFACE_SO" => GAP.JuliaInterface_path,
    ) do
      run(pipeline(`$(Base.julia_cmd()) --startup-file=no --project=$(Base.active_project()) -e $(code)`; stdout=devnull))
    end
    @test read(outfile, String) == "42"
  end
end

@testset "gap package artifact overrides" begin
  mktempdir() do tmpdir
    override_dir = joinpath(tmpdir, "override", "alnuth")
    mkpath(override_dir)
    write(joinpath(override_dir, "PackageInfo.g"), "")

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
