#############################################################################
##
##  JuliaInterface package
##
##  Override various GAP library functions
##
#############################################################################

ReplaceBinding("ExecuteProcess", GAP_jl.GAP_ExecuteProcess);

ReplaceBinding("DirectoriesPackagePrograms",
function(name)
    local info, installationpath, override;

    # We are not allowed to call
    # `InstalledPackageVersion', `TestPackageAvailability' etc.
    name:= LowercaseString( name );
    info:= PackageInfo( name );
    if IsBound( GAPInfo.PackagesLoaded.( name ) ) then
      # The package is already loaded.
      installationpath:= GAPInfo.PackagesLoaded.( name )[1];
    elif IsBound( GAPInfo.PackageCurrent ) and
         LowercaseString( GAPInfo.PackageCurrent.PackageName ) = name then
      # The package in question is currently going to be loaded.
      installationpath:= GAPInfo.PackageCurrent.InstallationPath;
    elif 0 < Length( info ) then
      # Take the installed package with the highest version
      # that has been found first in the root paths.
      installationpath:= info[1].InstallationPath;
    else
      # This package is not known.
      return [];
    fi;

    override := JuliaToGAP( IsString, GAP_jl.find_override(GAPToJulia(installationpath)) );
    return [ Directory( override ) ];
end);
