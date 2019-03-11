# The GAP 4 package `JuliaInterface'

JuliaInterface provides an interface to the Julia interpreter.

## General Disclaimer

All code in this repository is preliminary work.

It comes with absolutely no warranty and will most likely have errors. If you use it for computations, please check the correctness of the result very carefully.

Also, everything in this repository might change in the future, so currently any update can break the code you wrote upon functionality from packages in this repository.

This software is licensed under the LGPL, version 3, or any later version.

## Installation

### Requirements

- Julia 1.1 or higher, compiled in `<path_to_julia>`
- GAP 4.10 or higher, compiled in `<path_to_gaproot>`
- Standard building tools, such as gcc, autotools, libtools, automake, and make.
  If you were able to build GAP and Julia from their git repositories, JuliaInterface
  can be built.

### Installation

#### General instructions

- Clone or download this repository into the GAP package folder `<gap_package_folder>`, which
  is usually `<path_to_gaproot>/pkg`. You can download the package via
  ```
  git clone https://github.com/oscar-system/GAP.jl <path_to_gaproot>/pkg/GAP.jl
  ```
- Configure and compile JuliaInterface via
  ```
  cd <path_to_gaproot>/pkg/GAPJulia/JuliaInterface
  ./configure <path_to_gaproot>
  make
  ```

#### Notes for Mac OS X

It is possible to link JuliaInterface against the official Julia binary
which one can download from <https://julialang.org/downloads/>.
To do so, run configure as follows:

    ./configure --with-julia=/PATH/TO/Julia*.app/Contents/Resources/julia

## Usage

Load the JuliaInterface package via

    LoadPackage( "JuliaInterface" );

For further details, please consult the package manual.
