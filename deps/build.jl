# Builds a GAP, and attaches JuliaInterface

import Pkg

julia_folder_path = abspath(joinpath(@__DIR__,".."))

gap_root = abspath(joinpath(julia_folder_path,"gap"))
install_gap = true

if haskey(ENV,"GAP_ROOT")
    gap_root = ENV["GAP_ROOT"]
    install_gap = false
end

## Find julia binary

julia_binary = missing

if haskey(ENV,"JULIA_BINARY")
    julia_binary = ENV["JULIA_BINARY"]
else
    julia_binary = Sys.BINDIR
end

## Install GAP
if install_gap
    cd(julia_folder_path)
    run(`git clone https://github.com/gap-system/gap`)
    cd(gap_root)
    run(`./autogen.sh`)
    run(`./configure --with-gc=julia --with-julia=$(julia_binary)`)
    run(`make`)
    if ! haskey(ENV,"GAP_INSTALL_PACKAGES") || ENV["GAP_INSTALL_PACKAGES"] == "yes" 
        run(`make bootstrap-pkg-full`)
        cd("pkg")
        run(`../bin/BuildPackages.sh`)
    elseif haskey(ENV,"GAP_INSTALL_PACKAGES") && ENV["GAP_INSTALL_PACKAGES"] == "minimal"
        run(`make bootstrap-pkg-minimal`)
    else
        run(`mkdir pkg`)
    end
end

gap_executable = abspath(joinpath(gap_root,"gap"))

## Compile JuliaInterface/Experimental
cd(abspath(joinpath(@__DIR__, "..", "pkg", "GAPJulia" )))
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

## Create custom gap.sh

gap_sh_string="""
#!/bin/sh

exec "$(gap_root)/gap" -l "$(new_gap_root);$(gap_root)" "\$@"
"""
 
gap_sh_path = abspath(joinpath(new_gap_root,"gap.sh"))
open(gap_sh_path,"w") do outputfile
    print(outputfile,gap_sh_string)
end

cd(new_gap_root)
run(`chmod +x gap.sh`)
julia_gap_sh_link = abspath(joinpath(Pkg.depots1(),"gap"))
run(`ln -snf $gap_sh_path $julia_gap_sh_link`)
