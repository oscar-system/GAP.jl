# We store C symbols obtained via dlsym in an array. The @csym macro
# returns an expression indexing the array (e.g. CLibGap._bindings[3]),
# which matches the corresponding name (e.g. CLibGap._symnames[3]). The
# index calculation is done at compile time, so at runtime only an
# array indexing operation must be performed.

module CLibGap
    using Libdl
    const _bindings = Vector{Ptr}()
    const _symnames = Vector{Symbol}()
    function _load(libgap_handle)
        for i in 1:length(_bindings)
            _bindings[i] = Libdl.dlsym(libgap_handle, _symnames[i])
        end
    end
end

module CJuliaInterface
    using Libdl
    const _bindings = Vector{Ptr}()
    const _symnames = Vector{Symbol}()
    function _load(JuliaInterface_handle)
        for i in 1:length(_bindings)
            _bindings[i] = Libdl.dlsym(JuliaInterface_handle, _symnames[i])
        end
    end
end

macro csym(libname, expr)
    if libname == :CJuliaInterface
        lib = CJuliaInterface
    elseif libname == :CLibGap
        lib = CLibGap
    end
    # Extract the C function name from `expr`.
    sym =
        if expr isa String
            Symbol(expr)
        elseif expr isa QuoteNode
            expr.value
        elseif expr isa Symbol
            expr
        else
            throw(ArgumentError("expression is not a symbol"))
        end
    # Have we already seen that symbol?
    if ! (sym in lib._symnames)
        # If no, add an entry to the end of _symnames/_bindings.
        push!(lib._symnames, sym)
        push!(lib._bindings, C_NULL)
        index = length(lib._symnames)
    else
        # If yes, return the index of the existing symbol.
        index = findfirst(s -> s == sym, lib._symnames)
    end
    # return an expression of the form mod._bindings[index].
    return :($(lib)._bindings[$(esc(index))])
end
