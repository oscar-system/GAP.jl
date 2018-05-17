# The GAP 4 package `JuliaInterface'

JuliaInterface provides an interface to the Julia interpreter.

## Installation

### Requirements

- Julia 0.6.2 or higher, compiled in `<path_to_julia>`
- GAP 4.9.1 or higher, compiled in `<path_to_gaproot>`
- Standard building tools, such as gcc, autotools, libtools, automake, and make.
  If you were able to build GAP and Julia from their git repositories, JuliaInterface
  can be built.

### Installation

#### General instructions

- Clone or download this repository into the GAP package folder `<gap_package_folder>`, which
  is usually `<path_to_gaproot>/pkg`. You can download the package via
  ```
  git clone https://github.com/oscar-system/GAPJulia <path_to_gaproot>/pkg/GAPJulia
  ```
- Configure and compile JuliaInterface via
  ```
  cd <path_to_gaproot>/pkg/GAPJulia/JuliaInterface
  ./autogen.sh
  ./configure --with-gaproot=<path_to_gaproot> --with-julia=<path_to_julia>/usr
  make
  ```

#### Notes for Mac OS X

It is possible to link JuliaInterface against the official Julia binary
which one can download from <https://julialang.org/downloads/>.
To do so, run configure as follows:

  ./configure --with-julia=/PATH/TO/Julia*.app/Contents/Resources/julia

## Usage

Load the JuliaInterface package via
```
LoadPackage( "JuliaInterface" );
```


