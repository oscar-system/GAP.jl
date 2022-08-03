@testset "packages" begin

    @test GAP.Packages.load("PackageManager")
    @test ! GAP.Packages.load("no such package")
    @test ! GAP.Packages.load("no such package", install = true)

    @test GAP.Packages.install("fga", interactive = false)
    @test GAP.Packages.remove("fga", interactive = false)

#    pkgdir = mktempdir()
#    @test GAP.Packages.install("fga", interactive = false, pkgdir = pkgdir)
#    @test GAP.Packages.remove("fga", interactive = false, pkgdir = pkgdir)

end
