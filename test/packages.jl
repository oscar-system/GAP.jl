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
    GAP.Packages.versioninfo(IOBuffer(); full = true) # test that this does not error, see #1246

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

    # Run package tests.
    @test ! GAP.Packages.test("no_such_package")
    @test GAP.Packages.test("fga")

    # Test updating a package.
    # - a package that is not installed in the user package directory
    @test ! GAP.Packages.update("fga"; interactive = false)

    # - a package that is installed in the user package directory
    @test GAP.Packages.install("fga", interactive = false)
    @test GAP.Packages.update("fga", interactive = false)
    @test GAP.Packages.remove("fga", interactive = false)

    # Test building a package.
    # For that, we choose two packages with kernel extensions,
    # such that one is a needed package of the other.
    pkgs = map(name -> Dict{Symbol, Any}(:name => name), ["orb", "genss"])
    for pkg in pkgs
      # build the package and its dependencies (may do nothing
      # if they already are built)
      @test GAP.Packages.build_recursive(pkg[:name])
      # Make sure that GAP stores package information.
      GAP.Packages.with_info_level(GAP.Globals.InfoPackageLoading, 4) do
        @test GAP.Packages.load(pkg[:name]; quiet=false)
      end
      # Manipulate GAP's global information such that
      # `GAP.Globals.TestPackageAvailability` believes
      # the package is not yet loaded.
      # (Otherwise `GAP.Packages.build` would do nothing.)
      pkg[:pkgloaded] = getproperty(GAP.Globals.GAPInfo.PackagesLoaded, pkg[:name])
      GAP.Wrappers.UNB_REC(GAP.Globals.GAPInfo.PackagesLoaded, GAP.RNamObj(String(pkg[:name])))
      pkg[:pkginfo] = collect(GAP.Globals.PackageInfo(GapObj(pkg[:name])))
      pkg[:avail_test] = [x.AvailabilityTest for x in pkg[:pkginfo]]
      for r in pkg[:pkginfo]
        r.AvailabilityTest = GAP.Globals.ReturnFalse
      end

      # Build the packages again, this time for sure.
      @test GAP.Packages.build_recursive(pkg[:name])

      # Reinstall the GAP information.
      setproperty!(GAP.Globals.GAPInfo.PackagesLoaded, pkg[:name], pkg[:pkgloaded])
      for i in 1:length(pkg[:pkginfo])
        pkg[:pkginfo][i].AvailabilityTest = pkg[:avail_test][i]
      end
    end
    @test GAP.Packages.remove("orb", interactive = false)
    @test GAP.Packages.remove("genss", interactive = false)
end
