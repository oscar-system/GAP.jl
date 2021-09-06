BindGlobal("DirectoriesPackageProgramsOverrides", rec());
BindGlobal("DirectoriesPackageProgramsOriginal", DirectoriesPackagePrograms);

MakeReadWriteGlobal("DirectoriesPackagePrograms");
DirectoriesPackagePrograms := function(name)
    name:= LowercaseString(name);
    if IsBound(DirectoriesPackageProgramsOverrides.(name)) then
        return [ Directory( DirectoriesPackageProgramsOverrides.(name) ) ];
    fi;
    return DirectoriesPackageProgramsOriginal(name);
end;
MakeReadOnlyGlobal("DirectoriesPackagePrograms");
