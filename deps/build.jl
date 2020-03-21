# Builds GAP with julia GC, compiles/links GAPJulia against it,
# and exposes the right paths to julia/GAP

import Pkg

gap_version = v"4.11.0"

extra_gap_root = abspath(joinpath(@__DIR__, ".."))
gap_root = abspath(joinpath(extra_gap_root, "gap-$(gap_version)"))
install_gap = true

if haskey(ENV, "GAPROOT")
    gap_root = ENV["GAPROOT"]
    install_gap = false
end

println("gap_root = ", gap_root)
println("extra_gap_root = ", extra_gap_root)
println("install_gap = ", install_gap)

## Find julia binary
julia_binary = get(ENV, "JULIA_BINARY", Sys.BINDIR)

## Install GAP
if install_gap
    println("Installing GAP ...")
    cd(extra_gap_root)
    run(`rm -rf gap-$(gap_version)`)
    # TODO: gap-system.org availability is flaky, which often breaks CI builds; so use
    # github mirror instead, which is more reliable, albeit somewhat slower
    #filename = download("https://www.gap-system.org/pub/gap/gap-4.$(gap_version.minor)/tar.bz2/gap-$(gap_version).tar.bz2")
    filename = download("https://github.com/gap-system/gap/releases/download/v$(gap_version)/gap-$(gap_version).tar.bz2")
    run(`tar xjf $(filename)`)
    cd("gap-$(gap_version)")
    run(`./configure --with-gc=julia --with-julia=$(julia_binary)`)
    run(`make -j$(Sys.CPU_THREADS)`)

    gap_build_packages =  get(ENV, "GAP_BUILD_PACKAGES", "no")
    if gap_build_packages == "yes"
        cd("pkg")
        # eliminate a few big packages that take long to compile
        pkgs = Base.Filesystem.readdir()
        pkgs = Base.filter(x -> occursin(r"^(Normaliz|semigroups|simpcomp)", x), pkgs)
        run(`rm -rf $pkgs`)
        run(`../bin/BuildPackages.sh`)
    elseif gap_build_packages == "debug"
        cd("pkg")
        pkgs = Base.Filesystem.readdir()
        pkgs = Base.filter(x -> occursin(r"^(io|profiling)", x), pkgs)
        run(`../bin/BuildPackages.sh $pkgs`)
    end
end

##
## Compile JuliaInterface
##
println("Compiling JuliaInterface ...")
cd(abspath(joinpath(@__DIR__, "..", "pkg", "GAPJulia", "JuliaInterface")))
run(`./configure $gap_root`)
run(`make -j$(Sys.CPU_THREADS)`)

##
## Write deps.jl file containing the necessary paths
##
println("Generating deps.jl ...")

deps_string = """
GAPROOT = "$gap_root"
"""

path = abspath(joinpath(@__DIR__, "deps.jl"))
println(path)
open(path, "w") do outputfile
    print(outputfile,deps_string)
end

##
## Create custom gap.sh
##
println("Generating gap.sh ...")

gap_sh_string = """
#!/bin/sh

exec "$(gap_root)/gap" -l "$(extra_gap_root);$(gap_root)" "\$@"
"""
 
gap_sh_path = abspath(joinpath(extra_gap_root, "gap.sh"))
open(gap_sh_path, "w") do outputfile
    print(outputfile, gap_sh_string)
end

cd(extra_gap_root)
run(`chmod +x gap.sh`)
