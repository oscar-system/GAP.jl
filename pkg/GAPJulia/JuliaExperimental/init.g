#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# Reading the declaration part of the package.

_PATH_SO:=Filename(DirectoriesPackagePrograms("JuliaExperimental"), "JuliaExperimental.so");
if _PATH_SO <> fail then
    LoadDynamicModule(_PATH_SO);
fi;
Unbind(_PATH_SO);

