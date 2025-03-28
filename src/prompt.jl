"""
    prompt()

Start a GAP prompt where you can enter GAP commands as in a regular GAP
session. This prompt can be left as any GAP prompt by either entering `quit;`
or pressing ctrl-D, which returns to the Julia prompt.

This GAP prompt allows to quickly switch between writing Julia and GAP code in
a session where all data is shared.
"""
function prompt()
    global disable_error_handler

    # save the current SIGINT handler
    # (we pass NULL as signal handler; strictly speaking, we should be passing `SIG_DFL`
    # but it's not clearly how to access this from here, and anyway on the list
    # of platforms we support, it is NULL)
    old_sigint = @ccall signal(Base.SIGINT::Cint, C_NULL::Ptr{Cvoid})::Ptr{Cvoid} 

    # install GAP's SIGINT handler
    @ccall libgap.SyInstallAnswerIntr()::Cvoid

    # restore GAP's error output
    disable_error_handler[] = true
    replace_global!(:ERROR_OUTPUT, Globals._JULIAINTERFACE_ORIGINAL_ERROR_OUTPUT)

    # enable break loop
    Globals.BreakOnError = true

    # start GAP repl
    Globals.SESSION()

    # disable break loop
    Globals.BreakOnError = false

    # restore signal handler
    @ccall signal(Base.SIGINT::Cint, old_sigint::Ptr{Cvoid})::Ptr{Cvoid}

    # restore GAP.jl error handler
    disable_error_handler[] = false
    replace_global!(:ERROR_OUTPUT, Globals._JULIAINTERFACE_ERROR_OUTPUT)
end

# helper function for `gap.sh` scripts created by create_gap_sh()
function run_session()

    # Read the files from the GAP command line.
    @ccall libgap.Call0ArgsInNewReader(Globals.GAPInfo.LoadInitFiles_GAP_JL::Any)::Cvoid

    # GAP.jl forces the norepl option, which means that init.g never
    # starts a GAP session; we now run one "manually". Note that this
    # may throw a "GAP exception", which we need to catch; thus we
    # use Call0ArgsInNewReader to perform the actual call.
    if !Globals.GAPInfo.CommandLineOptions_original.norepl
        @ccall libgap.Call0ArgsInNewReader(Globals.SESSION::Any)::Cvoid
    end

    # Reset the GAP kernel variable `UserHasQUIT` so that GAP's exit handlers
    # can run. This is necessary if the user passed a file on the command line
    # that has a `QUIT` statements, thus ending GAP during ProcessInitFiles,
    # hence before the first SESSION.
    #
    # Note that in this case, even our manual call to SESSION above actually
    # ends up doing nothing as a side effect of `UserHasQUIT` being non-zero
    # (it aborts after its first call to a function, which happens to be
    # `GetBottomLVars()`).
    @ccall JuliaInterface_path().ResetUserHasQUIT()::Cvoid

    # Finally exit
    return exit_code()
end
