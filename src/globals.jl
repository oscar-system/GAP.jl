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

propertynames(::GlobalsType) = Vector{Symbol}(Globals.NamesGVars())


# HACK to get tab completion to work for GAP globals accessed via GAP.Globals;
# e.g. if the REPL already shows `GAP.Globals.MTX.Is` and the user presses
# TAB, they should be shown a list of members of the GAP global variable `MTX`
# (which is a record) starting with `Is`. The easy part for supporting this is
# to implement `propertynames` for `GapObj` (at least those which are GAP
# records). Unfortunately that's not quite enough; we also have add methods
# for the `get_value` method below
import REPL.REPLCompletions: get_value
function get_value(sym::Symbol, ::GAP.GlobalsType)
    v = _ValueGlobalVariable(sym)
    v === C_NULL && return (nothing, false)
    return (_GAP_TO_JULIA(v), true)
end
get_value(sym::QuoteNode, fn::GAP.GlobalsType) = get_value(sym.value, fn)

propertynames(r::GapObj) = Wrappers.IsRecord(r) ? Vector{Symbol}(Wrappers.RecNames(r)) : Vector{Symbol}()
