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

# Shared machinery of the task stack scanning regression tests in test/gc.jl
# and test/gc_threads_script.jl, see
# https://github.com/oscar-system/GAP.jl/issues/1032 and
# https://github.com/oscar-system/GAP.jl/issues/1224.
#
# Technique: a GAP function evaluates `pair(make_canary(off + i), <block>)`.
# While the second argument runs Julia code, the wrapper bag of the canary
# object created for the first argument is referenced only from a C stack
# frame of the task running GAP (the argument temporary of the GAP kernel's
# function call evaluation). If the GC fails to scan that task's stack, the
# bag and with it the canary are collected while still live; the canary's
# finalizer records this, keyed by a per-canary id (a shared flag would give
# false positives from the natural death of the previous iteration's canary).

module GCTestHelpers

using GAP

# one slot per canary id; written only by that canary's finalizer, so no
# locking is needed (finalizers must not block on a lock anyway). Ids are
# never reused and the vector never shrinks, as canaries of an earlier test
# may be finalized while a later one runs.
const freed = Bool[]

ensure_canaries(n) = length(freed) < n && append!(freed, falses(n - length(freed)))

function make_canary(id)
    c = Ref(Int(id))
    finalizer(_ -> (freed[Int(id)] = true), c)
    return c
end

canary_was_freed(id) = freed[Int(id)]

pair(a, b) = 0

# blocker for test/gc.jl: park the task until the driver wakes it
jwait(ch) = (take!(ch); 0)

# blocker for test/gc_threads_script.jl: busy-wait on another thread
const spin_state = Threads.Atomic{Int}(0)
const go = Threads.Atomic{Int}(0)
function jspin(id)
    spin_state[] = Int(id)
    while go[] < Int(id)
        GC.safepoint()   # participate in stop-the-world, but never task-switch
    end
    return 0
end

# the GAP victim function; `blocker` is GAP code for the blocking second
# argument, using the locals `jch`, `i` and `off`
function make_gap_victim(blocker::String)
    return GAP.evalstr("""
    function(jch, n, off)
      local i, s, bad;
      bad := 0;
      for i in [1..n] do
        s := Julia.Main.GCTestHelpers.pair(
                 Julia.Main.GCTestHelpers.make_canary(off + i),
                 $(blocker));
        if Julia.Main.GCTestHelpers.canary_was_freed(off + i) then
          bad := bad + 1;
        fi;
      od;
      return bad;
    end;""")
end

# churn allocations until at least one automatic collection has run. The
# budget must be generous: only an *automatic* collection takes the code
# paths under test, an explicit one does not.
const junk = Any[]
function churn_until_auto_gc()
    n0 = Base.gc_num().pause
    for k in 1:5_000_000
        Base.gc_num().pause == n0 || break
        push!(junk, zeros(128))
        length(junk) > 200_000 && empty!(junk)
    end
    empty!(junk)
    # last resort so the test cannot spin forever
    Base.gc_num().pause == n0 && GC.gc(false)
end

# allocate a varying number of GAP objects, kept alive, so that the victim's
# next wrapper bag gets a fresh master pointer cell rather than accidentally
# reusing one from a freed predecessor
function pad!(keepalive, i)
    for k in 1:(1 + i % 7)
        push!(keepalive, GapObj("pad $i $k"))
    end
end

end
