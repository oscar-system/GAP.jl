"""
    @gap <obj>
    @gap(<obj>)

Executes <obj> directly in GAP, as if `GAP.EvalString("<obj>")` was called.
Can be used for creating GAP literals directly from Julia.

    julia> @gap (1,2,3)
    GAP: (1,2,3)
    julia> @gap SymmetricGroup(3)
    GAP: SymmetricGroup( [ 1 .. 3 ] )
    julia> @gap(SymmetricGroup)(3)
    GAP: SymmetricGroup( [ 1 .. 3 ] )

Note that the last two examples have a slight syntactical, and therefore also
a semantical difference. The first one executes the string `SymmetricGroup(3)`
directly inside GAP. The second example returns the function `SymmetricGroup`
via `@gap(SymmetricGroup)`, then calls that function with the argument `3`.
"""
macro gap(str)
    return EvalString(string(str))
end

export @gap


"""
    macro g_str

Allows to create a GAP string by typing g"content".

    julia> g"foo"
    GAP: "foo"
"""
macro g_str(str)
    return julia_to_gap(str)
end

export @g_str
