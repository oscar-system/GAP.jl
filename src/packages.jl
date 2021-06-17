## dealing with GAP packages

"""
    LoadPackageAndExposeGlobals(package::String, mod::String; all_globals::Bool = false)
    LoadPackageAndExposeGlobals(package::String, mod::Module = Main; all_globals::Bool = false, overwrite::Bool = false)

`LoadPackageAndExposeGlobals` loads `package` into GAP via `LoadPackage`,
and stores all newly defined GAP globals as globals in the module `mod`. If `mod` is
a string, the function creates a new module, if `mod` is a Module, it uses `mod` directly.

The function is intended to be used for creating mock modules for GAP packages.
If you load the package `CAP` via

    LoadPackageAndExposeGlobals( "CAP", "CAP" )

you can use CAP commands via

    CAP.PreCompose( a, b )

If `overwrite` is true, Symbols already in the `Main` module will be overloaded.
Be aware that this flag only works in `Main`.

"""
function LoadPackageAndExposeGlobals(
    package::String,
    mod::String;
    all_globals::Bool = false,
)
    mod_sym = Symbol(mod)
    Base.MainInclude.eval(:(module $(mod_sym)
    import GAP
    end))
    ## Adds the new module to the Main module, so it is directly accessible in the julia REPL
    mod_mod = Base.MainInclude.eval(:(Main.$(mod_sym)))

    ## We need to call `invokelatest` as the module `mod_mod` was only created during the
    ## call of this function in a different module, so its world age is higher than the
    ## function calls world age.
    Base.invokelatest(
        LoadPackageAndExposeGlobals,
        package,
        mod_mod;
        all_globals = all_globals,
    )
end

function LoadPackageAndExposeGlobals(
    package::String,
    mod::Module;
    all_globals::Bool = false,
    overwrite::Bool = false,
)
    current_gvar_list = nothing
    if !all_globals
        current_gvar_list = Globals.ShallowCopy(Globals.NamesGVars())
    end
    load_package = evalstr("LoadPackage(\"$package\")")
    if load_package == Globals.fail
        error("cannot load package $package")
    end
    new_gvar_list = Globals.NamesGVars()
    if !all_globals
        new_gvar_list = Globals.Difference(new_gvar_list, current_gvar_list)
    end
    new_symbols = Vector{Symbol}(new_gvar_list)
    for sym in new_symbols
        if overwrite || !isdefined(mod, sym)
            try
                # Note that we must specify `GAP.` here.
                mod.eval(:($(sym) = GAP.Globals.$(sym)))
            catch
            end
        end
    end
end

export LoadPackageAndExposeGlobals


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
        # Try to install the package.
        if Packages.install(spec; interactive = false)
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
