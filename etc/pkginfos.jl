#
# Shared helper for locating GAP's `package-infos.json`, used by
# `update_artifacts.jl` and `update_jll_versions.jl`.
#

using Downloads: download

"""
    resolve_pkginfos_path(desc::AbstractString)

Turn `desc` into a local path to a `package-infos.json[.gz]`. `desc` may be a
GAP version (`"4.16.1"`), an arbitrary URL, or an already local path; the first
two are downloaded to a temporary file.
"""
function resolve_pkginfos_path(desc::AbstractString)
    if startswith(desc, "4.")
        desc = "https://github.com/gap-system/gap/releases/download/v$desc/package-infos.json.gz"
    end

    startswith(desc, "http") || return desc

    println("Download package-infos from $(desc)")
    return download(desc)
end
