using Documenter
using GAP

function build_JuliaInterface_manual()
  gapjl_path = abspath(@__DIR__, "..")
  mktempdir() do tmpdir
    GAP.create_gap_sh(tmpdir)
    gap_sh_path = joinpath(tmpdir, "gap.sh")
    cd(joinpath(gapjl_path, "pkg", "JuliaInterface")) do
      run(`$gap_sh_path -A --quitonbreak --norepl makedoc.g`)
    end
  end
end

function copy_JuliaInterface_manual()
  gapjl_path = normpath(@__DIR__, "..")
  src_dir = joinpath(gapjl_path, "pkg", "JuliaInterface", "doc")
  dst_dir = joinpath(gapjl_path, "docs", "src", "assets", "html", "JuliaInterface")

  # clear the destination directory first
  rm(dst_dir; recursive=true, force=true)
  
  mkpath(dst_dir)
  for file in readdir(src_dir; sort=false)
    if endswith(file, ".html") || endswith(file, ".css") || endswith(file, ".js")
      cp(joinpath(src_dir, file), joinpath(dst_dir, file))
    end
  end
end

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

## helper function that computes a "GAP documentation URL"
function compute_GAP_URL(url::String)
  startswith(url, "GAP_ref") || return nothing
  @info "Computing external reference: $(url)."
  reference = match(r"GAP_ref\((.*)\)", url)
  (! isnothing(reference) && length(reference.captures) == 1) || return nothing
  reference = string(reference.captures[1])
  key = split(reference, ":")
  length(key) == 2 || return nothing
  key = GapObj(string(key[2]))
  # Find all matches of `"<bookname>:<label>"`.
  urls = GAP.Globals.MatchURLs(GapObj(reference),
             GapObj("https://docs.gap-system.org/"))
  # Take only exact matches, this should be unique.
  urls = GAP.Globals.Filtered(urls, x -> x[2] == key)
  length(urls) == 1 || return nothing
  return String(urls[1][3])
end


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
  url = compute_GAP_URL(link.destination)
  if url !== nothing
    # Replace the URL in the link.
    link.destination = url
  end
  return true
end


## When executing our step, print an info line
## and call the function that does the work.
function Documenter.Selectors.runner(::Type{ExternalReference}, doc::Document)
    @info "ExternalReference: building external references."
    compute_external_references(doc)
end

build_JuliaInterface_manual()
copy_JuliaInterface_manual()

DocMeta.setdocmeta!(GAP, :DocTestSetup, :(using GAP, GAP.Random); recursive = true)

makedocs(
    sitename = "GAP.jl",
    modules = [GAP],
    doctest = false,
    doctestfilters = GAP.GAP_doctestfilters,
    pages = GAP.GAP_docs_pages,
)

deploydocs(
  repo = "github.com/oscar-system/GAP.jl.git",
  push_preview = true,
)
