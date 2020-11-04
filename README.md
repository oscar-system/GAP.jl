[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://oscar-system.github.io/GAP.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://oscar-system.github.io/GAP.jl/dev)
[![Build Status](https://github.com/oscar-system/GAP.jl/workflows/CI/badge.svg)](https://github.com/oscar-system/GAP.jl/actions?query=workflow%3A%22CI%22)
[![Code Coverage](https://codecov.io/github/oscar-system/GAP.jl/coverage.svg?branch=master&token=)](https://codecov.io/gh/oscar-system/GAP.jl)

# GAP.jl Julia package

This repository contains the [GAP.jl](src/GAP.jl) Julia package, as well as the GAP packages
[`JuliaInterface`](pkg/JuliaInterface) and [`JuliaExperimental`](pkg/JuliaExperimental)
developed for the [GAP](https://www.gap-system.org/)-[Julia](https://julialang.org/) integration
as part of the [OSCAR project](https://oscar.computeralgebra.de).

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
Several others types of objects can be converted using `GAP.julia_to_gap`:
```julia
julia> x = GAP.julia_to_gap([1,2,3])
GAP: [ 1, 2, 3 ]
```
Converting back to Julia is done using `GAP.gap_to_julia`.
However, for this one needs to specify the desired type of the resulting object.
For example, to convert the GAP list of integers we just defined back to Julia, we might do this:
```julia
julia> GAP.gap_to_julia(Array{Int64,1}, x)
3-element Array{Int64,1}:
 1
 2
 3
```

## General Disclaimer

All code in this repository is preliminary work.

It comes with absolutely no warranty and will most likely have errors. If you use it for computations, please check the correctness of the result very carefully.

Also, everything in this repository might change in the future, so currently any update can break the code you wrote upon functionality from packages in this repository.

This software is licensed under the LGPL, version 3, or any later version.

## Funding

The development of this Julia package is supported by the Deutsche Forschungsgemeinschaft DFG within the [Collaborative Research Center TRR 195](https://www.computeralgebra.de/sfb/).
