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

# Run by test/gc.jl in a subprocess with -t2: a task on a second thread runs
# GAP and busy-waits inside a Julia call without ever task-switching, while
# the main thread triggers automatic collections. The task's C stack, which
# holds the only reference to a bag, must still be scanned. See
# test/gc_common.jl for the technique.

using GAP

include(joinpath(@__DIR__, "gc_common.jl"))

victim = GCTestHelpers.make_gap_victim("Julia.Main.GCTestHelpers.jspin(off + i)")

@assert Threads.nthreads() >= 2

const N = 40
GCTestHelpers.ensure_canaries(N)
res = Ref(-1)
t = Threads.@spawn (res[] = victim(0, N, 0))

keepalive = GapObj[]
for i in 1:N
    while GCTestHelpers.spin_state[] < i
        istaskdone(t) && break   # don't spin forever if the victim failed
        yield()
    end
    istaskdone(t) && break
    # the victim is now busy-spinning on the other thread and GAP is not
    # entered concurrently, so allocating GAP objects from here is fine
    GCTestHelpers.pad!(keepalive, i)
    GCTestHelpers.churn_until_auto_gc()
    GCTestHelpers.go[] = i
end
wait(t)

println("canaries freed while live: ", res[], " of ", N)
exit(res[] == 0 ? 0 : 1)
