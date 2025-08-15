#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

struct GlobalsType end

Base.show(io::IO, ::GlobalsType) = Base.show(io, "table of global GAP objects")

"""
    Globals

This is a global object that gives access to all global variables of the
current GAP session via `getproperty` and `setproperty!`.

# Examples
```jldoctest
julia> GAP.Globals.Size    # a global GAP function
GAP: <Attribute "Size">

julia> GAP.Globals.size    # there is no GAP variable with this name
ERROR: GAP variable size not bound
[...]

julia> hasproperty( GAP.Globals, :size )
false

julia> GAP.Globals.size = 17;

julia> hasproperty( GAP.Globals, :size )
true

julia> GAP.Globals.size
17

julia> GAP.Globals.UnbindGlobal(g"size")

julia> GAP.Globals.Julia   # Julia objects can be values of GAP variables
Main

```
"""
const Globals = GlobalsType()

function getproperty(::GlobalsType, name::Symbol)
    v = _ValueGlobalVariable(name)
    v === C_NULL && error("GAP variable $name not bound")
    return _GAP_TO_JULIA(v)
end

function hasproperty(::GlobalsType, name::Symbol)
    return _ValueGlobalVariable(name) !== C_NULL
end

function setproperty!(::GlobalsType, name::Symbol, val::Any)
    CanAssignGlobalVariable(name) || error("cannot assign to $name in GAP")
    tmp = (val === nothing) ? C_NULL : _JULIA_TO_GAP(val)
    _AssignGlobalVariable(name, tmp)
end

propertynames(::GlobalsType, private::Bool=false) = Vector{Symbol}(Globals.NamesGVars())

function replace_global!(name::Symbol, val::Any)
    n = GapObj(name)
    Wrappers.MakeReadWriteGlobal(n)
    setproperty!(Globals, name, val)
    Wrappers.MakeReadOnlyGlobal(n)
end

propertynames(r::GapObj, private::Bool=false) = Wrappers.IsRecord(r) ? Vector{Symbol}(Wrappers.RecNames(r)) : Vector{Symbol}()
