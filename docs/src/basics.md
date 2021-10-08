```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

# Basics

## Types

```@docs
FFE
GapObj
GAP.Obj
GapInt
```

## Accessing GAP from Julia

```@docs
Globals
evalstr
GAP.prompt
GAP.create_gap_sh
```

## Accessing Julia from GAP

The GAP-Julia interface is fully bidirectional, so it is also possible to access all
Julia functionality from GAP. To learn more about this, please consult
[the manual of the GAP package JuliaInterface](GAP_ref(JuliaInterface:Title page)).
