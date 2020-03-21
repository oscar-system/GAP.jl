# The GAP 4 package `JuliaExperimental'

JuliaExperimental provides experimental code to test and explore the
capabilities of the JuliaInterface package, and the general combination of
GAP and Julia.

## General Disclaimer

All code in this repository is preliminary work.

It comes with absolutely no warranty and will most likely have errors. If you
use it for computations, please check the correctness of the result very
carefully.

Also, everything in this repository might change in the future, so currently
any update can break the code you wrote upon functionality from packages in
this repository.

This software is licensed under the LGPL, version 3, or any later version.

## Installation

### Requirements

- Julia 1.3 or higher, compiled in `<path_to_julia>`
- GAP 4.11 or higher, compiled in `<path_to_gaproot>`
- JuliaInterface, compiled in `<path_to_juliainterface>`
- The Julia packages Nemo.jl and Singular.jl

### Installation

#### General instructions

- Compile the JuliaInterface package as described it its README.md
- Start Julia and make sure Nemo.jl and Singular.jl are compiled, by typing

        using Singular
        using Nemo

## Usage

Load the JuliaExperimental package via

    LoadPackage( "JuliaExperimental" );
