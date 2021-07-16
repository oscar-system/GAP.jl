# Given a path to a GAP compiled against Julia, setup
# a fake GAP_jll root dir suitable for a package override
using Libdl

length(ARGS) in [1,2] || error("usage: ")
# TODO: make the following two dirs configurable (the first one a required
# argument, the second an optional one)
srcdir = ARGS[1]
dstdir = length(ARGS) == 2 ? ARGS[2] : "fake_GAP_jll"

rm(dstdir; force = true, recursive = true)
mkdir(dstdir)

mkdir(joinpath(dstdir, "bin"))
mkdir(joinpath(dstdir, "lib"))
mkdir(joinpath(dstdir, "include"))
mkdir(joinpath(dstdir, "share"))
mkdir(joinpath(dstdir, "share", "gap"))

symlink(joinpath(srcdir, "gap"), joinpath(dstdir, "bin", "gap"))
symlink(joinpath(srcdir, "src"), joinpath(dstdir, "include", "gap"))
symlink(joinpath(srcdir, "gac"), joinpath(dstdir, "share", "gap", "gac"))
symlink(joinpath(srcdir, "sysinfo.gap"), joinpath(dstdir, "share", "gap", "sysinfo.gap"))

for f in filter(endswith(Libdl.dlext), readdir(joinpath(srcdir, ".libs")))
    symlink(joinpath(srcdir, ".libs", f), joinpath(dstdir, "lib", f))
end
