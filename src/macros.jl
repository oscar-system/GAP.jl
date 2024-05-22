## convenience macros

"""
    @gap <expr>
    @gap(<expr>)

Execute <expr> directly in GAP, as if `GAP.evalstr("<expr>")` was called.
This can be used for creating GAP literals directly from Julia.

# Examples
```jldoctest
julia> @gap [1,2,3]
GAP: [ 1, 2, 3 ]

julia> @gap SymmetricGroup(3)
GAP: Sym( [ 1 .. 3 ] )

julia> @gap(SymmetricGroup)(3)
GAP: Sym( [ 1 .. 3 ] )

```

Note that the last two examples have a slight syntactical, and therefore also
a semantical difference. The first one executes the string `SymmetricGroup(3)`
directly inside GAP. The second example returns the function `SymmetricGroup`
via `@gap(SymmetricGroup)`, then calls that function with the argument `3`.

Due to Julia's way of handing over arguments into the code of macros,
not all expressions representing valid GAP code can be processed.
For example, the GAP syntax of permutations consisting of more than one cycle
cause problems, as well as the GAP syntax of non-dense lists.

```
julia> @gap (1,2,3)
GAP: (1,2,3)

julia> @gap (1,2)(3,4)
ERROR: LoadError: Error thrown by GAP: Error, no method found! For debugging hints type ?Recovery from NoMethodFound
[...]

julia> @gap [ 1,, 2 ]
ERROR: syntax: unexpected \",\"
[...]

```

Note also that a string argument gets evaluated with `GAP.evalstr`.

```jldoctest
julia> @gap \"\\\"abc\\\"\"
GAP: \"abc\"

julia> @gap \"[1,,2]\"
GAP: [ 1,, 2 ]

julia> @gap \"(1,2)(3,4)\"
GAP: (1,2)(3,4)

```
"""
macro gap(str)
    return :(evalstr($(string(str))))
end

export @gap

# Define a plain function that contains the code of the `@g_str` macro.
# Note that errors thrown by macros can apparently not be tested using
# `@test_throw`.
function gap_string_macro_helper(str::String)
    # We assume that `str` is the input of the `@g_str` macro;
    # more precisely, `str` is what arrives inside the code of the macro.
    # Note that here backslashes inside `str` are literally contained in `str`,
    # except for backslashes that escape doublequotes.
    # In order to get the intended meaning (as stated in the GAP manual section
    # "Special Characters"),
    # we escape doublequotes and leave the interpretation to `evalstr`.
    evl = evalstr("\"" * replace(str, "\"" => "\\\"") * "\"")
    evl === nothing && error("failed to convert to GapObj:\n $str")

    return evl
end

"""
    @g_str

Create a GAP string by typing `g"content"`.

# Examples
```jldoctest
julia> g"foo"
GAP: "foo"

julia> g"ab\\ncd\\\"ef\\\\gh"   # special characters are handled as in GAP
GAP: "ab\\ncd\\\"ef\\\\gh"

```

Due to Julia's way of handing over arguments into the code of macros,
not all strings representing valid GAP strings can be processed.

```jldoctest
julia> g"\\\\"
ERROR: Error thrown by GAP: Syntax error: String must end with " before end of file in stream:1
[...]

```

Conversely,
there are valid arguments for the macro that are not valid Julia strings.

```jldoctest
julia> g"\\c"
GAP: "\\c"

```
"""
macro g_str(str)
    return :(gap_string_macro_helper($str))
end

export @g_str

import MacroTools

"""
    @gapwrap

When applied to a method definition that involves access to entries of
`GAP.Globals`, this macro rewrites the code such that the relevant GAP
globals are cached, and need not be fetched again and again.

# Examples
```jldoctest
julia> @gapwrap isevenint(x) = GAP.Globals.IsEvenInt(x)::Bool;

julia> isevenint(1)
false

julia> isevenint(2)
true

```
"""
macro gapwrap(ex)
    # split the method definition
    def_dict = try
        MacroTools.splitdef(ex)
    catch
        error("@gapwrap must be applied to a method definition")
    end

    # take the body of the function
    body = def_dict[:body]

    # find, record and substitute all occurrences of GAP.Globals.*
    symdict = IdDict{Symbol,Symbol}()
    body = MacroTools.postwalk(body) do x
        MacroTools.@capture(x, GAP.Globals.sym_) || return x
        new_sym = get!(() -> gensym(sym), symdict, sym)
        return Expr(:ref, new_sym)
    end

    # modify the function body
    def_dict[:body] = Expr(
        :block,
        # first the location of the macro call
        __source__,
        # now the list of initializations ...
        (quote
            global $v
            if !isassigned($v)
                $v[] = GAP.Globals.$k
            end
         end for (k, v) in symdict)...,
        # ... then the original-with-substitutions body
        body,
    )

    # assemble the method definition again
    ex = MacroTools.combinedef(def_dict)

    return esc(Expr(
        :block,
        (:(@eval const $v = Ref{GapObj}()) for (k, v) in symdict)...,
        :(Base.@__doc__ $ex),
        ))
end

export @gapwrap

"""
    @gapattribute

This macro is intended to be applied to a method definition
for a unary function called `attr`, say,
where the argument has the type `T`, say,
the code contains exactly one call of the form `GAP.Globals.Something(X)`,
where `Something` is a GAP attribute such as `Centre` or `IsSolvableGroup`,
and `attr` returns the corresponding attribute value for its argument.

The macro defines three functions `attr`, `has_attr`, and `set_attr`, where
`attr` takes an argument of type `T` and returns what the given
method definition says,
`has_attr` takes an argument of type `T` and returns the result of
`GAP.Globals.HasSomething(X)` (which is either `true` or `false`),
`set_attr` takes an argument of type `T` and an object `obj` and
calls `GAP.Globals.SetSomething(X, obj)`.

In order to avoid runtime access via `GAP.Globals.Something` etc.,
the same modifications are applied in the construction of the three functions
that are applied by [`@gapwrap`](@ref).

The variables that are created by the macro belong to the Julia module
in whose scope the macro is called.

# Examples
```jldoctest
julia> @gapattribute isstrictlysortedlist(obj::GapObj) = GAP.Globals.IsSSortedList(obj)::Bool;

julia> l = GapObj([ 1, 3, 7 ]);

julia> has_isstrictlysortedlist( l )
false

julia> isstrictlysortedlist( l )
true

julia> has_isstrictlysortedlist( l )
true

julia> l = GapObj([ 1, 3, 7 ]);

julia> has_isstrictlysortedlist( l )
false

julia> set_isstrictlysortedlist( l, true )

julia> has_isstrictlysortedlist( l )
true

julia> isstrictlysortedlist( l )
true

```
"""
macro gapattribute(ex)
    def_dict = try
        MacroTools.splitdef(ex)
    catch
        error("@gapattribute must be applied to a method definition")
    end

    # The method must have exactly one argument.
    length(def_dict[:args]) == 1 || error("the method must have exactly one argument")

    # take the body of the function
    body = def_dict[:body]

    # Find the (unique) occurrence of GAP.Globals.<name>(<arg>),
    # and record <name> and <arg>.
    fun_arg = Set{Tuple{Symbol,Any}}()
    MacroTools.postwalk(body) do x
        MacroTools.@capture(x, GAP.Globals.sym_(arg_)) || return x
        push!(fun_arg, (sym, arg))
        return x
    end
    length(fun_arg) == 1 || error("there must be a unique call to a function in GAP.Globals")
    pair = pop!(fun_arg)
    gapname = string(pair[1])
    gaparg = pair[2]

    # Define the function names on the GAP side ...
    gaptester = Symbol("Has" * gapname)
    gapsetter = Symbol("Set" * gapname)

    # ... and on the Julia side.
    julianame = string(def_dict[:name])
    juliaarg = def_dict[:args][1]
    testername = Symbol("has_" * julianame)
    settername = Symbol("set_" * julianame)

    # assemble everything
    result = quote
        Base.@__doc__ GAP.@gapwrap $ex

        """
            $($testername)(x)

        Return `true` if the value for `$($julianame)(x)` has already been computed.
        """
        GAP.@gapwrap $testername($juliaarg) = GAP.Globals.$gaptester($gaparg)::Bool

        """
            $($settername)(x, v)

        Set the value for `$($julianame)(x)` to `v` if it has't been
        set already.
        """
        GAP.@gapwrap $settername($juliaarg,v) = GAP.Globals.$gapsetter($gaparg,v)::Nothing
    end

    # ensure correct line numbers are used on all three methods, so that
    # e.g. @less, @edit etc. work for them
    Meta.replace_sourceloc!(__source__, result)

    # we must prevent Julia from applying gensym to all locals, as these
    # substitutions do not get applied to the quoted part of the new body,
    # leading to trouble if the wrapped function has arguments (as the
    # argument names will be replaced, but not their uses in the quoted part
    return esc(result)
end

export @gapattribute



"""
    @wrap funcdecl

When applied to a function declaration of the form `NAME(a::T)` or
`NAME(a::T)::S`, this macro generates a function which behaves equivalently to
`NAME(a::T) = GAP.Globals.NAME(a)` resp. `NAME(a::T) = GAP.Globals.NAME(a)::S`,
assuming that `GAP.Globals.NAME` references a GAP function. Function declarations
with more than one argument or zero arguments are also supported.

However, the generated function actually caches the GAP object `GAP.Globals.NAME`.
This minimizes the call overhead. So @wrap typically is used to provide an optimized
way to call certain GAP functions.

If an argument is annotated as `::GapObj`, the resulting function accepts arguments
of any type and wraps them in `GapObj(...)` before passing them to the GAP function.

Another use case for this macro is to improve type stability of code calling into
GAP, via the type annotations for the arguments and return value contained in the
function declaration.

Be advised, though, that if the value of `GAP.Globals.NAME` is changed later on,
the function generated by this macro will not be updated, i.e., it will still
reference the original GAP object.

# Examples
```jldoctest
julia> GAP.@wrap Jacobi(x::GapInt, y::GapInt)::Int
Jacobi (generic function with 1 method)

julia> Jacobi(11,35)
1

julia> GAP.@wrap IsString(x::GapObj)::Bool
IsString (generic function with 1 method)

julia> IsString("abc")
true
```
"""
macro wrap(ex)
    if ex.head == :(::)
        length(ex.args) == 2 || error("unexpected return type annotation")
        retval = ex.args[2]
        ex = ex.args[1]
    else
        retval = :Any
    end
    ex.head == :call || error("unexpected input for macro @wrap")
    name = ex.args[1]
    newsym = gensym(name)

    fullargs = ex.args[2:length(ex.args)]

    # splits the arguments with type annotations into expressions for the lhs and rhs
    # of the call of the form `func(args) = GAP.Globals.func(args)`:
    # - type annotations have to be removed for the rhs
    # - if the type annotation is `GapObj`, the rhs has to be wrapped in `GAP.GapObj(...)` and the lhs has no type annotation
    tempargs = [
        begin
            if x isa Symbol
                (x, x)
            elseif x.head == :(::) && length(x.args) == 2
                var = x.args[1]
                typeannot = x.args[2]
                if typeannot in [:GapObj, :(GAP.GapObj)]
                    (var, :(GAP.GapObj($var)::GAP.GapObj))
                elseif typeannot == :(GAP.Obj)
                    (var, :(GAP.Obj($var)::GAP.Obj))
                elseif typeannot in [:GapInt, :(GAP.GapInt)]
                    (var, :(GAP.GapInt($var)::GAP.GapInt))
                else
                    (x, var)
                end
            else
                error("unknown argument syntax around `$x`")
            end
        end for x in fullargs
    ]
    lhsargs = map(first, tempargs)
    rhsargs = map(last, tempargs)
    
    # the "outer" part of the body
    body = MacroTools.@qq begin
               global $newsym
               if !isassigned($newsym)
                   $newsym[] = GAP.Globals.$name::GapObj
               end
               return $newsym[]($(rhsargs...))::$retval
           end


    return esc(MacroTools.@qq begin
       @eval const $newsym = Ref{GapObj}()
       Base.@__doc__ $(Expr(:call, name, lhsargs...)) = $body
    end)
end
