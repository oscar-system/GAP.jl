import REPL.REPLCompletions: completions

## These functions are used on the GAP side.

# a helper function, not to be documented
function _setglobal(M::Module, name::Symbol, val::Any)
  @static if isdefined(Core, :setglobal!)
    # `setglobal!` is available in Julia 1.9.
    Core.eval(M, Expr(:global, name)) # see https://github.com/JuliaLang/julia/pull/54678
    return invokelatest(Core.setglobal!, M, name, val)
  else
    # `jl_set_global` is available up to Julia 1.8.
    ccall(:jl_set_global, Cvoid, (Any, Any, Any), M, name, val)
    return val
  end
end

"""
    get_symbols_in_module(m::Module) :: Vector{Symbol}

Return all symbols in the module `m`.
This is used in a GAP method for `RecNames`.
"""
function get_symbols_in_module(m::Module)
    name = string(nameof(m))::String
    list = completions(name * ".", length(name) + 1)[1]
    list = [Symbol(x.mod) for x in list]
    list = filter(i -> isdefined(m, i), list)
    return list
end

"""
    call_with_catch(juliafunc, arguments)

Return a tuple `(ok, val)`
where `ok` is either `true`, meaning that calling the function `juliafunc`
with `arguments` returns the value `val`,
or `false`, meaning that the function call runs into an error;
in the latter case, `val` is set to the string of the error message.

# Examples
```jldoctest
julia> GAP.call_with_catch(sqrt, 2)
(true, 1.4142135623730951)

julia> flag, res = GAP.call_with_catch(sqrt, -2);

julia> flag
false

julia> startswith(res, "DomainError")
true

```
"""
function call_with_catch(juliafunc, arguments)
    try
        res = Core._apply(juliafunc, arguments)
        return (true, res)
    catch e
        return (false, string(e))
    end
end

"""
    kwarg_wrapper(func, args::Vector{T1}, kwargs::Dict{Symbol,T2}) where {T1, T2}

Call the function `func` with arguments `args` and keyword arguments
given by the keys and values of `kwargs`.

This function is used on the GAP side, in calls of Julia functions that
require keyword arguments.
Note that `jl_call` and `Core._apply` do not support keyword arguments.

# Examples
```jldoctest
julia> range(2, length = 5, step = 2)
2:2:10

julia> GAP.kwarg_wrapper(range, [2], Dict(:length => 5, :step => 2))
2:2:10

```
"""
function kwarg_wrapper(func, args::Vector{T1}, kwargs::Dict{Symbol,T2}) where {T1,T2}
    func = UnwrapJuliaFunc(func)
    return func(args...; [k => kwargs[k] for k in keys(kwargs)]...)
end

## convenience function

function Display(x::GapObj)
    print(String(Wrappers.StringDisplayObj(x)))
end

function Base.functionloc(f::GapObj)
    GAP.Globals.IsFunction(f) || throw(ArgumentError("`f` must be GAP function"))
    file = GAP.Globals.FilenameFunc(f)::GapObj
    if file == GAP.Globals.fail
        error("could not determine file of GAP function definition")
    end
    ln = GAP.Globals.StartlineFunc(f)::GAP.Obj
    if !isa(ln, Int)
        error("could not determine line of GAP function definition")
    end
    return (String(file), ln)
end

import Scratch: get_scratch!

"""
    get_scratch_helper!(key)

Return the path of a Julia scratchspace with name `key`.
This scratchspace gets created if it did not exist already.
The scratchspace may be removed by Julia as soon as the Julia package GAP.jl
gets uninstalled.
"""
get_scratch_helper!(key::String) = get_scratch!(GAP, key)

# Allow `InteractiveUtils.edit(GAP.Globals.Group)` and similar for any global
# function. Not (yet?) useful for GAP operations, but better than nothing.
import InteractiveUtils: edit
edit(m::GapObj) = edit(functionloc(m)...)
