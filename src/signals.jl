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

# Signal inspection, save/restore, and the Ctrl-C bridge; the ownership
# contract they implement is in docs/src/signals.md.

# Signal numbers differ between Linux and the BSD family (macOS).
# GAP.jl does not support Windows.
const _SIGNAL_NUMBERS = Sys.islinux() ?
    Dict(:HUP => 1, :INT => 2, :QUIT => 3, :ILL => 4, :TRAP => 5, :ABRT => 6,
         :BUS => 7, :FPE => 8, :KILL => 9, :USR1 => 10, :SEGV => 11,
         :USR2 => 12, :PIPE => 13, :ALRM => 14, :TERM => 15, :CHLD => 17,
         :CONT => 18, :STOP => 19, :TSTP => 20, :TTIN => 21, :TTOU => 22,
         :WINCH => 28) :
    Dict(:HUP => 1, :INT => 2, :QUIT => 3, :ILL => 4, :TRAP => 5, :ABRT => 6,
         :FPE => 8, :KILL => 9, :BUS => 10, :SEGV => 11, :SYS => 12,
         :PIPE => 13, :ALRM => 14, :TERM => 15, :STOP => 17, :TSTP => 18,
         :CONT => 19, :CHLD => 20, :TTIN => 21, :TTOU => 22, :WINCH => 28,
         :INFO => 29, :USR1 => 30, :USR2 => 31)

_signum(name::Symbol) = _SIGNAL_NUMBERS[name]

# Signals worth reporting, in numeric order; SIGKILL and SIGSTOP cannot be
# caught and sigaction refuses to even query them on macOS
const _REPORTED_SIGNALS = sort!(filter(!in((:KILL, :STOP)), collect(keys(_SIGNAL_NUMBERS))); by = _signum)

# Opaque buffers for `struct sigaction`, `sigset_t` and `struct termios`;
# generously sized so they fit every supported libc.
const _SIGACTION_BUFSIZE = 256
const _SIGSET_BUFSIZE = 256
const _TERMIOS_BUFSIZE = 256

# Values of the `sa_handler` field, and its position (first field on all
# supported platforms)
const _SIG_DFL = Ptr{Cvoid}(0)
const _SIG_IGN = Ptr{Cvoid}(1)

"""
    SignalInfo

Disposition of one signal in the current process, as returned by
[`signal_report`](@ref).

Fields: `signal` (number), `name` (e.g. `"SIGCHLD"`), `disposition`
(`:default`, `:ignore` or `:handler`), `handler` (function pointer),
`symbol` and `library` (the handler's name and shared library, resolved via
`dladdr`, or `nothing`), `owner` (`:julia`, `:gap`, `:io`, `:ncurses`,
`:JuliaInterface`, `:none`, or the library name), and `blocked` (whether the
signal is blocked in the calling thread's mask).
"""
struct SignalInfo
    signal::Int
    name::String
    disposition::Symbol
    handler::Ptr{Cvoid}
    symbol::Union{Nothing,String}
    library::Union{Nothing,String}
    owner::Symbol
    blocked::Bool
end

function _save_sigaction(sig::Integer)
    buf = zeros(UInt8, _SIGACTION_BUFSIZE)
    rc = @ccall sigaction(sig::Cint, C_NULL::Ptr{Cvoid}, buf::Ptr{UInt8})::Cint
    rc == 0 || Base.systemerror("sigaction")
    return buf
end

function _restore_sigaction(sig::Integer, buf::Vector{UInt8})
    rc = @ccall sigaction(sig::Cint, buf::Ptr{UInt8}, C_NULL::Ptr{Cvoid})::Cint
    rc == 0 || Base.systemerror("sigaction")
    return nothing
end

_sigaction_handler(buf::Vector{UInt8}) = Ptr{Cvoid}(reinterpret(UInt, buf[1:sizeof(UInt)])[1])

# Resolve a code address to (symbol, library basename) via dladdr
function _symbolize(addr::Ptr{Cvoid})
    # Dl_info: { const char *dli_fname; void *dli_fbase; const char *dli_sname; void *dli_saddr }
    info = zeros(UInt8, 4 * sizeof(Ptr{Cvoid}))
    rc = @ccall dladdr(addr::Ptr{Cvoid}, info::Ptr{UInt8})::Cint
    rc == 0 && return (nothing, nothing)
    ptrs = reinterpret(Ptr{UInt8}, info)
    fname = ptrs[1] == C_NULL ? nothing : basename(unsafe_string(ptrs[1]))
    sname = ptrs[3] == C_NULL ? nothing : unsafe_string(ptrs[3])
    return (sname, fname)
end

function _signal_owner(library::Union{Nothing,String})
    library === nothing && return :unknown
    occursin("JuliaInterface", library) && return :JuliaInterface
    occursin("julia", library) && return :julia
    startswith(library, "libgap") && return :gap
    occursin("ncurses", library) && return :ncurses
    (library == "io.so" || startswith(library, "io.")) && return :io
    return Symbol(library)
end

function _blocked_signals()
    set = zeros(UInt8, _SIGSET_BUFSIZE)
    # `how` is irrelevant when the new set is NULL: this only queries the mask
    rc = @ccall pthread_sigmask(0::Cint, C_NULL::Ptr{Cvoid}, set::Ptr{UInt8})::Cint
    rc == 0 || Base.systemerror("pthread_sigmask")
    return set
end

_is_blocked(set::Vector{UInt8}, sig::Integer) =
    (@ccall sigismember(set::Ptr{UInt8}, sig::Cint)::Cint) == 1

function _signal_info(name::Symbol, blocked_set::Vector{UInt8})
    sig = _signum(name)
    handler = _sigaction_handler(_save_sigaction(sig))
    if handler == _SIG_DFL
        disposition, symbol, library, owner = :default, nothing, nothing, :none
    elseif handler == _SIG_IGN
        disposition, symbol, library, owner = :ignore, nothing, nothing, :none
    else
        symbol, library = _symbolize(handler)
        disposition, owner = :handler, _signal_owner(library)
    end
    return SignalInfo(sig, "SIG" * String(name), disposition, handler,
                      symbol, library, owner, _is_blocked(blocked_set, sig))
end

"""
    signal_report(io::IO = stdout; all::Bool = false)

Print a table of the process-wide signal dispositions, attributing each
installed handler to the shared library that owns it, and return the
underlying `Vector{SignalInfo}`.

By default only signals that are caught, ignored, or blocked are shown;
`all = true` shows every known signal. This is the first tool to reach for
when Ctrl-C, subprocesses, or the terminal misbehave in a session using
GAP.jl; see the manual section on signal handling for the expected state.
"""
function signal_report(io::IO = stdout; all::Bool = false)
    blocked_set = _blocked_signals()
    infos = [_signal_info(name, blocked_set) for name in _REPORTED_SIGNALS]
    for info in infos
        all || info.disposition != :default || info.blocked || continue
        print(io, rpad(info.name, 10), rpad(String(info.disposition), 9))
        if info.disposition == :handler
            print(io, something(info.symbol, "?"), " [", something(info.library, "?"), "]")
        end
        info.blocked && print(io, "  blocked")
        println(io)
    end
    return infos
end

# Terminal attributes of stdin, or `nothing` if stdin is not a terminal
function _save_termios()
    (@ccall isatty(0::Cint)::Cint) == 1 || return nothing
    buf = zeros(UInt8, _TERMIOS_BUFSIZE)
    rc = @ccall tcgetattr(0::Cint, buf::Ptr{UInt8})::Cint
    return rc == 0 ? buf : nothing
end

# tcsetattr from a background job raises SIGTTOU, so only call it on change
function _restore_termios(buf::Union{Nothing,Vector{UInt8}})
    buf === nothing && return nothing
    buf == _save_termios() && return nothing

    TCSANOW = 0
    @ccall tcsetattr(0::Cint, TCSANOW::Cint, buf::Ptr{UInt8})::Cint
    return nothing
end

# Dispositions of `signals` plus the terminal attributes
function _save_signal_state(signals)
    actions = [(_signum(name), _save_sigaction(_signum(name))) for name in signals]
    return (; actions, termios = _save_termios())
end

_restore_signal_state(::Nothing) = nothing

function _restore_signal_state(state)
    for (sig, buf) in state.actions
        _restore_sigaction(sig, buf)
    end
    _restore_termios(state.termios)
    return nothing
end

function _with_saved_signal_state(f, signals)
    state = _save_signal_state(signals)
    try
        return f()
    finally
        _restore_signal_state(state)
    end
end

#############################################################################
##
## Interrupt bridge (Ctrl-C); the handler is in JuliaInterface.c
##

# counters in JuliaInterface.so
const _gap_depth_ptr = Ref{Ptr{Cint}}(C_NULL)
const _gap_interrupt_requested_ptr = Ref{Ptr{Cint}}(C_NULL)

@inline function _enter_gap()
    p = _gap_depth_ptr[]
    p == C_NULL && return nothing

    unsafe_store!(p, unsafe_load(p) + Cint(1))
    return nothing
end

@inline function _leave_gap()
    p = _gap_depth_ptr[]
    p == C_NULL && return nothing

    depth = unsafe_load(p) - Cint(1)
    unsafe_store!(p, depth)

    depth == 0 && unsafe_load(_gap_interrupt_requested_ptr[]) != 0 && _take_unhandled_interrupt()
    return nothing
end

@inline function _set_gap_depth(value::Cint)
    p = _gap_depth_ptr[]
    p == C_NULL && return nothing

    unsafe_store!(p, value)
    return nothing
end

# GAP acts on Ctrl-C at its next statement. If it became inactive before
# executing one, disarm the interrupt (else it fires in a later, unrelated
# call) and deliver it here, as Julia does for a Ctrl-C during a ccall.
@noinline function _take_unhandled_interrupt()
    taken = @ccall JuliaInterface_path.JuliaInterface_TakeUnhandledGapInterrupt()::Cint
    taken != 0 && throw(InterruptException())
    return nothing
end

# Evaluate `expr` with GAP marked as active.
#
# No try/finally: GAP may longjmp across this frame (an error in a nested
# Julia -> GAP -> Julia -> GAP call unwinds to GAP's own catch), which would
# skip popping Julia's exception handler. Not needed either: such an error
# lands in GAP, which is active, and ThrowObserver zeroes the counter before
# it throws into Julia.
macro gap_active(expr)
    quote
        _enter_gap()
        local result = $(esc(expr))
        _leave_gap()
        result
    end
end

# In standalone mode (gap.sh) GAP installs its own SIGINT handler.
function _install_interrupt_bridge(standalone::Bool)
    _gap_depth_ptr[] = cglobal((:gap_interrupt_depth, JuliaInterface_path), Cint)
    _gap_interrupt_requested_ptr[] = cglobal((:gap_interrupt_requested, JuliaInterface_path), Cint)
    standalone && return nothing

    # lets the handler tell "GAP waits at its prompt" from "GAP computes"
    readline_state = Libdl.dlsym(Libdl.dlopen(libgap), :rl_readline_state; throw_error = false)

    @ccall JuliaInterface_path.JuliaInterface_InstallSigintHandler(
        something(readline_state, C_NULL)::Ptr{Cvoid})::Cvoid
    return nothing
end

# Installed at startup by the GAP kernel (SIGCHLD, SIGWINCH) and by ncurses
# via Browse (SIGTSTP), although Julia owns them in an embedded session
const _SIGNALS_OWNED_BY_JULIA = (:CHLD, :TSTP, :WINCH)
