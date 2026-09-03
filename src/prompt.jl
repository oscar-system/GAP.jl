#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

"""
    prompt()

Start a GAP prompt where you can enter GAP commands as in a regular GAP
session. This prompt can be left as any GAP prompt by either entering `quit;`
or pressing ctrl-D, which returns to the Julia prompt.

This GAP prompt allows to quickly switch between writing Julia and GAP code in
a session where all data is shared.
"""
function prompt()
    # Ctrl-C reaches GAP through the interrupt bridge (see signals.jl) and,
    # with the break loop enabled below, behaves as in a standalone GAP
    # session.

    # restore GAP's error output
    set_error_handler_disabled(true)
    replace_global!(:ERROR_OUTPUT, Globals._JULIAINTERFACE_ORIGINAL_ERROR_OUTPUT)

    # enable break loop
    Globals.BreakOnError = true

    # GAP's REPL takes over the terminal (raw mode, SIGTSTP/SIGWINCH handlers);
    # hand it back to Julia afterwards, even if SESSION exits abnormally.
    try
        _with_saved_signal_state(_SIGNALS_OWNED_BY_JULIA) do
            Globals.SESSION()
        end
    finally
        # disable break loop
        Globals.BreakOnError = false

        # Leaving the GAP prompt returns control to ordinary Julia code, so turn
        # GAP.jl's custom error capture back on for subsequent Julia -> GAP calls.
        set_error_handler_disabled(false)
        replace_global!(:ERROR_OUTPUT, Globals._JULIAINTERFACE_ERROR_OUTPUT)
    end
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
    @ccall JuliaInterface_path.ResetUserHasQUIT()::Cvoid

    # Finally exit
    return exit_code()
end
