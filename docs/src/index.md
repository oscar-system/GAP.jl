```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

# GAP.jl

## Introduction

GAP.jl is a low level interface from Julia to
[the computer algebra system GAP](https://www.gap-system.org).
The term "low level" means that the aim is
to give Julia access to all GAP objects,
to let Julia call GAP functions,
and to provide conversions of low level data
(integers, Booleans, strings, arrays/lists, dictionaries/records)
between the two systems.

In particular, it is *not* the aim of GAP.jl to provide Julia types
for higher level GAP objects that represent algebraic structures,
such as groups, rings, fields, etc.,
and mappings between such structures.

The connection between GAP and Julia is in fact bidirectional, that is,
GAP can access all Julia objects,
call Julia functions,
and perform conversions of low level data.
This direction will become interesting on the Julia side
as soon as GAP packages provide functionality that is based on
using Julia code from the GAP side.

The viewpoint of an interface from GAP to Julia is described in
[the manual of the GAP package JuliaInterface](assets/html/JuliaInterface/chap0_mj.html).

## Acknowledgements

The development of this Julia package has been supported
by the German Research Foundation (DFG) within the
[Collaborative Research Center TRR 195 *Symbolic Tools in Mathematics
and their Applications*](https://www.computeralgebra.de/sfb/)
(from 2017 until 2028).

## Table of contents

```@contents
Pages = GAP.GAP_docs_pages
```
