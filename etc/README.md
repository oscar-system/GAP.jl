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

4. Ideally wait for completion of the all CI tests for the commit you just pushed.

5. Comment on the commit on GitHub with the message `@JuliaRegistrator
   register` ([see here for an example](https://github.com/oscar-system/GAP.jl/commit/159c6fd580e9d9cfbc1877a0856c4a5f9ecaba4d)).

The latter works because we have set up a GitHub Action for
[Julia TagBot](https://github.com/marketplace/actions/julia-tagbot) to tag and
make the release automatically.


## Using GAP.jl with a different version of GAP than is bundled

For various reasons you may wish to use GAP.jl with a different GAP version than
the one bundled with it via `Artifacts.toml`; e.g. to test GAP.jl against the
GAP master branch.

To do so, you can use a `Overrides.toml` file, as described in the `Pkg.jl` manual:
<https://julialang.github.io/Pkg.jl/dev/artifacts/#Overriding-artifact-locations-1>
