[![Build Status](https://travis-ci.com/oscar-system/GAP.jl.svg?branch=master)](https://travis-ci.com/oscar-system/GAP.jl)
[![Code Coverage](https://codecov.io/github/oscar-system/GAP.jl/coverage.svg?branch=master&token=)](https://codecov.io/gh/oscar-system/GAP.jl)

# GAP.jl Julia module

This repository contains the [GAP.jl](src/GAP.jl) Julia module, as well as the GAP packages
[`JuliaInterface`](pkg/GAPJulia/JuliaInterface) and [`JuliaExperimental`](pkg/GAPJulia/JuliaExperimental)
developed for the [GAP](https://www.gap-system.org/)-[Julia](https://julialang.org/) integration
as part of the [OSCAR project](http://oscar.computeralgebra.de).

## Install

To install this module in Julia, use
```
] add https://github.com/oscar-system/GAP.jl
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
