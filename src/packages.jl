## dealing with GAP packages
module Packages

using Downloads
import ...GAP: Globals, GapObj, sysinfo

const DEFAULT_PKGDIR = Ref{String}()

function init_packagemanager()
#TODO:
# As soon as PackageManager uses utils' Download function,
# we need not replace code from PackageManager anymore.
# (And the function should be renamed.)
    res = load("PackageManager")
    @assert res

    global DEFAULT_PKGDIR[] = sysinfo["DEFAULT_PKGDIR"]

    # overwrite PKGMAN_DownloadURL
    Globals.MakeReadWriteGlobal(GapObj("PKGMAN_DownloadURL"))
    Globals.PKGMAN_DownloadURL = function(url)
      try
        buffer = Downloads.download(String(url), IOBuffer())
        return GapObj(Dict{Symbol, Any}(:success => true, :result => String(take!(buffer))), recursive=true)
      catch
        return GapObj(Dict{Symbol, Any}(:success => false), recursive=true)
      end
    end
    Globals.MakeReadOnlyGlobal(GapObj("PKGMAN_DownloadURL"))

    # Install a method (based on Julia's Downloads package) as the first choice
    # for the `Download` function from GAP's utils package,
    # in order to make this function independent of the availability of some
    # external program that is not guaranteed by an explicit dependency.
    res = load("utils")
    @assert res
    if hasproperty(Globals, :Download_Methods)
      # provide a Julia function as a `Download` method
      r = Dict{Symbol, Any}(
           :name => "via Julia's Downloads.download",
           :isAvailable => Globals.ReturnTrue,
           :download => function(url, opt)
             try
               if hasproperty(opt, :target)
                 Downloads.download(String(url), String(opt.target))
                 return GapObj(Dict{Symbol, Any}(:success => true), recursive=true)
               else
                 buffer = Downloads.download(String(url), IOBuffer())
                 return GapObj(Dict{Symbol, Any}(:success => true, :result => String(take!(buffer))), recursive=true)
               end
             catch e
               return GapObj(Dict{Symbol, Any}(:success => false,
                                               :error => GapObj(string(e))),
                             recursive=true)
             end
           end)

      # put the new method in the first position
      meths = Globals.Download_Methods
      Globals.Add(meths, GapObj(r, recursive=true), 1)
    end
end

"""
    load(spec::String, version::String = ""; install::Bool = false, quiet::Bool = true)

Try to load the GAP package with name `spec`.
If `version` is specified then try to load a version of the package
that is compatible with `version`, in the sense of
[GAP's CompareVersionNumbers function](GAP_ref(ref:CompareVersionNumbers)),
otherwise try to load the newest installed version.
Return `true` if this is successful, and `false` otherwise.

If `install` is set to `true` and (the desired version of) the required
GAP package is not yet installed then [`install`](@ref) is called first,
in order to install the package;
if no version is prescribed then the newest released version of the package
will be installed.

The function calls [GAP's `LoadPackage` function](GAP_ref(ref:LoadPackage)).
If `quiet` is set to `false` then package banners are shown for all packages
being loaded. It is also passed on to [`install`](@ref).
"""
function load(spec::String, version::String = ""; install::Bool = false, quiet::Bool = true)
    # Try to load the package.
    gspec = GapObj(spec)
    gversion = GapObj(version)
    loaded = Globals.LoadPackage(gspec, gversion, !quiet)
    if loaded == true
        return true
    elseif Globals.IsPackageLoaded(gspec)
        # Another version is already loaded.
        # Perhaps we could install the required version,
        # but then we would not be able to load it into the current session
        # and thus in any case `false` must be returned.
        # It would be a strange side effect if the required version
        # would afterwards be loadable in a fresh Julia session,
        # thus we do not try to install the package here.
        return false
    elseif install == true
        # Try to install the given version of the package,
        # without showing messages.
        if Packages.install(spec, version; interactive = false, quiet)
            # Make sure that the installed version is admissible.
            return Globals.LoadPackage(gspec, gversion, !quiet) == true
        end
    end

    return false
    # TODO: can we provide more information in case of a failure?
    # GAP unfortunately only gives us info messages...
end

"""
    install(spec::String, version::String = "";
                          interactive::Bool = true, quiet::Bool = false,
                          pkgdir::AbstractString = GAP.Packages.DEFAULT_PKGDIR[])

Download and install the GAP package given by `spec` into the `pkgdir`
directory.

`spec` can be either the name of a package or the URL of an archive or repository
containing a package, or the URL of a `PackageInfo.g` file.

If `spec` is the name of a package then the package version can be
specified by `version`, in the format described for
[GAP's CompareVersionNumbers function](GAP_ref(ref:CompareVersionNumbers)).
In all other cases the newest released version of the package will get
installed.

Return `true` if the installation is successful or if
(a version compatible with `version`) of the package was already installed,
and `false` otherwise.

The function uses [the function `InstallPackage` from GAP's package
`PackageManager`](GAP_ref(PackageManager:InstallPackage)).
The info messages shown by this function can be suppressed by passing
`true` as the value of `quiet`. Specifying `interactive = false` will
prevent `PackageManager` from prompting the user for input interactively.
For details, please refer to its documentation.
"""
function install(spec::String, version::String = "";
                               interactive::Bool = true, quiet::Bool = false,
                               pkgdir::AbstractString = DEFAULT_PKGDIR[])
    # point PackageManager to the given pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)

    if quiet
      oldlevel = Globals.InfoLevel(Globals.InfoPackageManager)
      Globals.SetInfoLevel(Globals.InfoPackageManager, 0)
    end
    if version == ""
      res = Globals.InstallPackage(GapObj(spec), interactive)
    else
      res = Globals.InstallPackage(GapObj(spec), GapObj(version), interactive)
    end
    if quiet
      Globals.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
    end
    return res
end

"""
    update(spec::String; interactive::Bool = true, quiet::Bool = false,
                         pkgdir::AbstractString = GAP.Packages.DEFAULT_PKGDIR[])

Update the GAP package given by `spec` that is installed in the
`pkgdir` directory, to the latest version.
Return `true` if a newer version was installed successfully,
or if no newer version is available, and `false` otherwise.

`spec` can be either the name of a package or the URL of an archive or repository
containing a package, or the URL of a `PackageInfo.g` file.

The function uses [the function `UpdatePackage` from GAP's package
`PackageManager`](GAP_ref(PackageManager:UpdatePackage)).
The info messages shown by this function can be suppressed by passing
`true` as the value of `quiet`. Specifying `interactive = false` will
prevent `PackageManager` from prompting the user for input interactively.
For details, please refer to its documentation.
"""
function update(spec::String; interactive::Bool = true, quiet::Bool = false,
                              pkgdir::AbstractString = DEFAULT_PKGDIR[])
    # point PackageManager to the given pkg dir
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
    remove(spec::String; interactive::Bool = true, quiet::Bool = false,
                         pkgdir::AbstractString = GAP.Packages.DEFAULT_PKGDIR[])

Remove the GAP package with name `spec` that is installed in the
`pkgdir` directory.
Return `true` if the removal was successful, and `false` otherwise.

The function uses [the function `RemovePackage` from GAP's package
`PackageManager`](GAP_ref(PackageManager:RemovePackage)).
The info messages shown by this function can be suppressed by passing
`true` as the value of `quiet`. Specifying `interactive = false` will
prevent `PackageManager` from prompting the user for input interactively.
For details, please refer to its documentation.
"""
function remove(spec::String; interactive::Bool = true, quiet::Bool = false,
                              pkgdir::AbstractString = DEFAULT_PKGDIR[])
    # point PackageManager to the given pkg dir
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
