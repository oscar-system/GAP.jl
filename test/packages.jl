@testset "packages" begin

    @test GAP.Packages.load("PackageManager")
    @test ! GAP.Packages.load("no such package")
    @test ! GAP.Packages.load("no such package", install = true)

    @test GAP.Packages.install("io", interactive = false)
    @test GAP.Packages.remove("io", interactive = false)

#    pkgdir = mktempdir()
#    @test GAP.Packages.install("io", interactive = false, pkgdir = pkgdir)
#    @test GAP.Packages.remove("io", interactive = false, pkgdir = pkgdir)

end
