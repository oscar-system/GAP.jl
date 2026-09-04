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

# These tests pin the signal ownership contract described in
# docs/src/signals.md. They run early, before any test exercises GAP
# packages that install handlers of their own.

@testset "signal ownership contract" begin
    infos = GAP.signal_report(devnull)
    @test infos isa Vector{GAP.SignalInfo}
    @test GAP.signal_report(devnull; all = true) isa Vector{GAP.SignalInfo}

    owner(name) = infos[findfirst(info -> info.name == name, infos)].owner

    # Julia's GC safepoints and error reporting depend on its fault handlers
    for name in ("SIGSEGV", "SIGBUS", "SIGILL", "SIGFPE")
        @test owner(name) == :julia
    end

    # Ctrl-C is delivered by Julia; GAP.jl chains onto Julia's handler
    @test owner("SIGINT") == :JuliaInterface

    # SIGCHLD belongs to libuv; neither GAP's `ChildStatusChanged` nor io's
    # handler may remain installed after startup
    @test owner("SIGCHLD") ∉ (:gap, :io)

    # The terminal belongs to the Julia REPL while no GAP prompt is active
    @test owner("SIGTSTP") ∉ (:gap, :ncurses)
    @test owner("SIGWINCH") ∉ (:gap, :ncurses)
end

@testset "Julia subprocesses survive GAP initialization" begin
    # A hang here means GAP or a package reaped Julia's child or replaced
    # libuv's SIGCHLD handler; the watchdog turns that into a failure.
    task = @async success(`true`)
    @test timedwait(() -> istaskdone(task), 60.0) == :ok
    @test istaskdone(task) && fetch(task)
end

@testset "interrupt bridge" begin
    GAP.evalstr("""
    gapjl_signals_spin := function()
        local i;
        i := 0;
        while true do i := i + 1; od;
    end;;
    """)

    # what the SIGINT handler does while GAP code executes
    @ccall GAP.libgap.InterruptExecStat()::Cvoid
    @test_throws InterruptException GAP.Globals.gapjl_signals_spin()

    # the bridge's bookkeeping and GAP itself are intact afterwards
    @test unsafe_load(GAP._gap_depth_ptr[]) == 0
    @test GAP.evalstr("1 + 1") == 2

    # nested Julia -> GAP -> Julia -> GAP: the innermost runtime owns Ctrl-C
    depth_inside_julia = Ref{Cint}(-1)
    probe = () -> (depth_inside_julia[] = unsafe_load(GAP._gap_depth_ptr[]); nothing)
    GAP.Globals.CallFuncList(GAP.WrapJuliaFunc(probe), GapObj([]))
    @test depth_inside_julia[] == 0
    @test unsafe_load(GAP._gap_depth_ptr[]) == 0
end

# Run `script` in a fresh Julia process, wait for it to print `marker`, send
# it SIGINT, and return (exited in time, captured output after the marker)
function interrupt_subprocess(script::String, marker::String)
    cmd = `$(Base.julia_cmd()) --project=$(Base.active_project()) -e $script`
    output = Pipe()
    proc = run(pipeline(cmd; stdout = output, stderr = devnull); wait = false)
    close(output.in)
    # GAP may have emitted a carriage return on stdout before the marker
    @test strip(readline(output)) == marker
    # let the process get past the code that printed the marker
    sleep(1)
    kill(proc, Base.SIGINT)
    exited = timedwait(() -> process_exited(proc), 60.0) == :ok
    exited || kill(proc, Base.SIGKILL)
    return exited, read(output, String)
end

@testset "SIGINT during a GAP computation" begin
    script = """
        using GAP
        Base.exit_on_sigint(false)
        # GAP prints the marker via a Julia callback right before it starts
        # spinning, so GAP is executing when the signal arrives
        GAP.Globals.gapjl_ready = GAP.WrapJuliaFunc(() -> (println("GAP_RUNNING"); flush(stdout); nothing))
        try
            GAP.evalstr("gapjl_ready(); while true do od;")
        catch err
            println("caught ", typeof(err))
            exit(err isa InterruptException ? 0 : 1)
        end
        exit(2)
    """
    exited, output = interrupt_subprocess(script, "GAP_RUNNING")
    @test exited
    @test occursin("caught InterruptException", output)
end

@testset "SIGINT during Julia code still reaches Julia" begin
    script = """
        using GAP
        Base.exit_on_sigint(false)
        println("JULIA_RUNNING"); flush(stdout)
        try
            while true; sleep(0.05); end
        catch err
            println("caught ", typeof(err))
            exit(err isa InterruptException ? 0 : 1)
        end
    """
    exited, output = interrupt_subprocess(script, "JULIA_RUNNING")
    @test exited
    @test occursin("caught InterruptException", output)
end

# The io package still reaps with waitpid(-1) and installs its own SIGCHLD
# handler whenever its process functions run, which breaks Julia's
# subprocess handling afterwards. Verified in a subprocess so that the hang
# cannot poison this test process; opt-in because a broken run costs the
# whole timeout. Expected to pass once io >= 4.10.1 ships in GAP_pkg_io_jll.
if get(ENV, "GAPJL_TEST_SIGNALS_IO", "") == "1"
  @testset "Julia subprocesses after io package usage" begin
    script = """
        using GAP
        GAP.evalstr("LoadPackage(\\"IO\\");; pid := IO_fork();; if pid = 0 then IO_exit(0); fi; IO_WaitPid(pid, true);;")
        run(`true`)
    """
    cmd = `$(Base.julia_cmd()) --project=$(Base.active_project()) -e $script`
    proc = run(pipeline(cmd; stdout = devnull, stderr = devnull); wait = false)
    finished = timedwait(() -> process_exited(proc), 120.0) == :ok
    finished || kill(proc, Base.SIGKILL)
    @test_broken finished && success(proc)
  end
end
