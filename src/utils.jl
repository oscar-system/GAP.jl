import REPL.REPLCompletions: completions
import Base: show

## These two functions are used on the GAP side.

"""
    get_symbols_in_module(module_t::Module) :: Array{Symbol,1}

Return all symbols in the module `module_t`.
This is used in the GAP function `ImportJuliaModuleIntoGAP`.
"""
function get_symbols_in_module(module_t)
    module_name = string(nameof(module_t))
    string_list = completions( module_name * ".", length( module_name ) + 1 )[1]
    string_list = [ x.mod for x in string_list ]
    list = [ Symbol(x) for x in string_list ]
    list = filter(i->isdefined(module_t,i),list)
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
function call_with_catch( juliafunc, arguments )
    try
      res = Core._apply( juliafunc, arguments )
      return ( true, res )
    catch e
      return ( false, string( e ) )
    end
end


## convenience function

function Display(x::GapObj)
    ## FIXME: Get rid of this horrible hack
    ##        once GAP offers a consistent
    ##        DisplayString function
    local_var = "julia_gap_display_tmp"
    AssignGlobalVariable(local_var,x)
    xx = EvalStringEx("Display($local_var);")[1]
    if xx[1] == true
        println(GAP.gap_to_julia(AbstractString, xx[5]))
    else
        error("variable was not correctly evaluated")
    end
end
