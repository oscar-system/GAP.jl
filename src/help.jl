## enable access to GAP help system from Julia

function GAP_help_string(topic::String, onlyexact::Bool = false)
    return GAP.gap_to_julia(GAP.Globals.HelpString(GAP.julia_to_gap(topic), onlyexact))
end

function show_GAP_help(topic::String, onlyexact::Bool = false)
    print(GAP_help_string(topic, onlyexact))
end

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
Base.Docs.getdoc(x::GapObj) = Text(GAP_help_string(gap_to_julia(Globals.NameFunction(x))))
