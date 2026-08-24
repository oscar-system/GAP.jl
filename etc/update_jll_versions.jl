#
# This script updates the `GAP*_jll` entries in the `[compat]` section of
# Project.toml to match a given GAP release. Run it after `update_artifacts.jl`.
#
# Usage:
#
#     julia --project=etc etc/update_jll_versions.jl 4.16.1
#     julia --project=etc etc/update_jll_versions.jl https://.../package-infos.json.gz
#     julia --project=etc etc/update_jll_versions.jl local/path/package-infos.json --write
#
# Options:
#
#     --write             apply the changes (default is a dry run)
#     --update-registry   refresh the package registries first
#     --gap-version=X.Y.Z GAP version, if it cannot be derived from the argument
#
# A `GAP_pkg_X_jll` must be built from the *same* upstream version of package X
# that Artifacts.toml ships, because `setup_overrides` in src/GAP_pkg.jl grafts
# the JLL's binaries onto the artifact's source tree. So the target version is
# taken from `package-infos.json`, and the registry merely decides which build
# of it to pin.
#

include("pkginfos.jl")
import Pkg
using Pkg.Registry: reachable_registries, registry_info
import GZip
import JSON

const PKG_PREFIX = "GAP_pkg_"
const JLL_SUFFIX = "_jll"

# JuliaInterface is not a package distributed with GAP: it lives in pkg/ of this
# very repository, so its JLL version tracks GAP.jl's own version and is pinned
# exactly (see .github/workflows/treehash.yml).
const JULIAINTERFACE = "GAP_pkg_juliainterface_jll"

#
# Version encodings
#
# GAP itself (GAP_jll, GAP_lib_jll) uses `X.Y.Z -> X00.Y00.Z00`, see
# Yggdrasil/G/GAP/build_tarballs.jl.
#
# GAP packages use `offset_version` from Yggdrasil/G/GAP_pkg/common.jl, which
# combines the upstream version `a.b.c` with a recipe-local rebuild `offset`:
#
#     major = 100a + offset.major
#     minor = 10000b + 100c + offset.minor
#     patch = offset.patch
#
# We do not know the offsets, so we invert the encoding instead and keep those
# registered versions that were built from the upstream version we want.
#
encode_gap_version(v::VersionNumber) = VersionNumber(100*v.major, 100*v.minor, 100*v.patch)

decode_pkg_version(v::VersionNumber) = (v.major ÷ 100, v.minor ÷ 10000, (v.minor % 10000) ÷ 100)

# GAP package versions are not quite VersionNumbers: they may use `-` as a
# separator (`2026.05-01`) and may have fewer than three components (`1.4`).
function parse_pkg_version(s::AbstractString)
    parts = [something(tryparse(Int, p), -1) for p in split(s, r"[.-]")]
    any(<(0), parts) && return nothing
    append!(parts, [0, 0])
    return (parts[1], parts[2], parts[3])
end

strip_build(v::VersionNumber) = VersionNumber(v.major, v.minor, v.patch)

"""
    registered_versions()

Map the name of every registered `GAP*_jll` to its registered versions.
"""
function registered_versions()
    versions = Dict{String,Vector{VersionNumber}}()

    for reg in reachable_registries(), (_, entry) in reg.pkgs
        startswith(entry.name, "GAP") && endswith(entry.name, JLL_SUFFIX) || continue
        append!(get!(versions, entry.name, VersionNumber[]),
                keys(registry_info(entry).version_info))
    end

    return versions
end

"""
    best_pkg_version(candidates, upstream)

The newest registered JLL version built from the upstream package version
`upstream`, or `nothing` if there is none.
"""
function best_pkg_version(candidates::Vector{VersionNumber}, upstream)
    matching = filter(v -> decode_pkg_version(v) == upstream, candidates)
    return isempty(matching) ? nothing : strip_build(maximum(matching))
end

"""
    proposed_compat(project, pkginfos, gap_version)

Compute the new `[compat]` entries. Returns the proposals as a name => version
string dict, a list of advisory notes, and a list of problems: entries that
should have been updated but could not be, i.e. builds that are still missing
from the registry.
"""
function proposed_compat(project, pkginfos, gap_version)
    available = registered_versions()
    deps = filter(startswith("GAP"), collect(keys(project["deps"])))
    proposals = Dict{String,String}()
    notes = String[]
    problems = String[]

    # upstream version of each GAP package, keyed like the JLL names
    upstream = Dict(PKG_PREFIX * lowercase(info["PackageName"]) * JLL_SUFFIX => info["Version"]
                    for info in values(pkginfos))

    if gap_version !== nothing
        encoded = encode_gap_version(gap_version)
        for name in ("GAP_jll", "GAP_lib_jll")
            if encoded in strip_build.(get(available, name, VersionNumber[]))
                proposals[name] = "~$(encoded)"
            else
                push!(problems, "$name: $encoded is not registered (build pending?)")
            end
        end
    else
        push!(notes, "GAP_jll, GAP_lib_jll: no GAP version given, use --gap-version=X.Y.Z")
    end

    for name in sort(deps)
        startswith(name, PKG_PREFIX) || continue

        # JuliaInterface follows this repository's version, not a GAP package
        wanted = name == JULIAINTERFACE ? project["version"] : get(upstream, name, nothing)
        if wanted === nothing
            push!(notes, "$name: no longer distributed with GAP, remove it by hand")
            continue
        end

        parsed = parse_pkg_version(replace(wanted, "-DEV" => ""))
        if parsed === nothing
            push!(notes, "$name: cannot parse upstream version '$wanted'")
            continue
        end

        best = best_pkg_version(get(available, name, VersionNumber[]), parsed)
        if best === nothing
            # a JuliaInterface JLL only exists once this repo has been released,
            # so a missing one is expected while developing
            list = name == JULIAINTERFACE ? notes : problems
            push!(list, "$name: no registered build for upstream $wanted (build pending?)")
            continue
        end

        proposals[name] = (name == JULIAINTERFACE ? "=" : "~") * string(best)
    end

    # packages that gained a JLL but which GAP.jl does not depend on yet; whether
    # a package needs one is a human decision, as is the matching import in
    # src/GAP_pkg.jl
    for name in sort(collect(keys(upstream)))
        (name in deps || !haskey(available, name)) && continue
        push!(notes, "$name: registered but not a dependency, consider adding it")
    end

    return proposals, notes, problems
end

"""
    apply_compat(project_toml, proposals)

Rewrite the matching lines of the `[compat]` section in place. Returns the
number of changed lines. Deliberately line based: a TOML round trip would
reformat the whole file.
"""
function apply_compat(project_toml, proposals)
    lines = readlines(project_toml)
    in_compat = false
    changed = 0

    for (i, line) in enumerate(lines)
        if startswith(line, "[")
            in_compat = line == "[compat]"
            continue
        end
        in_compat || continue

        m = match(r"^(\S+) = \"", line)
        m === nothing && continue
        haskey(proposals, m[1]) || continue

        new_line = "$(m[1]) = \"$(proposals[m[1]])\""
        new_line == line && continue

        lines[i] = new_line
        changed += 1
    end

    write(project_toml, join(lines, "\n") * "\n")

    return changed
end

function main(args)
    write_changes = "--write" in args
    "--update-registry" in args && Pkg.Registry.update()

    gap_version = nothing
    for arg in args
        m = match(r"^--gap-version=(.*)$", arg)
        m !== nothing && (gap_version = VersionNumber(m[1]))
    end

    desc = only(filter(!startswith("--"), args))
    startswith(desc, "4.") && gap_version === nothing && (gap_version = VersionNumber(desc))

    pkginfos = GZip.open(JSON.parse, resolve_pkginfos_path(desc), "r")
    project_toml = joinpath(dirname(@__DIR__), "Project.toml")
    project = Pkg.TOML.parsefile(project_toml)

    proposals, notes, problems = proposed_compat(project, pkginfos, gap_version)

    for name in sort(collect(keys(proposals)))
        old = get(project["compat"], name, "")
        marker = old == proposals[name] ? "  " : "->"
        println("$marker $(rpad(name, 32)) $(rpad(old, 24)) $(proposals[name])")
    end

    for note in vcat(notes, problems)
        @warn note
    end

    if !write_changes
        println("\nDry run, pass --write to apply.")
        return 0
    end

    changed = apply_compat(project_toml, proposals)
    println("\nUpdated $changed entries in $project_toml")

    return isempty(problems) ? 0 : 1
end

exit(main(ARGS))
