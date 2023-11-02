```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

# Basics

## Accessing GAP from Julia

- Any global GAP variable and function can be accessed from Julia via the
  [`GAP.Globals`](@ref) object; for example `GAP.Globals.Binomial(5,3)`.
  See [Convenience adapters](@ref) for dealing with GAP syntax beyond
  simple function calls.

- The [`GAP.prompt`](@ref) command can be used to switch to a GAP session that
  works like a regular GAP, except that leaving it (via `quit;` or by pressing
  Ctrl-D) returns one to a Julia prompt. From the GAP prompt, one can access
  Julia variables via the `Julia` object, for example `Julia.binomial(5,3)`.
  For more details on how to access Julia from GAP, please consult
  [the manual of the GAP package JuliaInterface](https://oscar-system.github.io/GAP.jl/stable/assets/html/JuliaInterface/chap0_mj.html).

- Alternatively, one can start GAP in the traditional way,
  by executing a shell script.
  Such a script can be created in a location of your choice
  via [`GAP.create_gap_sh`](@ref).
  Note that one cannot switch from such a GAP session to the underlying
  Julia session and back.

```@docs
Globals
evalstr
evalstr_ex
GAP.prompt
GAP.create_gap_sh
```

## Accessing Julia from GAP

The GAP-Julia interface is fully bidirectional, so it is also possible to access all
Julia functionality from GAP. To learn more about this, please consult
[the manual of the GAP package JuliaInterface](https://oscar-system.github.io/GAP.jl/stable/assets/html/JuliaInterface/chap0_mj.html).

## Types

```@docs
FFE
GapObj
GAP.Obj
GapInt
```
