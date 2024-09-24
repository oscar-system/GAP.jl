[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oscar-system.github.io/GAP.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://oscar-system.github.io/GAP.jl/dev)
[![Build Status](https://github.com/oscar-system/GAP.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/oscar-system/GAP.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Codecov](https://codecov.io/github/oscar-system/GAP.jl/coverage.svg?branch=master&token=)](https://codecov.io/gh/oscar-system/GAP.jl)

# GAP.jl Julia package

This repository contains the [GAP.jl](src/GAP.jl) Julia package, as well as the GAP packages
[`JuliaInterface`](pkg/JuliaInterface) and [`JuliaExperimental`](pkg/JuliaExperimental)
developed for the [GAP](https://www.gap-system.org/)-[Julia](https://julialang.org/) integration
as part of the [OSCAR project](https://www.oscar-system.org).

*WARNING*: GAP.jl is intended as a low-level interface between GAP
and Julia. Therefore, for the most part it does not attempt (besides some
general conveniences) to provide a very “Julia-ish” interface to GAP
objects and functions, nor a “GAP-ish” interface to Julia objects and
functions. Instead, this is left to higher-level code, for example in the
[Oscar.jl](https://github.com/oscar-system/Oscar.jl) package.


## Install

To install this package in Julia:
```
using Pkg; Pkg.add("GAP")
```

## Basic usage

After entering the following in Julia,
```julia
using GAP
```
one may access any global GAP variable by prefixing its name with `GAP.Globals.`, and
call GAP functions like Julia functions. For example:
```julia
julia> GAP.Globals.SymmetricGroup(3)
GAP: SymmetricGroup( [ 1 .. 3 ] )
```

The Julia types `Int64` and `Bool` are automatically converted to GAP
objects when passed as arguments to GAP functions. Several others basic
types of objects can be converted using the `GapObj` constructor. For
example, here we convert a `Vector{Int}` to a GAP list:
```julia
julia> x = GapObj([1,2,3])
GAP: [ 1, 2, 3 ]
```
For nested objects, one can use the optional `recursive` keyword argument:
```julia
julia> GapObj([1,2,[3,4,5]])
GAP: [ 1, 2, <Julia: [3, 4, 5]> ]

julia> GapObj([1,2,[3,4,5]]; recursive=true)
GAP: [ 1, 2, [ 3, 4, 5 ] ]
```

Converting GAP objects to native Julia objects is done using suitable Julia constructors.
For example, to convert the GAP list of integers we defined earlier back to Julia,
we might do this:
```julia
julia> Vector{Int}(x)
3-element Vector{Int64}:
 1
 2
 3
```

You can temporarily switch to a GAP prompt using `GAP.prompt()`:
```
julia> GAP.prompt();
gap> G := SymmetricGroup(5);
Sym( [ 1 .. 5 ] )
gap> quit;

julia> GAP.Globals.G
GAP: Sym( [ 1 .. 5 ] )
```

For more information on these and other capabilities of this package, please
consult the [GAP.jl manual](https://oscar-system.github.io/GAP.jl/stable).


## Contact

Issues should be reported via our [issue tracker](https://github.com/oscar-system/GAP.jl/issues).

Responsible for GAP.jl within the OSCAR project are Thomas Breuer and Max Horn.

## General Disclaimer

All code in this repository is preliminary work.

It comes with absolutely no warranty and will most likely have errors. If you use it for computations, please check the correctness of the result very carefully.

Also, everything in this repository might change in the future, so currently any update can break the code you wrote upon functionality from packages in this repository.

This software is licensed under the LGPL, version 3, or any later version.

## Funding

The development of this Julia package is supported by the Deutsche Forschungsgemeinschaft DFG within the [Collaborative Research Center TRR 195](https://www.computeralgebra.de/sfb/).
