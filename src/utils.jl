import REPL.REPLCompletions: completions
import Base: show

## These two functions are used on the GAP side.

"""
    get_symbols_in_module(module_t::Module) :: Array{Symbol,1}

> Returns all symbols in the module `module_t`.
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

> Returns a tuple `( ok, val )`
> where `ok` is either `true`, meaning that calling the function `juliafunc`
> with `arguments` returns the value `val`,
> or `false`, meaning that the function call runs into an error;
> in the latter case, `val` is set to the string of the error message.
"""
function call_with_catch( juliafunc, arguments )
    try
      res = Core._apply( juliafunc, arguments )
      return ( true, res )
    catch e
      return ( false, string( e ) )
    end
end
