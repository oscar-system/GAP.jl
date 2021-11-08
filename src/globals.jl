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

julia> GAP.Globals.Julia   # Julia objects can be values of GAP variables
Main

```
"""
const Globals = GlobalsType()

function getproperty(::GlobalsType, name::Symbol)
    v = _ValueGlobalVariable(name)
    if v === C_NULL
        error("GAP variable $name not bound")
    end
    return _GAP_TO_JULIA(v)
end

function hasproperty(::GlobalsType, name::Symbol)
    return _ValueGlobalVariable(name) !== C_NULL
end

function setproperty!(::GlobalsType, name::Symbol, val::Any)
    if !CanAssignGlobalVariable(name)
        error("cannot assing to $name in GAP")
    end
    tmp = (val === nothing) ? C_NULL : _JULIA_TO_GAP(val)
    _AssignGlobalVariable(name, tmp)
end

propertynames(::GlobalsType) = Vector{Symbol}(Globals.NamesGVars())
