## enable access to GAP help system from Julia

using REPL

function gap_help_string(topic::String, onlyexact::Bool = false,
    term::REPL.Terminals.TTYTerminal = REPL.TerminalMenus.terminal)
    # Let GAP collect the information.
    info = Globals.HELP_Info(julia_to_gap(topic), onlyexact)

    if Globals.IsRecord(info)
        len = length(info.entries)
        if len == 1
            # If there is a unique match then just return it.
            choice = 1
        else
            # If there are several matches then try to present a menu.
            # (This does not work in Jupyter notebooks.)
            options = [gap_to_julia(x) for x in gap_to_julia(info.menu)]
            try
                pagesize = displaysize(Base.stdout)[1]-2
                choice = REPL.TerminalMenus.request(
                    term,
                    "Choose an entry (out of $len) to view, 'q' for none:",
                    REPL.TerminalMenus.RadioMenu(options, pagesize = pagesize))
                if choice == -1
                    # canceled
                    return ""
                end
            catch e
                # show *all* help entries
                return gap_to_julia(Globals.HelpString(julia_to_gap(topic), onlyexact))
            end
        end
        return gap_to_julia(Globals.ComposedHelpString(info.entries[choice]))
    else
        return gap_to_julia(Globals.HelpStringInner(info))
    end
end

"""
    show_gap_help(topic::String, onlyexact::Bool = false)

Print the information from the GAP help system about `topic` to the screen.
If `onlyexact` is `true` then only exact matches are shown,
otherwise all matches.
For example, `GAP.show_gap_help("Size")` shows also documentation for
`SizeScreen` and `SizesPerfectGroups`,
whereas `GAP.show_gap_help("Size", true)` shows only documentation for
`Size`.

For the variant showing all matches,
one can also enter `?GAP.Globals.Size` at the Julia prompt
instead of calling `show_gap_help`.

# Examples
```
julia> GAP.show_gap_help( "Size" )
[...]  # more than 50 entries from GAP manuals

help?> GAP.Globals.Size
[...]  # the same

julia> GAP.show_gap_help( "Size", true )
[...]  # about 15 entries from GAP manuals

```
"""
function show_gap_help(topic::String, onlyexact::Bool = false)
    print(gap_help_string(topic, onlyexact))
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
    return Text(gap_help_string(string(x.name)))
end

## Set getdoc for GlobalsType to nothing,
## so it dispatches on the Binding.
Base.Docs.getdoc(x::GlobalsType) = nothing

## If one enters `?x` for a variable `x` pointing to a `GapObj`
## then the following gets called.
## (Note that this feature works for Julia objects as well.)
function Base.Docs.getdoc(x::GapObj)
    if Globals.HasNameFunction(x)
      return Text(gap_help_string(gap_to_julia(Globals.NameFunction(x))))
    else
      return nothing
    end
end

## enable access to Julia's help system from GAP
function julia_help_string(obj)
    doc = Base.Docs.doc(obj)
    io = IOBuffer()
    ioc = IOContext(io, :color => true)
    if ! isempty(doc.content)
      hr = Markdown.HorizontalRule()
      n = Markdown.cols(io)
      doc_found = ! isa(doc.content[1], Markdown.Paragraph)
      for md in doc.content[1:end-1]
        Markdown.term(ioc, md, n)
        print(ioc, "\n\n")
        if doc_found
          Markdown.term(ioc, hr, n)
          print(ioc, "\n\n")
        end
      end
      Markdown.term(ioc, doc.content[end], n)
      println(ioc)
    end
    return String(take!(io))
end
