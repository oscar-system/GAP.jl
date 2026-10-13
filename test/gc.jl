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

# Regression tests for the GAP garbage collector integration. Those for the
# conservative scanning of task stacks use the technique described in
# test/gc_common.jl.

include("gc_common.jl")

# Run a test script in a subprocess, as some failures are crashes; returns
# whether it succeeded and its output.
function run_gc_script(name, flags = ``)
    script = joinpath(@__DIR__, name)
    cmd = `$(Base.julia_cmd()) $flags --project=$(Base.active_project()) $(script)`
    mktemp() do path, out
        p = run(pipeline(cmd; stdout = out, stderr = out); wait = false)
        if timedwait(() -> !process_running(p), 300) == :timed_out
            kill(p)
            wait(p)
        end
        close(out)
        return success(p), read(path, String)
    end
end

@testset "GC and task stacks" begin
    victim = GCTestHelpers.make_gap_victim("Julia.Main.GCTestHelpers.jwait(jch)")

    # run one victim iteration per call of `gc`, which is invoked while the
    # victim task is parked inside take!
    next_id = Ref(0)
    function run_victim(n, gc)
        off = next_id[]
        next_id[] += n
        GCTestHelpers.ensure_canaries(off + n)
        ch = Channel{Int}()
        res = Ref(-1)
        t = @task (res[] = victim(ch, n, off))
        bind(ch, t)   # a failing victim closes the channel instead of hanging us
        schedule(t)
        yield()
        keepalive = GapObj[]
        for i in 1:n
            GCTestHelpers.pad!(keepalive, i)
            gc()
            put!(ch, 0)
            yield()
        end
        wait(t)
        return res[]
    end

    # automatic collections (the only kind that historically took the buggy
    # code path)
    @test run_victim(60, GCTestHelpers.churn_until_auto_gc) == 0

    # explicit incremental collections
    @test run_victim(30, () -> GC.gc(false)) == 0

    # a task on a second thread that never task-switches while holding a bag
    # only in a C stack temporary; needs a multi-threaded subprocess, and
    # --gcthreads=2 additionally exercises the task scanner callback on
    # parallel GC mark threads
    run_threads_script() = run_gc_script("gc_threads_script.jl", `-t2 --gcthreads=2`)
    ok, output = run_threads_script()
    if !ok
        # retry once, e.g. after a timeout from an unlucky scheduling
        ok, output = run_threads_script()
    end
    ok || println(output)
    @test ok
end

@testset "GC marking" begin
    # a dead master pointer on the stack whose bag body has been freed
    ok, output = run_gc_script("gc_freed_body_script.jl")
    ok || println(output)
    @test ok
end
