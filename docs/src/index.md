# GAP.jl

```@contents
```

```@meta
CurrentModule = GAP
```

## Introduction

TODO: describe the goals and non-goals of this package

TODO: also link to JuliaInterface docs (also JuliaExperimental?)


## Types

```@docs
FFE
GapObj
```

## Macros

```@docs
@gap
@g_str
```

## Conversions

```@docs
gap_to_julia
julia_to_gap
```

## Convenience adapters

TODO: describe the various convenience / adapter methods we install, e.g. for
basic arithmetic, accessing GAP list and record entries, calling GAP function, etc.


TODO: Describe access to arbitrary GAP variables and functions via `GAP.Globals.IDENTIFIER_NAME`

TODO: describe Help system integration


## Managing GAP packages

```@docs
GAP.Packages.load
GAP.Packages.install
GAP.Packages.update
GAP.Packages.remove
```

## Other

```@docs
GAP.prompt
```


## Index

```@index
```
