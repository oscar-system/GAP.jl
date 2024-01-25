## dealing with GAP packages
module Packages

using Downloads
import Pidfile
import ...GAP: Globals, GapObj, replace_global!, RNamObj, sysinfo, Wrappers

const DEFAULT_PKGDIR = Ref{String}()
const DOWNLOAD_HELPER = Ref{Downloads.Downloader}()

function init_packagemanager()
#TODO:
# As soon as PackageManager uses utils' Download function,
# we need not replace code from PackageManager anymore.
# (And the function should be renamed.)
    res = load("PackageManager")
    @assert res

    global DEFAULT_PKGDIR[] = sysinfo["DEFAULT_PKGDIR"]
    global DOWNLOAD_HELPER[] = Downloads.Downloader(; grace=0.1)

    # overwrite PKGMAN_DownloadURL
    replace_global!(:PKGMAN_DownloadURL, function(url)
      try
        buffer = Downloads.download(String(url), IOBuffer(), downloader=DOWNLOAD_HELPER[])
        return GapObj(Dict{Symbol, Any}(:success => true, :result => String(take!(buffer))), recursive=true)
      catch
        return GapObj(Dict{Symbol, Any}(:success => false), recursive=true)
      end
    end)

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
                 Downloads.download(String(url), String(opt.target), downloader=DOWNLOAD_HELPER[])
                 return GapObj(Dict{Symbol, Any}(:success => true), recursive=true)
               else
                 buffer = Downloads.download(String(url), IOBuffer(), downloader=DOWNLOAD_HELPER[])
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
      Wrappers.Add(meths, GapObj(r, recursive=true), 1)

      # monkey patch PackageManager so that we can disable removal of
      # package directories for debugging purposes
      orig_PKGMAN_RemoveDir = Globals.PKGMAN_RemoveDir
      replace_global!(:PKGMAN_RemoveDir, function(dir)
        Globals.ValueOption(GapObj("debug")) == true && return
        orig_PKGMAN_RemoveDir(dir)
      end)
    end
end

"""
    load(spec::String, version::String = ""; install::Union{Bool, String} = false, quiet::Bool = true)

Try to load the GAP package given by `spec`, which can be either the name
of the package or a local path where the package is installed
(a directory that contains the package's `PackageInfo.g` file).

If `version` is specified then try to load a version of the package
that is compatible with `version`, in the sense of
[GAP's CompareVersionNumbers function](GAP_ref(ref:CompareVersionNumbers)),
otherwise try to load the newest installed version.
Return `true` if this is successful, and `false` otherwise.

If `install` is set to `true` or to a string and (the desired version of)
the required GAP package is not yet installed and `spec` is the package name
then [`install`](@ref) is called first, in order to install
the package;
if no version is prescribed then the newest released version of the package
will be installed.
A string value of `install` can be the URL of an archive or repository
containing a package, or the URL of a `PackageInfo.g` file,
like the first argument of [`install`](@ref).

The function calls [GAP's `LoadPackage` function](GAP_ref(ref:LoadPackage)).
If `quiet` is set to `false` then package banners are shown for all packages
being loaded.
The `quiet` value is also passed on to [`install`](@ref).
"""
function load(spec::String, version::String = ""; install::Union{Bool, String} = false, quiet::Bool = true)
    # Decide whether `spec` is a path to a directory that contains
    # a `PackageInfo.g` file.
    package_info = joinpath(spec, "PackageInfo.g")
    spec_is_path = isdir(spec) && isfile(package_info)

    # If `spec` contains a slash then it is not a package name.
    '/' in spec && ! spec_is_path && return false

    # The interpretation of `spec` as a package name has precedence
    # over the interpretation as a path.
    # Try to load the package, assuming that `spec` is its name.
    gspec = GapObj(spec)
    gversion = GapObj(version)
    if spec_is_path
      # If there is no package `gspec` and if the info level of
      # `GAP.Globals.InfoWarning` is at least 1 then GAP prints a warning.
      # Avoid this warning.
      warning_level_orig = Wrappers.InfoLevel(Globals.InfoWarning)
      Wrappers.SetInfoLevel(Globals.InfoWarning, 0)
    end
    loaded = Wrappers.LoadPackage(gspec, gversion, !quiet)
    if spec_is_path
      Wrappers.SetInfoLevel(Globals.InfoWarning, warning_level_orig)
    end

    loaded == true && return true

    if Wrappers.IsPackageLoaded(gspec)
      # Another version is already loaded.
      # Perhaps we could install the required version,
      # but then we would not be able to load it into the current session
      # and thus in any case `false` must be returned.
      # It would be a strange side effect if the required version
      # would afterwards be loadable in a fresh Julia session,
      # thus we do not try to install the package here.
      return false
    end

    if spec_is_path
      # Assume that the package is installed in the given path.
      # In order to call `GAP.Globals.SetPackagePath`,
      # we have to determine the package name.
      # (`Wrappers.SetPackagePath` does the same,
      # but it needs the package name as an argument.)
      gap_info = Globals.GAPInfo::GapObj
      Wrappers.UNB_REC(gap_info, RNamObj("PackageInfoCurrent"))
      Wrappers.Read(GapObj(package_info))
      record = gap_info.PackageInfoCurrent
      Wrappers.UNB_REC(gap_info, RNamObj("PackageInfoCurrent"))
      pkgname = Wrappers.NormalizedWhitespace(Wrappers.LowercaseString(
                  record.PackageName))
      rnam_pkgname = Wrappers.RNamObj(pkgname)

      # If the package with name `pkgname` is already loaded then check
      # whether the installation path is equal to `spec`.
      # (Note that `Wrappers.SetPackagePath` throws an error if a different
      # version of the package is already loaded.)
      if Wrappers.IsPackageLoaded(pkgname) &&
         Wrappers.ISB_REC(gap_info.PackagesLoaded, rnam_pkgname)
        install_path = Wrappers.ELM_REC(gap_info.PackagesLoaded, rnam_pkgname)[1]
        return joinpath(string(install_path), "PackageInfo.g") == package_info
      end
#TODO: What shall happen when `spec` is a symbolic link that points to
#      the installation path of the loaded package?

      # First save the available records for the package in question, ...
      old_records = nothing
      if Wrappers.ISB_REC(gap_info.PackagesInfo, rnam_pkgname)
        old_records = Wrappers.ELM_REC(gap_info.PackagesInfo, rnam_pkgname)
      end

      # ... then try to load the package, ...
      Wrappers.SetPackagePath(pkgname, gspec)
      loaded = Wrappers.LoadPackage(pkgname, gversion, !quiet)

      # ..., and reinstall the old info records
      # (which were removed by `Wrappers.SetPackagePath`).
      if old_records isa GapObj
        Wrappers.Append(Wrappers.ELM_REC(gap_info.PackagesInfo, rnam_pkgname),
            old_records)
      end

      loaded == true && return true
      Wrappers.IsPackageLoaded(gspec) && return false
    end

    # The package is not yet loaded, and `spec` is its name.
    if install == true
        # Try to install the given version of the package,
        # without showing messages.
        if Packages.install(spec, version; interactive = false, quiet)
            # Make sure that the installed version is admissible.
            return Wrappers.LoadPackage(gspec, gversion, !quiet) == true
        end
    elseif install isa String
        # `Packages.install` deals with the `install` information.
        if Packages.install(install, version; interactive = false, quiet)
            # Make sure that the installed version is admissible
            # (and that the package given by `install` fits to `spec`).
            return Wrappers.LoadPackage(gspec, gversion, !quiet) == true
        end
    end

    return false
    # TODO: can we provide more information in case of a failure?
    # GAP unfortunately only gives us info messages...
end

"""
    install(spec::String, version::String = "";
                          interactive::Bool = true, quiet::Bool = false,
                          debug::Bool = false,
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
                               debug::Bool = false,
                               pkgdir::AbstractString = DEFAULT_PKGDIR[])
    # point PackageManager to the given pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)
    Pidfile.mkpidlock("$pkgdir.lock") do
      if quiet || debug
        oldlevel = Wrappers.InfoLevel(Globals.InfoPackageManager)
        Wrappers.SetInfoLevel(Globals.InfoPackageManager, quiet ? 0 : 3)
      end
      if version == ""
        res = Globals.InstallPackage(GapObj(spec), interactive; debug)
      else
        res = Globals.InstallPackage(GapObj(spec), GapObj(version), interactive; debug)
      end
      if quiet || debug
        Wrappers.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
      end
      return res
    end
end

"""
    update(spec::String; interactive::Bool = true, quiet::Bool = false,
                         debug::Bool = false,
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
                              debug::Bool = false,
                              pkgdir::AbstractString = DEFAULT_PKGDIR[])
    # point PackageManager to the given pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)

    if quiet || debug
      oldlevel = Wrappers.InfoLevel(Globals.InfoPackageManager)
      Wrappers.SetInfoLevel(Globals.InfoPackageManager, quiet ? 0 : 3)
      res = Globals.UpdatePackage(GapObj(spec), interactive; debug)
      Wrappers.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
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
                         debug::Bool = false,
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
                              debug::Bool = false,
                              pkgdir::AbstractString = DEFAULT_PKGDIR[])
    # point PackageManager to the given pkg dir
    Globals.PKGMAN_CustomPackageDir = GapObj(pkgdir)
    mkpath(pkgdir)

    if quiet || debug
      oldlevel = Wrappers.InfoLevel(Globals.InfoPackageManager)
      Wrappers.SetInfoLevel(Globals.InfoPackageManager, quiet ? 0 : 3)
      res = Globals.RemovePackage(GapObj(spec), interactive; debug)
      Wrappers.SetInfoLevel(Globals.InfoPackageManager, oldlevel)
      return res
    else
      return Globals.RemovePackage(GapObj(spec), interactive)
    end
end

"""
    locate_package(name::String)

Return the path where the GAP package with name `name` is installed
if this package is loaded, and `""` otherwise.
"""
function locate_package(name::String)
  loaded = Globals.GAPInfo.PackagesLoaded::GapObj
  lname = RNamObj(lowercase(name))
  Wrappers.ISB_REC(loaded, lname) || return ""
  return String(Wrappers.ELM_REC(loaded, lname)[1])
end

end
