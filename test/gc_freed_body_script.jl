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

# Run by test/gc.jl in a subprocess, as the failure is a segfault inside the
# garbage collector.
#
# The GC must not mark the body of a bag through its master pointer after
# Julia has freed the body. The test produces dead master pointers that the
# sweep leaves alone while it frees the pages holding their bodies, and then
# lets the conservative stack scan find them:
#
# 1. Lists `x` and `y` are allocated alternately. Their master pointers share
#    pages; their bodies differ in size and hence are on different pages. The
#    bodies of the `x` are large, since few other objects compete for pages
#    of that size class and a page holds only a few of them.
# 2. A collection promotes all of them to the old generation.
# 3. The `x` are dropped and a second collection marks the `y`. The pages
#    with the master pointers now hold marked objects and have not received
#    new ones, so a quick sweep skips them. The pages with the bodies of the
#    `x` hold no marked object and are freed as a whole, which leaves the
#    type tags of the bodies in place.
# 4. Further collections run while the address of a dead `x` is on the stack.

using GAP

make_lists = GAP.evalstr("""
function(n)
  local xs, ys, i;
  xs := EmptyPlist(n);
  ys := EmptyPlist(n);
  for i in [1..n] do
    xs[i] := EmptyPlist(200);
    ys[i] := [i];
  od;
  return [xs, ys];
end;""")

clear_list = GAP.evalstr("""
function(xs)
  local i;
  for i in [1..Length(xs)] do
    xs[i] := 0;
  od;
end;""")

# a function of its own, so that no copy of an address stays on the stack
@noinline addresses(xs, idxs) = UInt[UInt(pointer_from_objref(xs[i])) for i in idxs]

# `addr` has to survive the call, in a callee-saved register or in a stack
# slot of this frame; the conservative scan sees both
@noinline function collect_with_stack_word(addr::UInt)
    GC.gc(false)
    return addr
end

const keepalive = Any[]

# Returns `false` if Julia did not run exactly the two quick collections that
# steps 2 and 3 need; only a quick sweep skips pages.
function run_round(make_lists, clear_list, n)
    GC.gc(false)   # so that Julia does not collect on its own in this round
    before = Base.gc_num()
    lists = make_lists(n)
    push!(keepalive, lists)
    xs = lists[1]

    GC.gc(false)
    # the first bodies fill free cells of pages that hold unrelated objects,
    # the last ones are on the page that is still being allocated from
    addrs = addresses(xs, (n ÷ 2):(n ÷ 64):(n - n ÷ 16))
    clear_list(xs)
    GC.gc(false)

    after = Base.gc_num()
    after.pause == before.pause + 2 || return false
    after.full_sweep == before.full_sweep || return false

    for addr in addrs
        collect_with_stack_word(addr)
    end
    return true
end

const ROUNDS = 3
const ATTEMPTS = 20

function main(make_lists, clear_list)
    done = 0
    for _ in 1:ATTEMPTS
        done += run_round(make_lists, clear_list, 4000)
        done == ROUNDS && break
    end
    println("rounds with two quick collections: ", done, " of ", ROUNDS)
    exit(done == ROUNDS ? 0 : 1)
end

main(make_lists, clear_list)
