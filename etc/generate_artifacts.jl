# see https://julialang.org/blog/2019/11/artifacts/
using Pkg.Artifacts
import SHA

# TODO: make the version an argument?
# then download and check? Or perhaps we allow using an already present local .tar.gz??
gap_version = v"4.11.0"

artifact_name = "pkg"
url = "https://files.gap-system.org/gap4pkgs/packages-v$(gap_version).tar.gz"
#url = "https://github.com/gap-system/gap/releases/download/v$(gap_version)/$(gap_tarball)"
#url = "https://files.gap-system.org/gap-4.$(gap_version.minor)/tar.bz2/$(gap_tarball)"
filename = basename(url)

# ensure tarball is available
if !isfile(filename)
    download(url, filename)
    # TODO: handle errors...
end

# compute SHA256 of the tarball
@show tarball_hash = bytes2hex(open(SHA.sha256, filename))

# This is the path to the Artifacts.toml we will manipulate
artifacts_toml = joinpath(@__DIR__, "Artifacts.toml")

# Query the `Artifacts.toml` file for the hash bound to the name `artifact_name`
# (returns `nothing` if no such binding exists)
gap_hash = artifact_hash(artifact_name, artifacts_toml)

# If the name was not bound, or the hash it was bound to does not exist, create it!
if gap_hash == nothing || !artifact_exists(gap_hash)
    # create_artifact() returns the content-hash of the artifact directory once we're finished creating it
    abs_filename = abspath(filename)
    gap_hash = create_artifact() do artifact_dir
        # We create the artifact by simply downloading a few files into the new artifact directory
        cd(artifact_dir) do
            run(`tar xvf $(abs_filename)`)
            run(`find . -name '._*' -exec rm \{\} \;`)
        end
    end

    # Now bind that hash within our `Artifacts.toml`.  `force = true` means that if it already exists,
    # just overwrite with the new content-hash.  Unless the source files change, we do not expect
    # the content hash to change, so this should not cause unnecessary version control churn.
    bind_artifact!(
        artifacts_toml,
        artifact_name,
        gap_hash;
        download_info = [(url, tarball_hash)],
        lazy = false,
        force = true,
    )
end
