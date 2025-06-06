# The GAP package `JuliaExperimental'

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

For details about e.g. reporting issues, copyright & licensing, and so on,
please refer to the `README.md` file of `GAP.jl` (which normally should be two
levels above the directory this file you are reading right now resides in).

## Installation

This package is automatically built and installed as part of the Julia
package `GAP.jl`.

For all features to work, the Julia packages Nemo.jl and Singular.jl
must be installed.

## Usage

Load the JuliaExperimental package via

    LoadPackage( "JuliaExperimental" );
