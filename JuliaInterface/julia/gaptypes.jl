#############################################################################
##
##  JuliaInterface package
##
##  Copyright 2017
##    Thomas Breuer, RWTH Aachen University
##    Sebastian Gutsche, Siegen University
##
#############################################################################

module GAPUtils

import REPL.REPLCompletions: completions
import Base: show

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

export call_with_catch

end

#########################################################################

module GAP

import Base: getproperty

import Main.ForeignGAP: MPtr

export GapFunc


"""
    GapFunc

> Holds a pointer to a function in the GAP CAS.
> Such functions can be called on GapObj's.
"""
struct GapFunc
    ptr::MPtr
end

"""
    GapFEE

> Wraps a pointer to a GAP FFE immediate object
> This type is defined in the JuliaInterface C code.
"""

"""
    (func::GapFunc)(args...)

> This function makes it possible to call GapFunc objects on
> GapObj objects. It also makes sure that the resulting object
> is a GapObj holding a pointer to the result.
> There is no argument number checking here, all checks on the arguments
> (except that they are GapObj) is done by GAP itself.
"""
function(func::GapFunc)(args...)
    return ccall(:call_gap_func, Any, (MPtr,Any), func.ptr, args)
end

struct GAPFuncsType
    funcs::Dict{Symbol,GapFunc}
end

Base.show(io::IO,::GAPFuncsType) = Base.show(io,"GAP function object")

GAPFuncs = GAPFuncsType(Dict{Symbol,GapFunc}())

function getproperty(funcobj::GAPFuncsType,name::Symbol)
    cache = getfield(funcobj,:funcs)
    if haskey(cache,name)
        return cache[name]
    end
    name_string = string(name)
    variable = ccall(:GAP_ValueGlobalVariable,MPtr,(Ptr{UInt8},),name_string)
    current_func = GapFunc(variable)
    cache[name] = current_func
    return current_func
end


end
