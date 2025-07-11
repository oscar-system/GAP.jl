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

The build scripts for these JLL packages can be found here:

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

2. Update the GAP build script by bumping the patch part of the version,
   and changing the `libjulia_jll` version number to the new one.
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/11335>

3. Wait for the Yggdrasil merge, and wait for the registry.

4. Update the `GAP_pkg_juliainterface` with the version number of the
   `GAP_jll` from the previous step, bump the patch part of `offset`,
   and change the `libjulia_jll` version number to the new one.
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/11336>

5. Wait for the Yggdrasil merge, and wait for the registry.

4. Bump the dependence in `GAP.jl` to whatever version numbers were released in Steps 3 and 5.


## Updating GAP

After a new GAP version is released, the following steps are necessary to update
all of the JLL packages that depend on GAP.

1. Update the GAP build script with the new `upstream_version` and SHA256 of the release tarball
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/9937>

   In this specific commit, there was also an update to `Readline_jll` and some build flags,
   but that should not be needed in most cases.

2. Wait for the Yggdrasil merge, and wait for the registry.
   > ex: <https://github.com/JuliaRegistries/General/pull/120909>

3. Update the GAP_lib build script with the new `upstream_version` and SHA256 of the release tarball
   > ex: <https://github.com/JuliaPackaging/Yggdrasil/pull/9938>

4. Wait for the Yggdrasil merge, and wait for the registry.
   > ex: <https://github.com/JuliaRegistries/General/pull/120893>

TODOs: 
- update `G/GAP_pkg/update.jl` (in Yggdrasil): `upstream_version`, `gap_version`, `gap_lib_version`, juliainterface `upstream_version`
- run `G/GAP_pkg/update.jl` (in Yggdrasil) and push the result in multiple small PRs which each touch 3-5 folders, wait for all of them to be merged and released to the registry
- run `etc/update_artifact.jl` (in GAP.jl)
- update compat bounds of all JLLs
- (optionally) release GAP.jl
