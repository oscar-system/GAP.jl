@testset "packages" begin

    @test GAP.Packages.load("PackageManager")
    @test ! GAP.Packages.load("no such package")
    @test ! GAP.Packages.load("no such package", install = true)

    @test GAP.Packages.install("fga", interactive = false)
    @test GAP.Packages.remove("fga", interactive = false)

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
    if ! GAP.Globals.IsPackageLoaded(GAP.GapObj("autodoc"))
      path = string(GAP.Globals.GAPInfo.PackagesInfo.autodoc[1].InstallationPath)
      @test GAP.Packages.load(path)
    end

    # - a nonexisting path
    path = path * "xxx"
    @test ! GAP.Packages.load(path)
end
