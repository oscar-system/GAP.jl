(function()
    local deps;

    # Add JuliaInterface to the needed GAP packages, such that it is loaded
    # early enough for being required by other GAP packages,
    # and such that it is available when user files get read
    # via the GAP command line.
    deps:= SHALLOW_COPY_OBJ( GAPInfo.Dependencies.NeededOtherPackages );
    APPEND_LIST_INTR( deps, [ [ "JuliaInterface", ">= 0.4.4" ] ] );
    GAPInfo.Dependencies:= MakeImmutable( rec( NeededOtherPackages:= deps ) );

    # Delay the handling of the files and "-c" commands mentioned in
    # the GAP command line, since all initializations in GAP.jl must be done
    # before they can use the GAP-Julia integration.
    # Thus we move 'InitFiles' to another variable, and provide
    # a GAP function that will be called from the 'gap.sh' script.
    # (But we have to execute the assignment of the variable
    # '__JULIAINTERNAL_LOADED_FROM_JULIA' earlier, which is used by GAP.jl
    # for checking that the GAP initializations from 'init.g' have been done.)
    GAPInfo.InitFiles_GAPjl:= GAPInfo.InitFiles;
    GAPInfo.InitFiles:= [ rec( command:= "BindGlobal( \"__JULIAINTERNAL_LOADED_FROM_JULIA\", true );" ) ];
    GAPInfo.LoadInitFiles_GAP_JL:= function()
    local result, i, f, status;
    GAPInfo.InitFiles:= GAPInfo.InitFiles_GAPjl;
    Unbind( GAPInfo.InitFiles_GAPjl );
#TODO:
# From here on, the following is essentially the code of the function
# that is called at the end of GAP's lib/init.g.
# If this function would be named, we could simply call it here.
    result:= true;
    for i in [1..LEN_LIST(GAPInfo.InitFiles)] do
        f := GAPInfo.InitFiles[i];
        if IS_REC(f) then
            status := READ_NORECOVERY(VALUE_GLOBAL("InputTextString")(f.command));
        elif VALUE_GLOBAL("EndsWith")(f, ".tst") then
            VALUE_GLOBAL("Test")(f);
            status := true;
        else
            status := READ_NORECOVERY(f);
        fi;
        if status = fail then
            result:= false;
            if IS_REC(f) then
                PRINT_TO( "*errout*", "Executing command \"", f.command,
                    "\" has been aborted.\n");
            else
                PRINT_TO( "*errout*", "Reading file \"", f,
                    "\" has been aborted.\n");
            fi;
            if i < LEN_LIST(GAPInfo.InitFiles) then
                PRINT_TO( "*errout*",
                    "The remaining files or commands on the command line will not be read.\n" );
            fi;
            break;
        elif status = false then
            result:= false;
            if IS_REC(f) then
                PRINT_TO( "*errout*", "Could not execute command \"", f.command, "\".\n" );
            else
                PRINT_TO( "*errout*", "Could not read file \"", f, "\".\n" );
            fi;
        fi;
    od;
    return result;
    end;
    end)();
