# Changes in GAP.jl

## Version 0.7.2 (released XXX)

- ...

## Version 0.7.1 (released 2021-10-29)

- Fix compatibility with Julia 1.6.0 and 1.6.1. (Note that we recommend using
  Julia 1.6.3 or newer anyway)
- Improve the GAP.jl manual; in particular, it now includes the manual of the
  JuliaInterface GAP package
- Optimize conversion of Julia ranges to GAP
- Update to a slightly newer GAP 4.12dev snapshot

## Version 0.7.0 (released 2021-10-08)

This is the first release of the 0.7.x series. It contains the following breaking
changes compared to the 0.6.x release:

- Require Julia 1.6 or later.
- Remove `LoadPackageAndExposeGlobals`. If you are using this, see
  <https://github.com/oscar-system/GAP.jl/pull/696> for alternatives.
- Remove all `convert` methods. If you were using `convert(GapObj, val)`,
  you can use `GapObj(val)` or `julia_to_gap(val)` instead. If you were
  using `convert(T,gapobj)`, use `T(gapobj)` or `julia_to_gap(gapobj)`
  instead.
- Remove `GAP.gap_exe()`. Instead please use `GAP.create_gap_sh(path)`.
- Remove GAP function `IsArgumentForJuliaFunction`. No replacement should
  be necessary.
- Remove GAP function `ImportJuliaModuleIntoGAP`. As a replacement, use
  `JuliaEvalString("import MODULENAME")`.
- Restrict `GapObj` constructor by adding a return type annotation that
  ensures only values of type `GapObj` are returned. If you relied on this
  also returning `Int`, `Bool` or `FFE`, please use the `GAP.Obj` constructor
  instead. If you relied on also Julia objects being returned, you should
  probably revise your code; but if you determine that you still really
  *really* have to do this, you can by using `julia_to_gap`.

Other changes:

- Add `GapInt` type union
- Patch the GAP package manager to perform downloads via Julia's
  `Downloads.download` to avoid certain failure scenarios
- Add `@wrap` macro as an alternative to `@gapwrap` for certain use cases.
- Don't show the GAP banner if Julia is started with the `--quiet` flag
- Call the GAP AtExit handler when exiting Julia, so that e.g. the command
  line history is saved (if the user enabled this in their preferences) or
  temporary directories are removed.
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

