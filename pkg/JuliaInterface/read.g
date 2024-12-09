#
# JuliaInterface: Test interface to julia
#
# Reading the implementation part of the package.
#
ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

ReadPackage( "JuliaInterface", "gap/adapter.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");
ReadPackage( "JuliaInterface", "gap/helpstring.g");
ReadPackage( "JuliaInterface", "gap/juliahelp.g");

# HACK: we need to set up the GAP package override system as early as possible.
# Since JuliaInterface is loaded before all other packages, putting it here
# ensures that
BindGlobal("DirectoriesPackageProgramsOverrides", rec());

BindGlobal("_DirectoriesPackageProgramsOriginal", DirectoriesPackagePrograms);
MakeReadWriteGlobal("DirectoriesPackagePrograms");
DirectoriesPackagePrograms := function(name)
    name:= LowercaseString(name);
    if IsBound(DirectoriesPackageProgramsOverrides.(name)) then
        return [ Directory( DirectoriesPackageProgramsOverrides.(name) ) ];
    fi;
    return _DirectoriesPackageProgramsOriginal(name);
end;
MakeReadOnlyGlobal("DirectoriesPackagePrograms");

# set up overrides for a few package JLLs
Julia.GAP.setup_gap_pkg_overrides();
