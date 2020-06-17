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

```jldoctest
julia> @gap (1,2,3)
GAP: (1,2,3)

julia> @gap (1,2)(3,4)
ERROR: LoadError: Error thrown by GAP: Error, no method found! For debugging hints type ?Recovery from NoMethodFound
[...]

julia> @gap [ 1,, 2 ]
ERROR: syntax: unexpected ","
[...]

```

Note also that a string argument gets evaluated with `GAP.evalstr`.

```jldoctest
julia> @gap "\\"abc\\""
GAP: "abc"

julia> @gap "[1,,2]"
GAP: [ 1,, 2 ]

julia> @gap "(1,2)(3,4)"
GAP: (1,2)(3,4)

```
"""
macro gap(str)
    return evalstr(string(str))
end

export @gap


"""
    @g_str

Create a GAP string by typing `g"content"`.

# Examples
```jldoctest
julia> g"foo"
GAP: "foo"
```
"""
macro g_str(str)
    return julia_to_gap(str)
end

export @g_str
