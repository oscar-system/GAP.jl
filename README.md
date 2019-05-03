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

## General Disclaimer

All code in this repository is preliminary work.

It comes with absolutely no warranty and will most likely have errors. If you use it for computations, please check the correctness of the result very carefully.

Also, everything in this repository might change in the future, so currently any update can break the code you wrote upon functionality from packages in this repository.

This software is licensed under the LGPL, version 3, or any later version.
