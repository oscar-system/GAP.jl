#
# JuliaInterface: Test interface to julia
#
# Reading the declaration part of the package.
#
_PATH_SO:=Filename(DirectoriesPackagePrograms("JuliaInterface"), "JuliaInterface.so");
if _PATH_SO <> fail then
    LoadDynamicModule(_PATH_SO);
fi;
Unbind(_PATH_SO);

ReadPackage( "JuliaInterface", "gap/JuliaInterface.gd");
