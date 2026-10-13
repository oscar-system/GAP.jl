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

# Run by test/gc.jl in a subprocess with --gcthreads=2.
#
# An old bag has to stay in the remembered set while it references a young
# bag; otherwise the next collection that does not reach the young bag in
# another way frees it. With several GC threads, the thread scanning the old
# bag can lose the race for marking the young one, and has to count the
# reference all the same.
#
# Each round stores fresh wrapped canaries (see test/gc_common.jl) into old
# lists, such that each canary is referenced by one list in `a` and by one in
# `b`. In the first collection the two lists holding a canary are scanned
# from the remembered set, possibly by different threads. Then the references
# from `a` are removed. In the second collection no canary may die, as `b`
# still references all of them.

using GAP
using Random

include(joinpath(@__DIR__, "gc_common.jl"))

@assert Threads.ngcthreads() >= 2

new_lists = GAP.evalstr("n -> List([1..n], i -> [0])")

fill_lists = GAP.evalstr("""
function(a, off)
  local i;
  for i in [1..Length(a)] do
    a[i][1] := Julia.Main.GCTestHelpers.make_canary(off + i);
  od;
end;""")

share_entries = GAP.evalstr("""
function(a, b, q)
  local j;
  for j in [1..Length(b)] do
    b[j][1] := a[q[j]][1];
  od;
end;""")

clear_lists = GAP.evalstr("""
function(a)
  local i;
  for i in [1..Length(a)] do
    a[i][1] := 0;
  od;
end;""")

const N = 5000
const ROUNDS = 300

function main(new_lists, fill_lists, share_entries, clear_lists)
    GCTestHelpers.ensure_canaries(N * ROUNDS)
    a = new_lists(N)
    b = new_lists(N)
    # the two lists holding a canary get far apart in the remembered set
    q = GapObj(randperm(N))
    GC.gc(true)

    for r in 1:ROUNDS
        off = (r - 1) * N
        fill_lists(a, off)
        share_entries(a, b, q)
        GC.gc(false)
        clear_lists(a)
        GC.gc(false)
        freed = count(@view GCTestHelpers.freed[(off + 1):(off + N)])
        if freed > 0
            println("round ", r, ": ", freed, " of ", N, " canaries freed while live")
            exit(1)
        end
    end
    println("no canary freed while live in ", ROUNDS, " rounds")
    exit(0)
end

main(new_lists, fill_lists, share_entries, clear_lists)
