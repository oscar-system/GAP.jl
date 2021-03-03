import REPL.REPLCompletions: completions

## These two functions are used on the GAP side.

"""
    get_symbols_in_module(m::Module) :: Array{Symbol,1}

Return all symbols in the module `m`.
This is used in the GAP function `ImportJuliaModuleIntoGAP`.
"""
function get_symbols_in_module(m::Module)
    name = string(nameof(m))
    list = completions(name * ".", length(name) + 1)[1]
    list = [Symbol(x.mod) for x in list]
    list = filter(i -> isdefined(m, i), list)
    return list
end

"""
    call_with_catch( juliafunc, arguments )

Return a tuple `( ok, val )`
where `ok` is either `true`, meaning that calling the function `juliafunc`
with `arguments` returns the value `val`,
or `false`, meaning that the function call runs into an error;
in the latter case, `val` is set to the string of the error message.

# Examples
```jldoctest
julia> GAP.call_with_catch( sqrt, 2 )
(true, 1.4142135623730951)

julia> GAP.call_with_catch( sqrt, -2 )
(false, "DomainError(-2.0, \\"sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).\\")")

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
    kwarg_wrapper(func, args::Array{T1,1}, kwargs::Dict{Symbol,T2}) where {T1, T2}

Call the function `func` with arguments `args` and keyword arguments
given by the keys and values of `kwargs`.

This function is used on the GAP side, in calls of Julia functions that
require keyword arguments.
Note that `jl_call` and `Core._apply` do not support keyword arguments.

# Examples
```jldoctest
julia> range( 2, length = 5, step = 2 )
2:2:10

julia> GAP.kwarg_wrapper( range, [ 2 ], Dict( :length => 5, :step => 2 ) )
2:2:10

```
"""
function kwarg_wrapper(func, args::Array{T1,1}, kwargs::Dict{Symbol,T2}) where {T1,T2}
    func = UnwrapJuliaFunc(func)
    return func(args...; [k => kwargs[k] for k in keys(kwargs)]...)
end

## convenience function

function Display(x::GapObj)
    print(AbstractString(Globals.StringDisplayObj(x)))
end
