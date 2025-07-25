#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

@testset "packages" begin

    @test GAP.Packages.load("PackageManager")
    @test ! GAP.Packages.load("no such package")
    @test ! GAP.Packages.load("no such package", install = true)
    @test GAP.Packages.locate_package("no such package") == ""

    @test GAP.Packages.install("fga", interactive = false)
    @test GAP.Packages.load("fga")
    @test ! isempty(GAP.Packages.locate_package("fga"))
    @test ! isempty(GAP.Packages.locate_package("FGA"))
    @test GAP.Packages.remove("fga", interactive = false)

    # Test the installation of a package with a kernel extension, but without a jll
    @test GAP.Packages.install("https://github.com/gap-packages/RegisterPackageTNUMDemo/releases/download/v0.4/RegisterPackageTNUMDemo-0.4.tar.gz", interactive = false)
    @test GAP.Packages.load("RegisterPackageTNUMDemo")
    @test GAP.Packages.remove("RegisterPackageTNUMDemo", interactive = false)

#    pkgdir = mktempdir()
#    @test GAP.Packages.install("fga", interactive = false, pkgdir = pkgdir)
#    @test GAP.Packages.remove("fga", interactive = false, pkgdir = pkgdir)

    # Load packages via their local paths.
    # - a package that was already loaded, with the same path
    path = string(GAP.Globals.GAPInfo.PackagesLoaded.juliainterface[1])
    @test GAP.Packages.load(path)

    # - a package that was already loaded, with another installation path
#TODO: How to guarantee two installed versions with different paths?

    # - a package that was not yet loaded (only once in a Julia session)
    if ! GAP.Globals.IsPackageLoaded(GapObj("autodoc"))
      path = string(GAP.Globals.GAPInfo.PackagesInfo.autodoc[1].InstallationPath)
      @test GAP.Packages.load(path)
    end

    # - a nonexisting path
    path = path * "xxx"
    @test ! GAP.Packages.load(path)
end
