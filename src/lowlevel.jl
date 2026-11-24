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

#
# Define a constant for each entry of a transcription of `enum TNUM` from
# GAP's `src/objects.h`, numbered as the C compiler does it, plus the tuple
# `TNUM_NAMES` of all their names. The range macros of `objects.h` are
# supported: `START_*` and `END_*` entries name a boundary without taking a
# number, `*_EVEN` entries start at an even number (leaving the odd one for
# the immutable variant), `*_ODD` entries end at an odd number.
#
macro tnum_enum(block)
    defs = Expr[]
    names = Symbol[]
    next = 0
    for ex in block.args
        ex isa LineNumberNode && continue

        if ex isa Symbol
            name, value = ex, next
            next = value + 1
        elseif Meta.isexpr(ex, :(=))
            name, value = ex.args
            next = value + 1
        elseif Meta.isexpr(ex, :call)
            op, name = ex.args
            if op === :START_ENUM_RANGE
                value = next
            elseif op === :START_ENUM_RANGE_EVEN
                value = next = next + isodd(next)
            elseif op === :NEXT_ENUM_EVEN
                value = next + isodd(next)
                next = value + 1
            elseif op === :END_ENUM_RANGE
                value = next - 1
            elseif op === :END_ENUM_RANGE_ODD
                value = next - iseven(next)
                next = value + 1
            else
                error("unsupported TNUM range macro: $op")
            end
        else
            error("unsupported TNUM entry: $ex")
        end

        push!(names, name)
        push!(defs, :(const $(esc(name)) = $value))
    end
    return Expr(:block, defs..., :(const $(esc(:TNUM_NAMES)) = $(Tuple(names))))
end

#
# The TNUM values must be compile time constants, so they cannot be queried
# from GAP; `initialize` verifies them against the GAP globals of the same
# names instead. To update this, copy `enum TNUM` from `src/objects.h`,
# remove the commas and the HPCGAP sections, and replace `//` by `#`.
#
@tnum_enum begin
    START_ENUM_RANGE(FIRST_REAL_TNUM)

    START_ENUM_RANGE(FIRST_CONSTANT_TNUM)

        # The next range contains all constant TNUMs for which multiplication
        # with an integer resp. powering by an integer makes sense
        START_ENUM_RANGE(FIRST_MULT_TNUM)
            T_INT      # immediate
            T_INTPOS
            T_INTNEG
            T_RAT
            T_CYC
            T_FFE      # immediate
            T_MACFLOAT
            T_PERM2
            T_PERM4
            T_TRANS2
            T_TRANS4
            T_PPERM2
            T_PPERM4
        END_ENUM_RANGE(LAST_MULT_TNUM)

        T_BOOL
        T_CHAR

        T_FUNCTION
        T_BODY     # the type of function body bags
        T_FLAGS
        T_LVARS
        T_HVARS
    END_ENUM_RANGE(LAST_CONSTANT_TNUM)

    # first mutable/immutable TNUM
    START_ENUM_RANGE_EVEN(FIRST_IMM_MUT_TNUM)

        # records
        START_ENUM_RANGE_EVEN(FIRST_RECORD_TNUM)
            T_PREC
        END_ENUM_RANGE_ODD(LAST_RECORD_TNUM)

        # lists
        START_ENUM_RANGE_EVEN(FIRST_LIST_TNUM)

            # plists
            START_ENUM_RANGE_EVEN(FIRST_PLIST_TNUM)
                NEXT_ENUM_EVEN(T_PLIST)
                NEXT_ENUM_EVEN(T_PLIST_NDENSE)
                NEXT_ENUM_EVEN(T_PLIST_DENSE)
                NEXT_ENUM_EVEN(T_PLIST_DENSE_NHOM)
                NEXT_ENUM_EVEN(T_PLIST_DENSE_NHOM_SSORT)
                NEXT_ENUM_EVEN(T_PLIST_DENSE_NHOM_NSORT)
                NEXT_ENUM_EVEN(T_PLIST_EMPTY)
                NEXT_ENUM_EVEN(T_PLIST_HOM)
                NEXT_ENUM_EVEN(T_PLIST_HOM_NSORT)
                NEXT_ENUM_EVEN(T_PLIST_HOM_SSORT)
                NEXT_ENUM_EVEN(T_PLIST_TAB)
                NEXT_ENUM_EVEN(T_PLIST_TAB_NSORT)
                NEXT_ENUM_EVEN(T_PLIST_TAB_SSORT)
                NEXT_ENUM_EVEN(T_PLIST_TAB_RECT)
                NEXT_ENUM_EVEN(T_PLIST_TAB_RECT_NSORT)
                NEXT_ENUM_EVEN(T_PLIST_TAB_RECT_SSORT)
                NEXT_ENUM_EVEN(T_PLIST_CYC)
                NEXT_ENUM_EVEN(T_PLIST_CYC_NSORT)
                NEXT_ENUM_EVEN(T_PLIST_CYC_SSORT)
                NEXT_ENUM_EVEN(T_PLIST_FFE)
            END_ENUM_RANGE_ODD(LAST_PLIST_TNUM)

            # other kinds of lists
            NEXT_ENUM_EVEN(T_RANGE_NSORT)
            NEXT_ENUM_EVEN(T_RANGE_SSORT)
            NEXT_ENUM_EVEN(T_BLIST)
            NEXT_ENUM_EVEN(T_BLIST_NSORT)
            NEXT_ENUM_EVEN(T_BLIST_SSORT)
            NEXT_ENUM_EVEN(T_STRING)
            NEXT_ENUM_EVEN(T_STRING_NSORT)
            NEXT_ENUM_EVEN(T_STRING_SSORT)

        END_ENUM_RANGE_ODD(LAST_LIST_TNUM)

        # object sets and maps
        START_ENUM_RANGE_EVEN(FIRST_OBJSET_TNUM)
            NEXT_ENUM_EVEN(T_OBJSET)
            NEXT_ENUM_EVEN(T_OBJMAP)
        END_ENUM_RANGE_ODD(LAST_OBJSET_TNUM)

    # last mutable/immutable TNUM
    END_ENUM_RANGE(LAST_IMM_MUT_TNUM)

    # external types
    START_ENUM_RANGE(FIRST_EXTERNAL_TNUM)
        T_COMOBJ
        T_POSOBJ
        T_DATOBJ
        T_WPOBJ
        # package TNUMs, for use by kernel extensions
        FIRST_PACKAGE_TNUM
        LAST_PACKAGE_TNUM = 253

    END_ENUM_RANGE(LAST_EXTERNAL_TNUM)

    END_ENUM_RANGE(LAST_REAL_TNUM)

    T_COPYING
end

# JuliaInterface allocates the TNUM of wrapped Julia objects with
# `RegisterPackageTNUM`; it is the first GAP package to be loaded, hence gets
# the first package TNUM
const T_JULIA_OBJ = FIRST_PACKAGE_TNUM

#
# functions which directly interact with GAP objects, bypassing the GAP kernel
#
function ADDR_OBJ(obj::GapObj)
    mptr = Ptr{Ptr{Csize_t}}(pointer_from_objref(obj))
    return unsafe_load(mptr)
end

function ADDR_OBJ(ptr::Ptr)
    mptr = Ptr{Ptr{Csize_t}}(ptr)
    return unsafe_load(mptr)
end

function TNUM_OBJ(obj::GapObj)
    header = unsafe_load(ADDR_OBJ(obj), 0)
    return reinterpret(Int, header & 0xFF)
end

function TNUM_OBJ(ptr::Ptr)
    header = unsafe_load(ADDR_OBJ(ptr), 0)
    return reinterpret(Int, header & 0xFF)
end

function FLAGS_OBJ(obj::GapObj)
    header = unsafe_load(ADDR_OBJ(obj), 0)
    return reinterpret(Int, (header >> 8) & 0xFF)
end

function SIZE_OBJ(obj::GapObj)
    header = unsafe_load(ADDR_OBJ(obj), 0)
    return reinterpret(Int, (header >> 16))
end

"""
    ADDR_TNUM_SIZE_OBJ(obj::GapObj)

Return the address of the data of `obj` together with its type number and its
size, reading the bag header only once.

Calling `ADDR_OBJ`, `TNUM_OBJ` and `SIZE_OBJ` separately chases the same two
pointers again for each of them. LLVM merges those accesses in simple cases,
but not once the caller is inlined into a loop such as the one in
`_collect_list!`; a caller that needs more than one of the three values is three
times slower there.
"""
function ADDR_TNUM_SIZE_OBJ(obj::GapObj)
    addr = ADDR_OBJ(obj)
    header = unsafe_load(addr, 0)
    return addr, reinterpret(Int, header & 0xFF), reinterpret(Int, (header >> 16))
end

# given a GAP T_FUNCTION object, fetch its n-th function handler (handler 0-6
# are for calls with that many arguments, handler 7 is for any higher number
# of arguments)
function GET_FUNC_PTR(obj::GapObj, narg::Int)
    #@assert TNUM_OBJ(obj) == T_FUNCTION
    #@assert 0 <= narg && narg <= 7
    bag_ptr = Ptr{Ptr{Nothing}}(ADDR_OBJ(obj))
    unsafe_load(bag_ptr, narg + 1)
end

GAP_IS_INT(obj::GapObj) = TNUM_OBJ(obj) <= T_INTNEG
GAP_IS_RAT(obj::GapObj) = TNUM_OBJ(obj) == T_RAT
GAP_IS_MACFLOAT(obj::GapObj) = TNUM_OBJ(obj) == T_MACFLOAT
GAP_IS_CHAR(obj::GapObj) = TNUM_OBJ(obj) == T_CHAR
