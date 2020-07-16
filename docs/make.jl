using Documenter, GAP, Markdown

## The following code inserts a step into the list of tasks
## that are performed by Documenter.jl's function `makedocs`.
## The idea is to encode external references to GAP manuals
## by strings of the form `"GAP_ref(<bookname>:<label>)"`
## in the source files, and to compute the corresponding URLs
## in the manuals available at `https://www.gap-system.org/Manuals/`
## when `makedocs` creates GAP.jl's documentation.
## (Note that these URLs may change when new GAP versions get released,
## thus one does not want to update them by hand.)
##
## The steps for `makedocs` are given by the subtypes of
## `Documenter.Builder.DocumentPipeline`,
## they get executed in the order defined by the values (floats)
## of the function `Documenter.Selectors.order` for these subtypes,
## and executing the step for the subtype `T` means to call
## `Documenter.Selectors.runner` with `T` and the document object.
##
## The code was adapted from the package
## https://github.com/ali-ramadhan/DocumenterBibliographyTest.jl,
## the hint to use this approach came up in the discussion of
## https://github.com/JuliaDocs/Documenter.jl/issues/1343.

## Declare a new subtype for our step,
## the evaluation of external references.
abstract type ExternalReference <: Documenter.Builder.DocumentPipeline end

## Execute our step after the computation of cross-references (3.0)
## and before the check of the document (4.0).
Documenter.Selectors.order(::Type{ExternalReference}) = 3.1

## When executing our step, print an info line
## and call the function that does the work.
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
    # Do something only if the current element has the type `Markdown.Link`.
    if isa(link, Markdown.Link) && startswith(link.url, "GAP_ref")
        @info "Computing external reference: $(link.url)."
        reference = match(r"GAP_ref\((.*)\)", link.url)
        if ! isnothing(reference) && length(reference.captures) == 1
            reference = string(reference.captures[1])
            key = split(reference, ":")
            if length(key) == 2
                key = GAP.julia_to_gap(string(key[2]))
                # Find all matches of `"<bookname>:<label>"`.
                urls = GAP.Globals.MatchURLs(GAP.julia_to_gap(reference),
                           GAP.julia_to_gap("https://www.gap-system.org/Manuals/"))
                # Take only exact matches, this should be unique.
                urls = GAP.Globals.Filtered(urls, x -> x[2] == key)
                if length(urls) == 1
                    # Replace the URL in the link.
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
