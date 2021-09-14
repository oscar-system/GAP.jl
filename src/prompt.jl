function gap_exe()
    return joinpath(GAPROOT, "bin", "gap.sh")
end

export gap_exe

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
    old_sigint = ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), Base.SIGINT, C_NULL)

    # install GAP's SIGINT handler
    ccall((:SyInstallAnswerIntr, libgap), Cvoid, ())

    # restore GAP's error output
    disable_error_handler[] = true
    Globals.MakeReadWriteGlobal(GapObj("ERROR_OUTPUT"))
    evalstr("""ERROR_OUTPUT:= "*errout*";""")
    Globals.MakeReadOnlyGlobal(GapObj("ERROR_OUTPUT"))

    # enable break loop
    Globals.BreakOnError = true

    # start GAP repl
    Globals.SESSION()

    # disable break loop
    Globals.BreakOnError = false

    # restore signal handler
    ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), Base.SIGINT, old_sigint)

    # restore GAP.jl error handler
    disable_error_handler[] = false
    reset_GAP_ERROR_OUTPUT()
end
