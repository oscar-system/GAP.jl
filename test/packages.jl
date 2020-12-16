@testset "packages" begin

    @test GAP.Packages.load("PackageManager")
    @test ! GAP.Packages.load("no such package")
    @test ! GAP.Packages.load("no such package", install = true)

    tmproot = mktempdir()
    pkgdir = joinpath(tmproot, "pkg")
    mkpath(pkgdir)
    GG = GAP.Globals
    GG.GAPInfo.RootPaths = GG.Concatenation(GapObj([tmproot]; recursive = true), GG.GAPInfo.RootPaths)

    #GAP.Globals.ExtendRootDirectories(GapObj([tmproot * "/"]; recursive=true))
    @test GAP.Packages.install("io", interactive = false, pkgdir = pkgdir)
    @test GAP.Packages.remove("io", interactive = false, pkgdir = pkgdir)

end
