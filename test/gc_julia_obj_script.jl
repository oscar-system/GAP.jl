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

# Run by test/gc.jl in a subprocess with --gcthreads=1, which fixes the order
# in which the collector scans the remembered set.
#
# An old bag has to stay in the remembered set while it references a young
# Julia object, also if the collector reached that object through another
# reference before it scanned the bag.
#
# Each round lets `CLONE_OBJ` turn old lists into wrapper bags of fresh
# canaries (see test/gc_common.jl); a wrapper bag is otherwise never older
# than its Julia object. This puts the bags into the remembered set. Then the
# canaries are stored in the old vector `KEEP`, which enters the remembered
# set after the bags and is therefore scanned before them. After a collection
# the references in `KEEP` are removed. In the next collection no canary may
# die, as the bags still reference all of them.

using GAP

include(joinpath(@__DIR__, "gc_common.jl"))

const N = 500
const ROUNDS = 20
const KEEP = Any[nothing for _ in 1:N]

new_lists = GAP.evalstr("n -> List([1..n], i -> [i])")

clone_all = GAP.evalstr("""
function(bags, wrappers)
  local i;
  for i in [1..Length(bags)] do
    CLONE_OBJ(bags[i], wrappers[i]);
  od;
end;""")

# a function of its own, so that afterwards only `KEEP` and the bags
# reference the canaries
@noinline function wrap_canaries(clone_all, bags, ids)
    canaries = Any[GCTestHelpers.make_canary(id) for id in ids]
    clone_all(bags, GapObj(canaries))
    copyto!(KEEP, canaries)
    return nothing
end

function main(new_lists, clone_all)
    GCTestHelpers.ensure_canaries(N * ROUNDS)
    bags = new_lists(N)
    GC.gc(true)

    for r in 1:ROUNDS
        ids = ((r - 1) * N + 1):(r * N)
        GC.gc(false)   # the bags and `KEEP` are old and marked from here on
        wrap_canaries(clone_all, bags, ids)
        GC.gc(false)
        fill!(KEEP, nothing)
        GC.gc(false)
        freed = count(@view GCTestHelpers.freed[ids])
        if freed > 0
            println("round ", r, ": ", freed, " of ", N, " canaries freed while live")
            exit(1)
        end
    end
    println("no canary freed while live in ", ROUNDS, " rounds")
    exit(0)
end

main(new_lists, clone_all)
