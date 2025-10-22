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

Please use our [issue tracker](https://github.com/oscar-system/GAP.jl/issues)
to report any issues you may encounter when using it. You can also submit
feature requests and general help requests via that tracker.

GAP.jl is being maintained by
- Thomas Breuer <sam@math.rwth-aachen.de>>
- Lars Göttgens <goettgens@art.rwth-aachen.de>
- Max Horn <mhorn@rptu.de>


## License

GAP.jl is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 3 of the License, or (at your
option) any later version.

GAP.jl is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public License
along with GAP.jl in form of the file `LICENSE`, or see
<https://www.gnu.org/licenses/lgpl.html>.

Copyright (C) 2017-2025 by its authors, which include:
- Thomas Breuer
- Sebastian Gutsche
- Lars Göttgens
- Max Horn
and many others -- please refer to the git history of the project for a
complete list.


## Funding

The development of this Julia package is supported by the Deutsche Forschungsgemeinschaft DFG within the [Collaborative Research Center TRR 195](https://www.computeralgebra.de/sfb/).
The package belongs to [the OSCAR project](https://www.oscar-system.org/).

