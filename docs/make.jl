using Documenter
using GAP
using GAP.Markdown

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

## Declare a new subtype for our step,
## the evaluation of external references.
abstract type ExternalReference <: Documenter.Builder.DocumentPipeline end

## Distinguish different versions of Documenter.jl.
if isdefined(Documenter, :Document)
  # version at least 1.0
  # The code was adapted from `expand_citations`
  # in DocumenterCitations.jl/src/citations.jl.
  Document = Documenter.Document

  # Execute our step before the computation of cross-references (3.0)
  # because otherwise the syntax of external references leads to errors.
  Documenter.Selectors.order(::Type{ExternalReference}) = 2.99

  function compute_external_references(doc::Document)
    for (src, page) in doc.blueprint.pages
      @debug "ExternalReference: compute for entries in $(src)"
      empty!(page.globals.meta)
      compute_external_reference(doc, page, page.mdast)
    end
  end

  function compute_external_reference(doc::Document, page, mdast::Documenter.MarkdownAST.Node)
    for node in Documenter.AbstractTrees.PreOrderDFS(mdast)
      if node.element isa Documenter.DocsNode
        # The docstring AST trees are not part of the tree of the page, so
        # we need to expand them explicitly
        for (docstr, meta) in zip(node.element.mdasts, node.element.metas)
          compute_external_reference(doc, page, docstr)
        end
      elseif node.element isa Documenter.MarkdownAST.Link
        compute_external_reference(node, page.globals.meta, page, doc)
      end
    end
  end

  function compute_external_reference(node::Documenter.MarkdownAST.Node, meta, page, doc)
    # Do something only if the current element is a `MarkdownAST.Link`.
    link = node.element
    isa(link, Documenter.MarkdownAST.Link) || return true
    url = link.destination
    startswith(url, "GAP_ref") || return true
    @info "Computing external reference: $(url)."
    reference = match(r"GAP_ref\((.*)\)", url)
    (! isnothing(reference) && length(reference.captures) == 1) || return true
    reference = string(reference.captures[1])
    key = split(reference, ":")
    length(key) == 2 || return true
    key = GapObj(string(key[2]))
    # Find all matches of `"<bookname>:<label>"`.
    urls = GAP.Globals.MatchURLs(GapObj(reference),
               GapObj("https://www.gap-system.org/Manuals/"))
    # Take only exact matches, this should be unique.
    urls = GAP.Globals.Filtered(urls, x -> x[2] == key)
    if length(urls) == 1
      # Replace the URL in the link.
      link.destination = String(urls[1][3])
    end
    return true
  end
else
  # old version
  # The code was adapted from the package
  # https://github.com/ali-ramadhan/DocumenterBibliographyTest.jl,
  # the hint to use this approach came up in the discussion of
  # https://github.com/JuliaDocs/Documenter.jl/issues/1343.
  Document = Documenter.Documents.Document

  # Execute our step after the computation of cross-references (3.0)
  # and before the check of the document (4.0).
  Documenter.Selectors.order(::Type{ExternalReference}) = 3.1

  function compute_external_references(doc::Document)
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
                key = GapObj(string(key[2]))
                # Find all matches of `"<bookname>:<label>"`.
                urls = GAP.Globals.MatchURLs(GapObj(reference),
                           GapObj("https://www.gap-system.org/Manuals/"))
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
end

## When executing our step, print an info line
## and call the function that does the work.
function Documenter.Selectors.runner(::Type{ExternalReference}, doc::Document)
    @info "ExternalReference: building external references."
    compute_external_references(doc)
end

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP, GAP.Random); recursive = true)

makedocs(
    sitename = "GAP.jl",
    modules = [GAP],
    doctest = true,
    doctestfilters = GAP.GAP_doctestfilters,
    pages = GAP.GAP_docs_pages,
)

deploydocs(repo = "github.com/oscar-system/GAP.jl.git")
