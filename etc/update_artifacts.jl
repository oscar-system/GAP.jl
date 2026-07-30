#
# This script is used to update Artifacts.toml
#
# Usage variants:
# 1. Specify `packages-infos.json` to update all packages. This removes all
#    artifacts for packages not contained in that file.
#
#     julia --project=etc etc/update_artifacts.jl 4.14.0
#     julia --project=etc etc/update_artifacts.jl https://.../package-infos.json
#     julia --project=etc etc/update_artifacts.jl https://.../package-infos.json.gz
#     julia --project=etc etc/update_artifacts.jl local/path/package-infos.json
#     julia --project=etc etc/update_artifacts.jl local/path/package-infos.json.gz
#
# 2. Specify `meta.json` to update a single package.
#
#     julia --project=etc etc/update_artifacts.jl https://.../meta.json
#     julia --project=etc etc/update_artifacts.jl local/path/meta.json
#

using Downloads: download, RequestError
import Pkg
using Pkg.Artifacts
import Pkg.PlatformEngines
#using Pkg.GitTools
import GZip
import JSON
import TOML
import SHA


function sha256sum(tarball_path)
    return open(tarball_path, "r") do io
        return bytes2hex(SHA.sha256(io))
    end
end

function add_artifacts_for_packages(; pkginfos_path::String = "package-infos.json", artifacts_toml::String="Artifacts.toml")
    pkgs = GZip.open(JSON.parse, pkginfos_path, "r")
    artifacts = TOML.parsefile(artifacts_toml)

    if haskey(pkgs, "PackageName")  # meta.json for a single package
        print("Processing '$(pkgs["PackageName"])' ")
        pkginfo = pkgs
        add_artifacts_for_package(pkginfo, artifacts)
    else                            # package-infos.json for all packages
        for name in sort(collect(keys(pkgs)))
            print("Processing '$(name)' ")
            pkginfo = pkgs[name]
            add_artifacts_for_package(pkginfo, artifacts)
        end

        # delete artifacts for any packages that are no longer distributed with GAP
        pkg_names = ["GAP_pkg_"*lowercase(pkginfo["PackageName"]) for (name, pkginfo) in pkgs]
        to_be_removed = setdiff(keys(artifacts), pkg_names)
        for name in to_be_removed
            delete!(artifacts, name)
        end
    end

    # write it all out again
    open(artifacts_toml, "w") do io
        TOML.print(io, artifacts; sorted=true)
    end
    
    return nothing
end

function add_artifacts_for_package(pkginfo, artifacts)
    gap_pkgname = pkginfo["PackageName"]
    pkgname = lowercase(gap_pkgname)
    artifact_name = "GAP_pkg_$(pkgname)"

    #
    # extract info about the package tarball
    #
    formats = intersect(split(pkginfo["ArchiveFormats"], r"[,\s]+"), [".tar.gz", ".tar.bz2"])
    isempty(formats) && error("  No supported archive formats found for $(gap_pkgname)")

    git_tree_sha1s = String[]
    urls = Dict{String,String}[]

    baseurls = [pkginfo["ArchiveURL"], "https://files.gap-system.org/pkg/" * basename(pkginfo["ArchiveURL"])]
    for (i, format) in enumerate(formats)
        sha256 = i == 1 ? pkginfo["ArchiveSHA256"] : nothing

        for baseurl in baseurls
            url = baseurl * format
            tarball_path = try
                download(url)
            catch e
                if e isa RequestError && e.response.status == 404
                    println("  $(url) not found, skipping")
                    continue
                else
                    rethrow(e)
                end
            end
            tarball_hash = sha256sum(tarball_path)
            if isnothing(sha256)
                sha256 = tarball_hash
            elseif sha256 != tarball_hash
                error("  SHA256 mismatch for $url: expected $(sha256), got $(tarball_hash)")
            end

            git_tree_sha1 = create_artifact() do artifact_dir
                Pkg.PlatformEngines.unpack(tarball_path, artifact_dir)
            end
            push!(git_tree_sha1s, bytes2hex(git_tree_sha1.bytes))

            push!(urls, Dict("url" => url, "sha256" => sha256))

            rm(tarball_path)
        end
    end

    allequal(git_tree_sha1s) || error("  unpacked tarballs have different git-tree-sha1 values for $(gap_pkgname)")

    # prefer .tar.gz over .tar.bz2 for the download URL, see https://github.com/JuliaPackaging/PkgServer.jl/issues/238
    if any(url -> endswith(url["url"], ".tar.gz"), urls)
        filter!(url -> endswith(url["url"], ".tar.gz"), urls)
    end

    artifact_entry = Dict{String,Any}(
        "git-tree-sha1" => first(git_tree_sha1s),
        "download" => urls,
    )

    if artifacts[artifact_name] == artifact_entry
        println("  artifact entry already present")
    elseif !haskey(artifacts, artifact_name)
        artifacts[artifact_name] = artifact_entry
        println("  added artifact entry for $(artifact_name)")
    else
        artifacts[artifact_name] = artifact_entry
        println("  updated artifact entry for $(artifact_name)")
    end

    return
end

# https://github.com/gap-system/gap/releases/download/v4.14.0/package-infos.json.gz
# https://github.com/gap-system/gap/releases/download/v4.14.0/package-infos.json.gz.sha256

if length(ARGS) > 0
    desc = ARGS[1]
    if startswith(desc, "http")
        pkginfos_url = desc
        println("Download package-infos from $(pkginfos_url)")
        pkginfos_path = download(pkginfos_url)
    elseif startswith(desc, "4.")
        pkginfos_url = "https://github.com/gap-system/gap/releases/download/v$desc/package-infos.json.gz"
        println("Download package-infos from $(pkginfos_url)")
        pkginfos_path = download(pkginfos_url)
    else
        pkginfos_path = desc
    end

    println("processing $(pkginfos_path)")
    add_artifacts_for_packages(; pkginfos_path)
end
