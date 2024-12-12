# Helper for replacing a GAP global variable or function by a new value.
# The original value is retained under the name `_ORIG_***`
BIND_GLOBAL("ReplaceBinding", function(name, val)
  local orig_name;
  # Store a copy of the original value, but only if that copy does not yet
  # exist. This ensures we don't overwrite it during a call to `Reread`.
  orig_name := "_ORIG_";
  APPEND_LIST_INTR(orig_name, name);
  if not ISB_GVAR(orig_name) then
    ASS_GVAR(orig_name, VAL_GVAR(name));
    MakeReadOnlyGVar(orig_name);
  fi;
  MakeReadWriteGVar(name);
  ASS_GVAR(name, val);
  MakeReadOnlyGVar(name);
end);

(function()
    local deps;

    # Add JuliaInterface to the needed GAP packages, such that it is loaded
    # early enough for being required by other GAP packages,
    # and such that it is available when user files get read
    # via the GAP command line.
    deps := [ [ "JuliaInterface", ">=0.13.0-DEV" ] ];
    if not IsBound(GAPInfo.KernelInfo.ENVIRONMENT.GAP_BARE_DEPS) then
        APPEND_LIST_INTR( deps, GAPInfo.Dependencies.NeededOtherPackages );
    fi;
    GAPInfo.Dependencies:= MakeImmutable( rec( NeededOtherPackages:= deps ) );

    # force the --norepl option to be on
    GAPInfo.CommandLineOptions_original := GAPInfo.CommandLineOptions;
    GAPInfo.CommandLineOptions := SHALLOW_COPY_OBJ( GAPInfo.CommandLineOptions );
    GAPInfo.CommandLineOptions.norepl := true;

    # Delay the handling of the files and "-c" commands mentioned in
    # the GAP command line, since all initializations in GAP.jl must be done
    # before they can use the GAP-Julia integration.
    # Thus we move 'InitFiles' to another variable, and provide
    # a GAP function that will be called from the 'gap.sh' script.
    GAPInfo.InitFiles_GAPjl:= GAPInfo.InitFiles;
    GAPInfo.InitFiles:= [];
    GAPInfo.LoadInitFiles_GAP_JL:= function()
        GAPInfo.InitFiles:= GAPInfo.InitFiles_GAPjl;
        Unbind( GAPInfo.InitFiles_GAPjl );
        VALUE_GLOBAL("ProcessInitFiles")(GAPInfo.InitFiles);
    end;
    end)();
