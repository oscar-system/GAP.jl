(function()
    local deps, i, standalone, initfiles, entry;

    # Add JuliaInterface to the needed GAP packages, such that it is loaded
    # early enough for being required by other GAP packages,
    # and such that it is available when user files get read
    # via the GAP command line.
    deps:= SHALLOW_COPY_OBJ( GAPInfo.Dependencies.NeededOtherPackages );
    APPEND_LIST_INTR( deps, [ [ "JuliaInterface", ">= 0.4.4" ] ] );
    GAPInfo.Dependencies:= MakeImmutable( rec( NeededOtherPackages:= deps ) );

    # Notify that GAP.jl initiates the loading process.
    for i in [ 1 .. LEN_LIST( GAPInfo.SystemCommandLine )-1 ] do
      if GAPInfo.SystemCommandLine[i] = "-c" then
        if POSITION_SUBSTRING( GAPInfo.SystemCommandLine[i+1], "__JULIAINTERNAL_LOADED_FROM_JULIA_STAND_ALONE\", true", 0 ) <> fail then
          standalone:= true;
        elif POSITION_SUBSTRING( GAPInfo.SystemCommandLine[i+1], "__JULIAINTERNAL_LOADED_FROM_JULIA_STAND_ALONE\", false", 0 ) <> fail then
          standalone:= false;
        fi;
      fi;
    od;
    if IsBound( standalone ) then
      # Set the flag that notifies the 'JuliaInterface' package:
      # GAP.jl has initiated to load GAP.
      BIND_GLOBAL( "__JULIAINTERNAL_LOADED_FROM_JULIA", true );
    fi;
    end)();
