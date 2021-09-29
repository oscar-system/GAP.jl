# Changes in GAP.jl


## Version 0.7.0 (released 2022-MM-DD)

This is the first release of the 0.7.x series. It contains the following breaking
changes compared to the 0.6.x release:

- `LoadPackageAndExposeGlobals` was removed. If you are using this, see
  <https://github.com/oscar-system/GAP.jl/pull/696> for alternatives.
- Remove all `convert` methods. If you were using `convert(GapObj, val)`,
  you can use `GapObj(val)` or `julia_to_gap(val)` instead. If you were
  using `convert(T,gapobj)`, use `T(gapobj)` or `julia_to_gap(gapobj)`
  instead.
- Remove `IsArgumentForJuliaFunction` from the GAP side.

Other changes:

- Add `GapInt` type union
- Patch the GAP package manager to perform downloads via Julia's
  `Downloads.download` to avoid certain failure scenarios
- Don't show the GAP banner wen Julia is started with the `--quiet` / `-q` flag
- Many internal changes and refactoring


## Version 0.6.2 (released 2021-08-31)

- use latest versions of `GAP_jll`, `GAP_lib_jll`

## Version 0.6.1 (released 2021-08-19)

## Version 0.6.0 (released 2021-07-28)

## Version 0.5.2 (released 2021-02-14)

## Version 0.5.1 (released 2021-01-07)

## Version 0.5.0 (released 2020-12-11)

## Version 0.4.4 (released 2020-09-06)

## Version 0.4.3 (released 2020-08-04)

## Version 0.4.2 (released 2020-07-09)

## Version 0.4.1 (released 2020-05-21)

## Version 0.4.0 (released 2020-05-13)

- Add GAP.prompt() function which gives a GAP prompt inside Julia
- Add support for Julia keyword arguments on the GAP side
- Overload the Julia 'in' operator for GAP objects
- Add conversion constructors for various Julia types, to allow for more
  idiomatic Julia code accessing GAP objects
- Improve GAP <-> Julia conversion
- Show the GAP banner again by default, unless we are being loaded from Oscar.jl
- Switch to Julia "artifact" system for downloading the GAP sources,
  which can save time and disk space when rebuilding or reinstalling GAP.jl
- Complete overhaul of the build process for GAP, making it more robust
- Ensure that we link against the same GMP and readline as other components of
  OSCAR do
- Remove the implicit dependency on LinearAlgebra.jl
- Fix a bunch of minor bugs
- Various janitorial changes


## Version 0.3.5 (released 2020-03-22)

