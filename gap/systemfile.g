(function()
    local deps;

    # Add JuliaInterface to the needed GAP packages, such that it is loaded
    # early enough for being required by other GAP packages,
    # and such that it is available when user files get read
    # via the GAP command line.
    deps:= SHALLOW_COPY_OBJ( GAPInfo.Dependencies.NeededOtherPackages );
    APPEND_LIST_INTR( deps, [ [ "JuliaInterface", ">=0.8.1" ] ] );
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
