#
# This script is used to update Artifacts.toml
#
# Usage variants:
#   julia --project=etc etc/update_artifacts.jl 4.14.0
#   julia --project=etc etc/update_artifacts.jl https://.../package-infos.json
#   julia --project=etc etc/update_artifacts.jl https://.../package-infos.json.gz
#   julia --project=etc etc/update_artifacts.jl local/path/package-infos.json
#   julia --project=etc etc/update_artifacts.jl local/path/package-infos.json.gz
#

using Downloads: download
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

    for name in sort(collect(keys(pkgs)))
        print("Processing '$name' ")
        pkginfo = pkgs[name]
        add_artifacts_for_package(pkginfo, artifacts)

        # write it all out again
        open(artifacts_toml, "w") do io
            TOML.print(io, artifacts; sorted=true)
        end

    end
    
    # delete artifacts for any packages that are no longer distributed with GAP
    pkg_names = ["GAP_pkg_"*lowercase(pkginfo["PackageName"]) for (name, pkginfo) in pkgs]
    to_be_removed = setdiff(keys(artifacts), pkg_names)
    for name in to_be_removed
        delete!(artifacts, name)
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
    sha256 = pkginfo["ArchiveSHA256"]
    url = pkginfo["ArchiveURL"]
    formats = split(pkginfo["ArchiveFormats"], " ")
    url *= first(formats)  # this matches what the PackageDistro does, and allow us to use ArchiveSHA256
    url2 = "https://files.gap-system.org/pkg/" * basename(url)

    # check if this file is already registered
    if haskey(artifacts, artifact_name)
        downloads = artifacts[artifact_name]["download"]
        d = Dict("sha256" => sha256, "url" => url)
        if d in downloads
            println("  already present")
            d2 = Dict("sha256" => sha256, "url" => url2)
            if !(d2 in downloads)
                println("  added backup URL $(url2)")
                push!(downloads, d2)
            end
            return
        end
    end

    # add the artifact
    println("  importing new archive $url")
    tarball_path = download(url)
    tarball_hash = sha256sum(tarball_path)
    if sha256 != tarball_hash
        error("SHA256 mismatch for $url")
    end

    git_tree_sha1 = create_artifact() do artifact_dir
        Pkg.PlatformEngines.unpack(tarball_path, artifact_dir)
    end

    rm(tarball_path)
    #clear && remove_artifact(git_tree_sha1)

    artifacts[artifact_name] = Dict{String,Any}(
        "git-tree-sha1" => bytes2hex(git_tree_sha1.bytes),
        "download" => [ Dict("sha256" => sha256, "url" => url),
                        Dict("sha256" => sha256, "url" => url2) ]
    )

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
