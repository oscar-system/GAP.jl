using Documenter, GAP, Markdown

abstract type ExternalReference <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{ExternalReference}) = 3.1  # After cross-references

function Documenter.Selectors.runner(::Type{ExternalReference}, doc::Documenter.Documents.Document)
    @info "ExternalReference: building external references."
    compute_external_references(doc)
end

function compute_external_references(doc::Documenter.Documents.Document)
    for (src, page) in doc.blueprint.pages
        empty!(page.globals.meta)
        for element in page.elements
            compute_external_reference(page.mapping[element], page, doc)
        end
    end
end

function compute_external_reference(elem, page, doc)
    Documenter.Documents.walk(page.globals.meta, elem) do link
        compute_external_reference(link, page.globals.meta, page, doc)
    end
end

function compute_external_reference(link, meta, page, doc)
    if isa(link, Markdown.Link) && startswith(link.url, "GAP_ref")
        @info "Computing external reference: $(link.url)."
        reference = match(r"GAP_ref\((.*)\)", link.url)
        if ! isnothing(reference) && length(reference.captures) == 1
            reference = string(reference.captures[1])
            key = split(reference, ":")
            if length(key) == 2
                key = GAP.julia_to_gap(string(key[2]))
                urls = GAP.Globals.MatchURLs(GAP.julia_to_gap(reference),
                           GAP.julia_to_gap("https://www.gap-system.org/Manuals/"))
                urls = GAP.Globals.Filtered(urls, x -> x[2] == key)
                if length(urls) == 1
                    link.url = String(urls[1][3])
                end
            end
        end
    end
    return true
end

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP); recursive = true)

makedocs(
    format = Documenter.HTML(),
    sitename = "GAP.jl",
    modules = [GAP],
    clean = true,
    doctest = true,
    doctestfilters = Regex[
      r"BitVector|BitArray\{1\}",
      r"Matrix\{Int64\}|Array\{Int64,2\}",
      r"Vector\{Any\}|Array\{Any,1\}",
      r"Vector\{Int64\}|Array\{Int64,1\}",
      r"Vector\{UInt8\}|Array\{UInt8,1\}",
    ],
    strict = false,
    checkdocs = :none,
    pages = ["index.md"],
)

deploydocs(repo = "github.com/oscar-system/GAP.jl.git", target = "build")
