## enable access to GAP help system from Julia

function GAP_help_string(topic::String, onlyexact::Bool = false)
    return GAP.gap_to_julia(GAP.Globals.HelpString(GAP.julia_to_gap(topic), onlyexact))
end

"""
    show_GAP_help(topic::String, onlyexact::Bool = false)

Print the information from the GAP help system about `topic` to the screen.
If `onlyexact` is `true` then only exact matches are shown,
otherwise all matches.
For example, `GAP.show_GAP_help("Size")` shows also documentation for
`SizeScreen` and `SizesPerfectGroups`,
whereas `GAP.show_GAP_help("Size", true)` shows only documentation for
`Size`.

For the variant showing all matches,
one can also enter `?GAP.Globals.Size` at the Julia prompt
instead of calling `show_GAP_help`.

# Examples
```
julia> GAP.show_GAP_help( "Size" )
[...]  # more than 50 entries from GAP manuals

hepl?> GAP.Globals.Size
[...]  # the same

julia> GAP.show_GAP_help( "Size", true )
[...]  # about 15 entries from GAP manuals

```
"""
function show_GAP_help(topic::String, onlyexact::Bool = false)
    print(GAP_help_string(topic, onlyexact))
end

## If one enters `?GAP.Globals.Size` then the following dispatch mechanism
## does the job.

import Base.Docs: Binding, getdoc, docstr

## Create a helper type that gets returned by Binding
struct GAPHelpType
    name::Symbol
end

Base.Docs.Binding(x::GlobalsType, name::Symbol) = GAPHelpType(name)

function Base.Docs.doc(x::GAPHelpType, typesig::Type = Union{})
    return Text(GAP_help_string(string(x.name)))
end

## Set getdoc for GlobalsType to nothing,
## so it dispatches on the Binding.
Base.Docs.getdoc(x::GlobalsType) = nothing

## If one enters `?x` for a variable `x` pointing to a `GapObj`
## then the following gets called.
## (Note that this feature works for Julia objects as well.)
function Base.Docs.getdoc(x::GapObj)
    if Globals.HasNameFunction(x)
      return Text(GAP_help_string(gap_to_julia(Globals.NameFunction(x))))
    else
      return nothing
    end
end
