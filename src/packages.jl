## dealing with GAP packages
module Packages

import ...GAP: Globals, GapObj, sysinfo

const DEFAULT_PKGDIR = sysinfo["DEFAULT_PKGDIR"]

"""
    load(spec::String, version::String = ""; install = false)

Try to load the newest installed version of the GAP package with name `spec`.
Return `true` if this is successful, and `false` otherwise.

The function calls [GAP's `LoadPackage` function](GAP_ref(ref:LoadPackage));
the package banner is not printed.

If `install` is set to `true` and the required GAP package is not yet
installed then [`install`](@ref) is called first, in order to install
the newest released version of the package.
"""
function load(spec::String, version::String = ""; install = false)
    # Try to load the package.
    gspec = GapObj(spec)
    gversion = GapObj(version)
    loaded = Globals.LoadPackage(gspec, gversion, false)
    if loaded == true
        return true
    elseif install == true
        # Try to install the package, without showing messages.
        if Packages.install(spec; interactive = false, quiet = true)
            # Make sure that the installed version is admissible.
            return Globals.LoadPackage(gspec, gversion, false)
        end
    end

    return false
    # TODO: can we provide more information in case of a failure?
    # GAP unfortunately only gives us info messages...
end

"""
    install(spec::String; interactive::Bool = true, quiet::Bool = false)

Download and install the newest released version of the GAP package
given by `spec` in the `pkg` subdirectory of GAP's build directory
(variable `GAP.GAPROOT`).
Return `true` if the installation is successful or if the package
was already installed, and `false` otherwise.

`spec` can be either the name of a package or the URL of an archive or repository
containing a package, or the URL of a `PackageInfo.g` file.

The function uses [the function `InstallPackage` from GAP's package
`PackageManager`](GAP_ref(PackageManager:InstallPackage)).
The info messages shown by  this function can be suppressed by entering
`true` as the value of `quiet`.
"""
function install(spec::String; interactive::Bool = true, pkgdir::AbstractString = DEFAULT_PKGDIR, quiet::Bool = false)
    res = load("PackageManager")
    @assert res

    # point PackageManager to our internal pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)

    if quiet
      oldlevel = Globals.InfoLevel(Globals.InfoPackageManager)
      Globals.SetInfoLevel(Globals.InfoPackageManager, 0)
      res = Globals.InstallPackage(GapObj(spec), interactive)
      Globals.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
      return res
    else
      return Globals.InstallPackage(GapObj(spec), interactive)
    end
end

"""
    update(spec::String; quiet::Bool = false)

Update the GAP package given by `spec` that is installed in the
`pkg` subdirectory of GAP's build directory (variable `GAP.GAPROOT`),
to the latest version.
Return `true` if a newer version was installed successfully,
or if no newer version is available, and `false` otherwise.

`spec` can be either the name of a package or the URL of an archive or repository
containing a package, or the URL of a `PackageInfo.g` file.

The function uses [the function `UpdatePackage` from GAP's package
`PackageManager`](GAP_ref(PackageManager:UpdatePackage)).
The info messages shown by  this function can be suppressed by entering
`true` as the value of `quiet`.
"""
function update(spec::String; interactive::Bool = true, pkgdir::AbstractString = DEFAULT_PKGDIR, quiet::Bool = false)
    res = load("PackageManager")
    @assert res

    # point PackageManager to our internal pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)

    if quiet
      oldlevel = Globals.InfoLevel(Globals.InfoPackageManager)
      Globals.SetInfoLevel(Globals.InfoPackageManager, 0)
      res = Globals.UpdatePackage(GapObj(spec), interactive)
      Globals.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
      return res
    else
      return Globals.UpdatePackage(GapObj(spec), interactive)
    end
end
# note that the updated version cannot be used in the current GAP session,
# because the older version is already loaded;
# thus nec. to start Julia anew

"""
    remove(spec::String; quiet::Bool = false)

Remove the GAP package with name `spec` that is installed in the
`pkg` subdirectory of GAP's build directory (variable `GAP.GAPROOT`).
Return `true` if the removal was successful, and `false` otherwise.

The function uses [the function `RemovePackage` from GAP's package
`PackageManager`](GAP_ref(PackageManager:RemovePackage)).
The info messages shown by  this function can be suppressed by entering
`true` as the value of `quiet`.
"""
function remove(spec::String; interactive::Bool = true, pkgdir::AbstractString = DEFAULT_PKGDIR, quiet::Bool = false)
    res = load("PackageManager")
    @assert res

    # point PackageManager to our internal pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)

    if quiet
      oldlevel = Globals.InfoLevel(Globals.InfoPackageManager)
      Globals.SetInfoLevel(Globals.InfoPackageManager, 0)
      res = Globals.RemovePackage(GapObj(spec), interactive)
      Globals.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
      return res
    else
      return Globals.RemovePackage(GapObj(spec), interactive)
    end
end

end
