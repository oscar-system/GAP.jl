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
    return evalstr(string(str))
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
ERROR: LoadError: Error thrown by GAP: Syntax error: String must end with " before end of file in stream:1
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
    return gap_string_macro_helper(str)
end

export @g_str

import MacroTools

"""
    @gapwrap

When applied to a method definition that involves access to entries of
`GAP.Globals`, this macro rewrites the code (using `@generated`)
such that the relevant entries are cached at compile time,
and need not be fetched again and again at runtime.

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
        return Expr(:$, new_sym)
    end

    # now quote the old body, and prepend a list of assignments of
    # this form:
    #   ##XYZ##123 = GAP.Globals.XYZ
    def_dict[:body] = Expr(
        :block,
        # first the location of the macro call
        __source__,
        # now the list of initializations ...
        (:(local $v = GAP.Globals.$k::GapObj) for (k, v) in symdict)...,
        # ... then the quoted original-with-substitutions body
        Meta.quot(body),
    )

    # assemble the method definition again
    ex = MacroTools.combinedef(def_dict)
    result = :(@generated $ex)

    # we must prevent Julia from applying gensym to all locals, as these
    # substitutions do not get applied to the quoted part of the new body,
    # leading to trouble if the wrapped function has arguments (as the
    # argument names will be replaced, but not their uses in the quoted part
    return esc(result)
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

The macro defines three functions `attr`, `hasattr`, and `setattr`, where
`attr` takes an argument of type `T` and returns what the given
method definition says,
`hasattr` takes an argument of type `T` and returns the result of
`GAP.Globals.HasSomething(X)` (which is either `true` or `false`),
`setattr` takes an argument of type `T` and an object `obj` and
calls `GAP.Globals.SetSomething(X, obj)`.

In order to avoid runtime access via `GAP.Globals.Something` etc.,
the same modifications are applied in the construction of the three functions
that are applied by [`@gapwrap`](@ref).

The variables that are created by the macro belong to the Julia module
in whose scope the macro is called.

# Examples
```jldoctest
julia> @gapattribute isstrictlysortedlist(obj::GAP.GapObj) = GAP.Globals.IsSSortedList(obj)::Bool;

julia> l = GAP.evalstr( "[ 1, 3, 7 ]" );

julia> hasisstrictlysortedlist( l )
false

julia> isstrictlysortedlist( l )
true

julia> hasisstrictlysortedlist( l )
true

julia> l = GAP.evalstr( "[ 1, 3, 7 ]" );

julia> hasisstrictlysortedlist( l )
false

julia> setisstrictlysortedlist( l, true )

julia> hasisstrictlysortedlist( l )
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
    testername = Symbol("has" * julianame)
    settername = Symbol("set" * julianame)

    # assemble everything
    result = quote
        Base.@__doc__ @gapwrap $ex

        """
            $($testername)(x)

        Return `true` if the value for `$($julianame)(x)` has already been computed.
        """
        @gapwrap $testername(x) = GAP.Globals.$gaptester(x)::Bool

        """
            $($settername)(x, v)

        Set the value for `$($julianame)(x)` to `v` if it has't been
        set already.
        """
        @gapwrap $settername(x,v) = GAP.Globals.$gapsetter(x,v)::Nothing
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
