# Maintainer README

Some information for maintainers of the GAP.jl packages


## Making releases

1. Switch to the `master` branch and `cd` into the root directory of the git repository.

2. Update the version of the Julia and GAP packages by invoking the script
   `etc/update_version.sh` with the new version as argument. Example:
   `etc/update_version.sh 0.3.0` (by the way, this is shell script which calls
   `perl` right now; it would make sense to rewrite it as a Julia script to avoid
   the need for perl).

3. `git push`

4. Ideally wait for Travis CI to complete the full CI tests for the commit
   you just pushed

5. Comment on the commit on GitHub with the message `@JuliaRegistrator
   register` ([see here for an example](https://github.com/oscar-system/GAP.jl/commit/159c6fd580e9d9cfbc1877a0856c4a5f9ecaba4d)).

The latter works because we have set up a GitHub Action for
[Julia TagBot](https://github.com/marketplace/actions/julia-tagbot) to tag and
make the release automatically.


## Updating `GAP_jll` resp. `GAP_lib_jll`

To do this, open a pull request for <https://github.com/JuliaPackaging/Yggdrasil>.
The files to edit there are in `G/GAP` (produces a JLL with compiled code for
the GAP kernel) and `G/GAP_lib` (produces a JLL with the GAP library code, no
binaries). Usually, those two JLLs should be updated simultaneously; but if
one knows that only the kernel resp. only the GAP library, one can also
deviate from this.


## Updating `GAP_pkg_juliainterface_jll`

When the C sources in `pkg/JuliaInterface/src` change, this JLL should be updated.
To do this, open a pull request for <https://github.com/JuliaPackaging/Yggdrasil>.
The file to edit there is `G/GAP_pkg/GAP_pkg_juliainterface/build_tarballs.jl`.
Increment the version and the git SHA1 hash.


## Using GAP.jl with a different version of GAP than what `GAP_jll` provides

This can be useful for various reasons e.g.,

- you need to test GAP.jl with a newer GAP version, perhaps even its master branch
- you need to test with a newer Julia version that breaks binary compatibility
- you need to test with a Julia debug build

For this to work, follow these instructions:

1. Obtain a copy of the GAP sources, probably from a clone of the GAP git repository.
   Let's say this is in directory `GAPROOT`.

2. Compiled GAP inside GAPROOT once (this is to ensure `build/c_oper1.c` and
  `build/c_type1.c` are present).

3. Build GAP with the Julia version of your choice by executing the `etc/setup_override_dir.jl`
   script. It takes as first argument the GAPROOT, and as second argument the places where
   the result shall be installed. I recommend to execute this in a separate
   environment, as it may need to install a few things.

   To give a concrete example you could invoke

        julia --proj=override etc/setup_override_dir.jl $GAPROOT /tmp/gap_jll_override

4. Use the `etc/run_with_override.jl` script with the exact same Julia executable
   and the override environment we just prepared.

        julia --proj=override etc/run_with_override.jl /tmp/gap_jll_override

5. This opens a Julia session with the override in effect. You can now e.g. load GAP.jl
   via `using GAP`, or install other packages (such as Oscar) and test with them.

## Updating the package artifacts

Run this from the root director of GAP.jl:

    julia --project=etc etc/update_artifacts.jl 4.X.Y
