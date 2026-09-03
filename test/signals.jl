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

# Pins the ownership contract of docs/src/signals.md. Runs early, before
# tests load GAP packages that install handlers of their own.

@testset "signal ownership contract" begin
    infos = GAP.signal_report(devnull)
    @test infos isa Vector{GAP.SignalInfo}
    @test GAP.signal_report(devnull; all = true) isa Vector{GAP.SignalInfo}

    owner(name) = infos[findfirst(info -> info.name == name, infos)].owner

    # Julia's GC safepoints and error reporting depend on its fault handlers
    for name in ("SIGSEGV", "SIGBUS", "SIGILL", "SIGFPE")
        @test owner(name) == :julia
    end

    # Ctrl-C is delivered by Julia; GAP.jl only chains onto it
    @test owner("SIGINT") in (:julia, :JuliaInterface)

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

# io <= 4.10.0 reaps with waitpid(-1), after which Julia's subprocess handling
# hangs. Opt-in (a hang costs the whole timeout), and in a subprocess so the
# hang cannot poison this one.
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
