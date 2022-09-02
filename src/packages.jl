## dealing with GAP packages
module Packages

using Downloads
import ...GAP: Globals, GapObj, sysinfo

const DEFAULT_PKGDIR = sysinfo["DEFAULT_PKGDIR"]

function init_packagemanager()
#TODO:
# As soon as PackageManager uses utils' Download function,
# we need not replace code from PackageManager anymore.
# (And the function should be renamed.)
    res = load("PackageManager")
    @assert res

    # overwrite PKGMAN_DownloadURL
    Globals.MakeReadWriteGlobal(GapObj("PKGMAN_DownloadURL"))
    Globals.PKGMAN_DownloadURL = function(url)
        # exception handling is omitted by concept, i.e. errors occuring during the download are shown to the user
        buffer = Downloads.download(String(url), IOBuffer())
        return GapObj(Dict{Symbol, Any}(:success => true, :result => String(take!(buffer))), recursive=true)
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
             # exception handling is omitted by concept, i.e. errors occuring during the download are shown to the user
             if hasproperty(opt, :target)
               Downloads.download(String(url), String(opt.target))
               return GapObj(Dict{Symbol, Any}(:success => true), recursive=true)
             else
               buffer = Downloads.download(String(url), IOBuffer())
               return GapObj(Dict{Symbol, Any}(:success => true, :result => String(take!(buffer))), recursive=true)
             end
           end)

      # put the new method in the first position
      meths = Globals.Download_Methods
      Globals.Add(meths, GapObj(r, recursive=true), 1)
    end
end

"""
    load(spec::String, version::String = ""; install::Bool = false, quiet::Bool = true)

Try to load the newest installed version of the GAP package with name `spec`.
Return `true` if this is successful, and `false` otherwise.

The function calls [GAP's `LoadPackage` function](GAP_ref(ref:LoadPackage));
the package banner is not printed.

If `install` is set to `true` and the required GAP package is not yet
installed then [`install`](@ref) is called first, in order to install
the newest released version of the package.

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
    elseif install == true
        # Try to install the package, without showing messages.
        if Packages.install(spec; interactive = false, quiet)
            # Make sure that the installed version is admissible.
            return Globals.LoadPackage(gspec, gversion, !quiet)
        end
    end

    return false
    # TODO: can we provide more information in case of a failure?
    # GAP unfortunately only gives us info messages...
end

"""
    install(spec::String; interactive::Bool = true, quiet::Bool = false,
                          pkgdir::AbstractString = GAP.Packages.DEFAULT_PKGDIR)

Download and install the newest released version of the GAP package
given by `spec` into the `pkgdir` directory.
Return `true` if the installation is successful or if the package
was already installed, and `false` otherwise.

`spec` can be either the name of a package or the URL of an archive or repository
containing a package, or the URL of a `PackageInfo.g` file.

The function uses [the function `InstallPackage` from GAP's package
`PackageManager`](GAP_ref(PackageManager:InstallPackage)).
The info messages shown by this function can be suppressed by passing
`true` as the value of `quiet`. Specifying `interactive = false` will
prevent `PackageManager` from prompting the user for input interactively.
For details, please refer to its documentation.
"""
function install(spec::String; interactive::Bool = true, quiet::Bool = false,
                               pkgdir::AbstractString = DEFAULT_PKGDIR)
    # point PackageManager to the given pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)

    try
#T When a new PackageManager version will be available,
#T this try/catch is no longer necessary,
#T because no GAP error is thrown when one is offline or so.
      if quiet
        oldlevel = Globals.InfoLevel(Globals.InfoPackageManager)
        Globals.SetInfoLevel(Globals.InfoPackageManager, 0)
        res = Globals.InstallPackage(GapObj(spec), interactive)
        Globals.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
        return res
      else
        return Globals.InstallPackage(GapObj(spec), interactive)
      end
    catch e
      if ! quiet
        println( "cannot install $spec:\n$e")
      end
      return false
    end
end

"""
    update(spec::String; interactive::Bool = true, quiet::Bool = false,
                         pkgdir::AbstractString = GAP.Packages.DEFAULT_PKGDIR)

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
                              pkgdir::AbstractString = DEFAULT_PKGDIR)
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
                         pkgdir::AbstractString = GAP.Packages.DEFAULT_PKGDIR)

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
                              pkgdir::AbstractString = DEFAULT_PKGDIR)
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
