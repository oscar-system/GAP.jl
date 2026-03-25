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

struct GAPStackFrame
    function_label::String
    file::Union{Nothing,String}
    line::Union{Nothing,Int}
end

struct GAPError <: Exception
    message::String
    gap_frames::Vector{GAPStackFrame}
    raw_text::String
    julia_stacktrace::Vector{Tuple{Base.StackTraces.StackFrame,Int}}
end

GAPError(message::String, gap_frames::Vector{GAPStackFrame}, raw_text::String) =
    GAPError(message, gap_frames, raw_text, Tuple{Base.StackTraces.StackFrame,Int}[])

# Error handling spans GAP and Julia:
# - GAP prints error text into _JULIAINTERFACE_ERROR_BUFFER
# - gap/err.g captures GAP stack frames into _JULIAINTERFACE_ERROR_STACK
# - copy_gap_error_to_julia() snapshots both into last_error_snapshot
# - ThrowObserver later consumes that snapshot and throws a Julia GAPError
#
# Some paths, especially parse-time failures in evalstr, can reach ThrowObserver
# without a prior snapshot callback. For those, throw_gap_error falls back to
# reading the current GAP runtime state directly.
const last_error_snapshot = Ref{Union{Nothing,GAPError}}(nothing)

const disable_error_handler = Ref{Bool}(false)

is_error_handler_disabled() = disable_error_handler[]

function Base.showerror(io::IO, err::GAPError)
    show_gap_error(io, err)
end

function Base.showerror(io::IO, err::GAPError, bt; backtrace=true)
    show_gap_error(io, err)
    if backtrace && !isempty(err.julia_stacktrace)
        show_julia_backtrace(io, err.julia_stacktrace)
    end
end

function show_gap_error(io::IO, err::GAPError)
    print(io, "Error thrown by GAP")
    if !isempty(err.message)
        print(io, ": ", err.message)
    end

    if !isempty(err.gap_frames)
        print(io, "\nGAP stacktrace:")
        for (i, frame) in pairs(err.gap_frames)
            print(io, "\n [", i, "] ")
            printstyled(io, frame.function_label; bold=true)
            if frame.file !== nothing
                print(io, " @ ", Base.contractuser(frame.file))
                if frame.line !== nothing
                    print(io, ":", frame.line)
                end
            elseif frame.line !== nothing
                print(io, " @ line ", frame.line)
            end
        end
    elseif !isempty(err.raw_text)
        print(io, "\n", chomp(err.raw_text))
    end
end

function show_julia_backtrace(io::IO, trace::Vector{Tuple{Base.StackTraces.StackFrame,Int}})
    isempty(trace) && return

    println(io, "\nJulia stacktrace:")
    Base.show_backtrace(io, Any[trace...])
end

# Capture the Julia stack before ThrowObserver rewrites the control flow through
# GAP.jl internals. The goal is to show the user-facing Julia call site that
# entered GAP, not the later machinery that converts the failure into GAPError.
function capture_current_julia_backtrace()
    trace = Tuple{Base.StackTraces.StackFrame,Int}[
        (frame, 1) for frame in Base.stacktrace(true)
        if frame.func ∉ (
            :capture_current_julia_backtrace,
            :copy_gap_error_to_julia,
            :throw_gap_error,
            :ThrowObserver,
        )
    ]
    trace = filter(frame -> !is_internal_julia_error_frame(frame[1]), trace)
    trim_julia_backtrace_at_toplevel(trace)
    return collapse_repeated_julia_frames(trace)
end

function is_internal_julia_error_frame(frame::Base.StackTraces.StackFrame)
    file = String(frame.file)
    file == abspath(@__DIR__, "ccalls.jl") && return true
    file == abspath(@__DIR__, "GAP.jl") && return true
    endswith(file, ".dylib") && return true
    endswith(file, ".so") && return true
    endswith(file, ".dll") && return true
    endswith(file, ".c") && return true
    endswith(file, ".h") && return true
    file == ":-1" && return true
    frame.line <= 0 && return true
    return false
end

function trim_julia_backtrace_at_toplevel(trace::Vector{Tuple{Base.StackTraces.StackFrame,Int}})
    for (i, (frame, _)) in pairs(trace)
        if Base.StackTraces.is_top_level_frame(frame)
            resize!(trace, i)
            break
        end
    end
    return trace
end

function collapse_repeated_julia_frames(trace::Vector{Tuple{Base.StackTraces.StackFrame,Int}})
    collapsed = Tuple{Base.StackTraces.StackFrame,Int}[]
    for (frame, n) in trace
        if !isempty(collapsed)
            prev, prev_n = collapsed[end]
            if frame.file == prev.file && frame.line == prev.line
                collapsed[end] = (prev, prev_n + n)
                continue
            end
        end
        push!(collapsed, (frame, n))
    end
    return collapsed
end

function capture_gap_error_frames()
    frames = GAPStackFrame[]
    if !hasproperty(Globals, :_JULIAINTERFACE_ERROR_STACK)
        return frames
    end

    # GAP stores frames as [label, file-or-fail, line-or-fail].
    raw_frames = Globals._JULIAINTERFACE_ERROR_STACK
    for raw_frame in raw_frames
        label = String(raw_frame[1])
        file = raw_frame[2] == Globals.fail ? nothing : String(raw_frame[2])
        line = raw_frame[3] == Globals.fail ? nothing : Int(raw_frame[3])
        push!(frames, GAPStackFrame(label, file, line))
    end
    return frames
end

function clear_gap_error_frames()
    hasproperty(Globals, :_JULIAINTERFACE_CLEAR_ERROR_STACK) || return
    Globals._JULIAINTERFACE_CLEAR_ERROR_STACK()
end

function clear_gap_error_buffer()
    hasproperty(Globals, :_JULIAINTERFACE_ERROR_BUFFER) || return
    # Keep the original GAP string object and only truncate it. Rebinding the
    # global would break the OutputTextString stream created in gap/err.g.
    @ccall libgap.SET_LEN_STRING(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj, 0::Cuint)::Cvoid
end

function clear_gap_error()
    clear_gap_error_frames()
    clear_gap_error_buffer()
end

function set_error_handler_disabled(flag::Bool)
    disable_error_handler[] = flag
    # Switching modes must also drop any buffered error state so later calls do
    # not observe snapshots captured under the previous policy.
    last_error_snapshot[] = nothing
    clear_gap_error()
    return flag
end

# GAP's raw error text often contains prefixes such as "Error, " and extra
# continuation lines. GAPError.message keeps only the first user-facing summary
# line, while GAPError.raw_text preserves the full text for display fallback.
function gap_error_message(raw_text::String)
    isempty(raw_text) && return ""

    first_line = split(chomp(raw_text), '\n'; limit=2)[1]
    startswith(first_line, "Error, ") && (first_line = first_line[8:end])
    endswith(first_line, " called from") &&
        (first_line = first_line[1:end-length(" called from")])
    return strip(first_line)
end

function copy_gap_error_to_julia()
    global disable_error_handler
    if disable_error_handler[]
        return
    end

    # This is the normal callback path: GAP has already written its error text
    # and stack into the global buffer/stack, so snapshot them now before the
    # next GAP command can overwrite that state.
    raw_text = String(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj)
    isempty(raw_text) && return

    frames = capture_gap_error_frames()
    last_error_snapshot[] = GAPError(
        gap_error_message(raw_text),
        frames,
        raw_text,
        capture_current_julia_backtrace(),
    )
    clear_gap_error()
end

function capture_gap_error_snapshot_from_runtime()
    # Fallback for code paths where ThrowObserver fires without a prior Julia
    # callback snapshot, for example some evalstr parse errors.
    raw_text = hasproperty(Globals, :_JULIAINTERFACE_ERROR_BUFFER) ?
        String(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj) : ""
    frames = capture_gap_error_frames()
    if isempty(raw_text) && isempty(frames)
        return nothing
    end

    return GAPError(
        gap_error_message(raw_text),
        frames,
        raw_text,
        capture_current_julia_backtrace(),
    )
end

function take_gap_error_snapshot()
    snapshot = last_error_snapshot[]
    # Snapshots are single-use. Once a GAP error has been consumed, later calls
    # must not see it again.
    last_error_snapshot[] = nothing
    return snapshot
end

function throw_gap_error(snapshot::Union{Nothing,GAPError})
    if snapshot === nothing
        snapshot = capture_gap_error_snapshot_from_runtime()
        snapshot === nothing || clear_gap_error()
    end
    if snapshot === nothing
        snapshot = GAPError("", GAPStackFrame[], "")
    end
    throw(snapshot)
end

function ThrowObserver(depth::Cint)
    global disable_error_handler
    if disable_error_handler[]
        return
    end

    # Tell GAP that the error was handled on the Julia side, then restore GAP's
    # interpreter state before throwing back into Julia.
    @ccall libgap.ClearError()::Cvoid
    @ccall libgap.SWITCH_TO_BOTTOM_LVARS()::Cvoid
    # Only the outermost observer turns the GAP failure into a Julia exception.
    if depth <= 0
        throw_gap_error(take_gap_error_snapshot())
    end
end
