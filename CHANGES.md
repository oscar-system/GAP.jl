# Changes in GAP.jl

## Version 0.13.0-DEV (released YYYY-MM-DD)

- Update to GAP 4.14.0
- Instead of downloading a single huge "artifact" containing all deposited GAP
  packages, we now use (and download) one artifact per GAP package.
- Use precompiled binaries for the following GAP packages:
  - ace
  - anupq
  - browse
  - cddinterface
  - cohomolo
  - crypting
  - cvec
  - datastructures
  - deepthought
  - digraphs
  - edim
  - ferret
  - float
  - fplsa
  - gauss
  - grape
  - guava
  - io
  - json
  - kbmag
  - normalizinterface
  - nq
  - orb
  - profiling
  - simpcomp
- Add `GAP.Packages.build_recursive(name)`
- `GAP.Packages.build(name)` no longer tries to build the package if it is
  already installed

## Version 0.12.1 (released 2024-12-09)

- Add `GAP.Packages.build(name)`
- Add iteration over GAP iterators
- Reintroduce `julia_to_gap` for backward compatibility
- Improve evalstr to show syntax warnings

## Version 0.12.0 (released 2024-09-25)

- Remove GAP function `JuliaModule` (use `Julia.MODULENAME` etc. instead)
- Remove GAP function `JuliaFunction` (use `Julia.FUNCNAME` etc. instead)
- Support keyword arguments in `CallJuliaFunctionWithCatch`
- Stop wrapping Julia modules on the GAP side in special objects
- Rewrite `julia_to_gap`, in order to
  - make the installation of new conversion methods from Julia to GAP
    simpler and safer and
  - restrict the necessity to create dictionaries to situations where
    recursive conversions make sense.
  For that, the function `GAP.GapObj_internal`, the macro `GAP.@install`,
  and the type `GapCacheDict` were introduced.
- Many internal changes and refactoring that should have no user facing effect
  but will simplify future updates

## Version 0.11.4 (released 2024-09-19)

- Support AbstractAlgebra 0.43

## Version 0.11.3 (released 2024-09-16)

- Fix the availability check in `Packages.install` to handle transitive dependencies
- Add dependency on AbstractAlgebra
- Replace banner hiding code with the improved version from AbstractAlgebra
- Adjust `show` method for GAP objects to make use of AbstractAlgebra pretty printing

## Version 0.11.2 (released 2024-09-10)

- Update to GAP 4.13.1
- Add `GetJuliaScratchspace` to `JuliaInterface`
- Enhance `Packages.install`
- Fix access to Julia docstrings from the GAP session
- Restore compatibility with Julia nightly (for now)
- Remove the GAP user preference `IncludeJuliaStartupFile`
  that was used to control whether `~/.julia/config/startup.jl`
  gets included by Julia when GAP is started together with Julia
  via a `gap.sh` script.
  In this situation, one can now use the environment variable
  `JULIA_STARTUP_FILE_IN_GAP`;
  if its value is `yes` then the startup file gets included, otherwise not.
- Various janitorial changes

## Version 0.11.1 (released 2024-06-06)

- Optimize conversion from `UInt` to `GapObj`
- Allow `GapInt(x)` as shorthand for producing a GAP integer
- Show an error when trying to load GAP.jl while multithreaded GC is enabled
- Support `gap_to_julia(::AbstractVector)`
- Enhance `@wrap` so that it can produce wrapper functions which coerce
  arguments to GAP objects (see its docstring for details and examples)
- Various janitorial changes

## Version 0.11.0 (released 2024-04-05)

- Update to GAP 4.13.0
- Removed bundled `etc/BuildPackages.sh` (no longer needed)
- Fix GAP help access for Julia nightly
- Various janitorial changes

## Version 0.10.3 (released 2024-03-01)

- Fix TAB completion for e.g. 'GAP.Globals.MTX.S' in Julia >= 1.11

## Version 0.10.2 (released 2024-01-26)

- Add `GAP.Packages.locate_package`
- Enhance `GAP.Packages.load` to accept a URL string for the `install`
  keyword argument (see its documentation for details)
- Change package downloader code to a custom Downloader object to
  work around certain technical issues in Julia 1.10 and upwards

## Version 0.10.1 (released 2023-12-29)

- Optimize GAP function calls
- Improve type stability in a bunch of places
- Enhance `GAP.Packages.install` to work right if multiple Julia processes
  invoke it to install the same package simultaneously
- Various janitorial changes

## Version 0.10.0 (released 2023-10-10)

- Add `hasbangindex`, `hasbangproperty`
- Change `hash(::GapObj)` to throw an error (no general non-trivial
  hashing is possible for general GAP objects)
- Remove support for conversion to `AbstractString` (it was not
  meaningful anyway, and hopefully nobody used it; but if you did, just
  convert to `String` instead for an identical outcome)
- Teach `InteractiveUtils.edit` about GAP function
- Add options to `GAP.Package.install` etc. to help debug issues with it
- Various janitorial changes

## Version 0.9.8 (released 2023-09-11)

- Allow GAP.Obj(x,true) for recursive conversion (#910. #925)
- Improve documentation on special GAP syntax (#922, #929, #932)
- Work around a potential crash when GAP launches subprocesses (#906)
- If the environment variable `GAP_BARE_DEPS` is set, then GAP skips loading
  any of its packages, except for JuliaInterface (#912)
- Various janitorial changes

## Version 0.9.7 (released 2023-06-26)

- Allow passing a path to `GAP.Packages.load` instead of a package name
- Quote `@gap` and `g_str` results, to make those macros useful in functions
  (not just in the REPL)
- Improve documentation of `evalstr_ex`, `evalstr`
- Reduce the occurrences of `evalstr` in docstrings
- Prevent a race condition when doing `@everywhere using GAP`
- Various janitorial changes

## Version 0.9.6 (released 2023-05-10)

- Fix compatibility issues with upcoming Julia 1.10-DEV
- Various janitorial changes

## Version 0.9.5 (released 2023-05-02)

- Allow iterating over Julia objects from within GAP
- Various janitorial changes

## Version 0.9.4 (released 2023-03-04)

- Tweak @gapattribute to not require `import GAP: @gapwrap`
- Update OSCAR URL

## Version 0.9.3 (released 2023-02-05)

- Update package archives to a newer version (corresponding to GAP 4.12.2 plus
  some updates). Among other things this should fix troubles using GAP.jl
  under WSL.
- Catch `Downloads.download` errors, for better feedback when trying to install
  GAP packages while offline
- Update bundled `BuildPackages.sh` script to match GAP 4.12.2
- Fix building digraphs and a few other GAP packages

## Version 0.9.2 (released 2022-12-02)

- Silence scary warning about missing compiler
- Prepare for an upcoming change to serialization in Julia 1.10
- `Packages.install` and thus also `Packages.load` with argument
  `install = true` admit prescribing a version number of the package
  to be loaded/installed
- Document `recursive` keyword argument for `GAP.Obj` and `GAP.GapObj`

## Version 0.9.1 (released 2022-11-23)

- Added a longer example for using GAP.jl, based around the Rubik's cube
- Fix some type minor stability issues

## Version 0.9.0 (released 2022-11-01)

- Update go GAP 4.12.1.

## Version 0.8.5 (released 2022-10-18)

- Better (?) fix for the race condition the previous release was supposed to address

## Version 0.8.4 (released 2022-10-12)

- Avoid a race condition when loading GAP.jl concurrently in multiple processes

## Version 0.8.3 (released 2022-10-10)

- Improve the `gap_to_julia` and `julia_to_gap` documentation by providing
  an explicit list of types for which conversions are provided in GAP.jl
  (this information was already available in GAP manual for `JuliaInterface`,
  but not on the Julia side)
- Use `Scratch.jl` for the GAP root directory to hopefully avoid issues on
  systems where the Julia depot is read-only
- Fix banner printing issues in Julia >= 1.8
- Install a `GAP.Globals.Download` method if possible (will have an effect
  once we start to ship the latest version of the GAP package `utils`)

## Version 0.8.2 (released 2022-08-05)

- Switch GAP.Packages test to use `fga` instead of `io`

## Version 0.8.1 (released 2022-06-10)

- Add `getbangindex`, `setbangindex!`, `getbangproperty`, `setbangproperty!`,
  helpers to access to internals of positional and component objects
- Optimize speed of calls to GAP function without arguments
- Fix `Packages.install` to deal with more kinds of download errors
  (e.g. when the user is offline)

## Version 0.8.0 (released 2022-04-21)

- Upgrade to newer GAP snapshot
- Give helpful error if `GAP_jll` is not available
- Allow assigning Julia variables in arbitrary Julia modules from GAP.
  For example `Julia.x := 1` sets the variable `x` in the `Main` module,
  as does `Julia.Main.x := 1`.
- Change `@gapattribute` to use prefixes `has_` and `set_` instead of
  `has` and `set`. So for example for `@gapattribute isfinite(obj) = ...`
  the tester function now is `has_isfinite` instead of `hasisfinite` and
  the setter function is `set_isfinite` instead of `setisfinite`.
- Remove `Base.big(obj::GapObj)`: nothing was using it and it does not really
  fit conceptually into this package.
- Implement tab completion on GAP prompts for Julia module members;
  so e.g. typing `Julia.GA` followed by a tab key press is completed to
  `Julia.GAP`, and `Julia.GAP.` then suggests the names of all members
  of the `GAP` module
- Fix a bug where a warning issues when no C/C++ compiler could be found
  was accidentally turned into an error that prevented loading GAP.jl.
  Note that installing certain GAP packages still requires a C/C++ compiler.

## Version 0.7.7 (released 2022-02-14)

- Add `quiet` argument to `Packages.load` 
- Fix compatibility with Julia nightly
- Replace some calls to low-level GAP functions by high-level synonyms,
  for better compatibility with future GAP releases

## Version 0.7.6 (released 2022-02-07)

- Improve how we show the error messaged triggered by a user trying to
  load GAP.jl on native Windows (which isn't supported)
- Rewrite `@wrap`, `@gapwrap` and `@gapattribute` to be better compatible
  with future Julia versions.

## Version 0.7.5 (released 2022-01-24)

- Improve type stability of the code for converting from GAP to Julia objects;
  now in many cases code calling it will get precise information about the
  result type, enabling better optimizations
- Fixed a bug in `@gapattribute` that manifested in a runtime error

## Version 0.7.4 (released 2022-01-18)

- Better banner suppression logic
- Restore use of `GAP_pkg_juliainterface_jll` (accidentally broken in the
  previous release)

## Version 0.7.3 (released 2022-01-01)

- Restore compatibility with Julia nightlies

## Version 0.7.2 (released 2021-11-17)

- Use `GAP_pkg_juliainterface_jll` to install a compiled version of the
  bundled C code, thus for basic use of GAP.jl no C/C++ compiler is needed
  anymore; this also avoids compatibility issues when switching back and forth
  between Julia 1.6 and 1.7
- Add support for REPL tab completion on members of `GAP.Globals`; e.g. if you
  enter `GAP.Globals.MTX.Is` into the REPL and press the TAB key twice, you
  should be offered a list of members of the record `GAP.Globals.MTX` whose
  name starts with `Is`.
- Fix a bug where running GAP through Julia via a `gap.sh` wrapper created
  using `GAP.create_gap_sh` could produce an error (specifically when a `QUIT`
  statement is encountered while processing a GAP file by passing its path as
  argument to `gap.sh`)
- Fix printing of certain containers; e.g. `repr(GAP.GapObj[])` confusingly
  produced the string `"GAP_jll.MPtr[]"`; it now gives `"GapObj[]"` resp.
  `"GAP.GapObj[]"` (depending on whether `using GAP` or `import GAP` were
  used to load GAP.jl)

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

