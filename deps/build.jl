# Builds a GAP, and attaches JuliaInterface

gap_root = abspath(joinpath(@__DIR__,"gap"))
install_gap = true

if haskey(ENV,"GAP_ROOT")
    gap_root = ENV["GAP_ROOT"]
    install_gap = false
end

## Install GAP

if install_gap
    run(`git clone https://github.com/gap-system/gap`)
    cd(gap_root)
    run(`./autogen.sh`)
    run(`./configure --with-gc=julia --with-julia=$(ENV["_"])`)
    run(`make`)
    if ! haskey(ENV,"GAP_INSTALL_PACKAGES") && ENV["GAP_INSTALL_PACKAGES"] != "no"
        run(`make bootstrap-pkg-full`)
        cd("pkg")
        run(`../bin/BuildPackages.sh`)
    else
        run(`mkdir pkg`)
    end
end

gap_executable = abspath(joinpath(gap_root,"gap"))

## Compile JuliaInterface/Experimental
cd(abspath(joinpath(@__DIR__,"..","pkg")))
run(`./configure $gap_root`)
run(`make`)

new_gap_root = abspath(joinpath(@__DIR__,".."))

## Write deps.jl file containing the necessary paths
deps_string ="""
GAP_ROOT = "$gap_root"
GAP_EXECUTABLE = "$gap_executable"
GAP_ADDITIONAL_ROOT = "$new_gap_root"

"""

open(abspath(joinpath(@__DIR__,"deps.jl")),"w") do outputfile
    print(outputfile,deps_string)
end
