# Directions for updating GAP.jl

`GAP.jl` depends on the GAP kernel, the GAP library,
and some glue code in the `JuliaInterface` GAP package,
which is located in the `pkg/JuliaInterface/` directory.
Additionally, there are various GAP packages that either
depend on a GAP kernel extension, or some binary that
is not part of GAP.

Compiled versions of each are distributed to users
as binary artifacts via the Julia "JLL" packages `GAP_jll`,
`GAP_lib_jll`, `GAP_pkg_juliainterface_jll`, and
various `GAP_pkg_*_jll` packages (where `*` stands for
the name of the GAP package written in all lowercase).

The build recipes for these JLL packages can be found here:

- <https://github.com/JuliaPackaging/Yggdrasil/blob/master/G/GAP/build_tarballs.jl>
- <https://github.com/JuliaPackaging/Yggdrasil/blob/master/G/GAP_lib/build_tarballs.jl>
- <https://github.com/JuliaPackaging/Yggdrasil/blob/master/G/GAP_pkg/GAP_pkg_juliainterface/build_tarballs.jl>
- <https://github.com/JuliaPackaging/Yggdrasil/tree/master/G/GAP_pkg>

## Updating the glue code in `juliainterface`

Suppose just the code in `juliainterface` was updated, without any changes to GAP itself.
Then `GAP_pkg_juliainterface_jll` needs to be rebuilt before the next GAP.jl release.
One can detect that such a rebuild is necessary when the CI job `treehash` in the GAP.jl
repository fails in a PR.

1. Merge that PR.

2. After the changes are merged (and before the next `GAP.jl` release), update
   the `GAP_pkg_juliainterface` build recipe with a new version number and using the
   latest commit SHA for the `master` branch of `GAP.jl`.
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/11582>

3. Wait for this to be merged into Yggdrasil, and then wait for the registry
   to pick up the new version of `GAP_pkg_juliainterface_jll`.
   > ex: <https://github.com/JuliaRegistries/General/pull/134045>

4. Bump the dependence in `GAP.jl` to whatever version number was used in Step 2.
   In this PR, the `treehash` CI job should succeed.
   > ex: <https://github.com/oscar-system/GAP.jl/pull/1200>

5. (Optional) Release a new `GAP.jl`. This is done by pinging JuliaRegistrator in the comments of a commit.
   > ex: <https://github.com/oscar-system/GAP.jl/commit/21d5dd6b4ff8457649a922f0d5ba4a4414502f27#commitcomment-161267536>


## Build against a new `libjulia` version

This needs to be done regularly, or as soon as some weird crashes start
happening on a new julia release or on julia nightly.

1. Wait for someone to update `libjulia_jll` to a new version.

2. Update the GAP build recipe by changing the `libjulia_jll` version number to the new one.
   There is no need to change any other version number in the recipe.
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/11656>

3. Wait for the Yggdrasil merge, and wait for the registry.
   > ex: <https://github.com/JuliaRegistries/General/pull/134713>

4. Update the `GAP_pkg_juliainterface` build recipe by changing the `libjulia_jll` version number to the new one.
   There is no need to change any other version number in the recipe.
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/11659>

5. Wait for the Yggdrasil merge, and wait for the registry.
   > ex: <https://github.com/JuliaRegistries/General/pull/134734>


## Updating GAP

After a new GAP version is released, the following steps are necessary to update
all of the JLL packages that depend on GAP.

1. Update the GAP build recipe with the new `upstream_version` and SHA256 of the release tarball.
   Furthermore, update the `version`; usually this is the `upstream_version` component-wise
   multiplied by 100.
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/12345>

2. Wait for the Yggdrasil merge, and wait for the registry.
   > ex: <https://github.com/JuliaRegistries/General/pull/140789>

3. Update the GAP_lib build recipe with the new `upstream_version` and SHA256 of the release tarball.
   Furthermore, update the `version`; usually this is the `upstream_version` component-wise
   multiplied by 100.
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/12346>

4. Wait for the Yggdrasil merge, and wait for the registry.
   > ex: <https://github.com/JuliaRegistries/General/pull/140790>

5. In Yggdrasil in the file `G/GAP_pkg/update.jl`, update the following variables:
   - `upstream_version` to the new GAP version.
   - `gap_version` to the `version` from step 1. If the GAP release is ABI-compatible
     with the previous one, then this can remain unchanged.
   - `gap_lib_version` to the `version` from step 3. If the GAP release is ABI-compatible
     with the previous one, then this can remain unchanged.
   - juliainterface `upstream_version` to the version that the next release of `GAP.jl` (that contains
     the new GAP version) will have.
   Create a PR for this change.
   *Important:* Each commit message in this PR should contain `[skip build]`, while the PR description
   and merge commit message should instead contain `[skip ci]`. This avoids triggering unnecessary builds.

6. Run the `G/GAP_pkg/update.jl` script locally (see the top of that file for instructions).
   For each `GAP_pkg_*` folder that was updated, create a separate PR with the changes to that folder only.
   Wait for all of these PRs to be merged, and wait for the registry to pick up the new versions of all
   `GAP_pkg_*_jll` packages.
   %TODO: a sentence about `juliainterface`

7. In `GAP.jl`, create a PR with the following changes:
   1. In the `Project.toml` update the compat bounds as follows:
      - `GAP_jll` to the `version` from step 1, with a `~` prefix.
      - `GAP_lib_jll` to the `version` from step 3, with a `~` prefix.
      - %TODO: `GAP_pkg_juliainterface`
      - For each `GAP_pkg_*_jll` package that was updated in step 6, update to the new version
      with a `~` prefix. You can find the new version numbers in the registry PRs from step 6.
   2. Run `etc/update_artifact.jl` with the new GAP version as argument to the `Artifacts.toml` file.
      See the top of that script for instructions.
   3. If the GAP release is not ABI-compatible with the previous one, update the minor part of the version
      of `GAP.jl` in its `Project.toml`
   4. If the GAP release was created from a new release branch (e.g. `stable-4.15` instead of `stable-4.14`),
      then update occurrences in `.github/workflows/gap.yml` accordingly.
   Wait for the PR to pass CI (including the `treehash` job) and merge it.
   > ex: <https://github.com/oscar-system/GAP.jl/pull/1274> for an ABI-compatible GAP update.
   > ex: <https://github.com/oscar-system/GAP.jl/pull/1244> for a non-ABI-compatible GAP update. Note
     that the version of `GAP.jl` was not updated here, since this was already done in a previous PR.

8. (Optional) Release a new `GAP.jl`. This is done by pinging JuliaRegistrator in the comments of a commit.
   > ex: <https://github.com/oscar-system/GAP.jl/commit/21d5dd6b4ff8457649a922f0d5ba4a4414502f27#commitcomment-161267536>
