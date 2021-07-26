[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oscar-system.github.io/GAP.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://oscar-system.github.io/GAP.jl/dev)
[![Build Status](https://github.com/oscar-system/GAP.jl/workflows/CI/badge.svg)](https://github.com/oscar-system/GAP.jl/actions?query=workflow%3A%22CI%22+branch%3Amaster)
[![Codecov](https://codecov.io/github/oscar-system/GAP.jl/coverage.svg?branch=master&token=)](https://codecov.io/gh/oscar-system/GAP.jl)
[![Coveralls](https://coveralls.io/repos/github/oscar-system/GAP.jl/badge.svg?branch=master)](https://coveralls.io/github/oscar-system/GAP.jl?branch=master)

# GAP.jl Julia package

This repository contains the [GAP.jl](src/GAP.jl) Julia package, as well as the GAP packages
[`JuliaInterface`](pkg/JuliaInterface) and [`JuliaExperimental`](pkg/JuliaExperimental)
developed for the [GAP](https://www.gap-system.org/)-[Julia](https://julialang.org/) integration
as part of the [OSCAR project](https://oscar.computeralgebra.de).

*WARNING*: GAP.jl is intended as a low-level interface between GAP
and Julia. Therefore, for the most part it does not attempt (besides some
general conveniences) to provide a very “Julia-ish” interface to GAP
objects and functions, nor a “GAP-ish” interface to Julia objects and
functions. Instead, this is left to higher-level code, for example in the
[Oscar.jl](https://github.com/oscar-system/Oscar.jl) package.


## Install

To install this package in Julia, use
```
] add GAP
```

## Basic usage

After entering the following in Julia,
```julia
using GAP
```
one may call any GAP function by prefixing its name with `GAP.Globals.`. For example:
```julia
julia> GAP.Globals.SymmetricGroup(3)
GAP: SymmetricGroup( [ 1 .. 3 ] )
```

The Julia types `Int64` and `Bool` are automatically converted to GAP objects.
Several others basic types of objects can be converted using the `GapObj` constructor:
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

Converting back to Julia can be done using suitable Julia constructors.
For example, to convert the GAP list of integers we defined earlier back to Julia,
we might do this:
```julia
julia> Vector{Int64}(x)
3-element Vector{Int64}:
 1
 2
 3
```

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
