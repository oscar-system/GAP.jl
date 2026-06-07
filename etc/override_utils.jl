module OverrideUtils

export fixup_macos_libgap_install_names, macos_libgap_install_name_updates

function macos_libgap_install_name_updates(prefix::AbstractString; is_apple::Bool = Sys.isapple())
    is_apple || return Tuple{String, String}[]

    libdir = joinpath(prefix, "lib")
    isdir(libdir) || return Tuple{String, String}[]

    updates = Tuple{String, String}[]
    for entry in sort(readdir(libdir))
        startswith(entry, "libgap.") || continue
        endswith(entry, ".dylib") || continue
        occursin(r"^libgap\.[0-9]+\.dylib$", entry) || continue
        path = joinpath(libdir, entry)
        isfile(path) || continue
        push!(updates, (path, "@rpath/$(entry)"))
    end
    return updates
end

function fixup_macos_libgap_install_names(prefix::AbstractString)
    for (path, install_name) in macos_libgap_install_name_updates(prefix)
        run(`install_name_tool -id $(install_name) $(path)`)
    end
    return nothing
end

end
