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

# Signal state inspection and save/restore helpers.
#
# Julia, the GAP kernel, and GAP packages (io, Browse/ncurses) all install
# process-wide signal handlers; see docs/src/signals.md for the ownership
# contract. The helpers here make the actual state visible (`signal_report`)
# and let GAP.jl restore Julia's state after code that ignores the contract.

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

function _restore_termios(buf::Union{Nothing,Vector{UInt8}})
    buf === nothing && return nothing
    TCSANOW = 0
    @ccall tcsetattr(0::Cint, TCSANOW::Cint, buf::Ptr{UInt8})::Cint
    return nothing
end

# Snapshot of the dispositions of `signals` plus the terminal attributes, to
# be reinstated with `_restore_signal_state` after running code that installs
# its own handlers (GAP's kernel, io, ncurses)
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
## Interrupt bridge (Ctrl-C)
##
## JuliaInterface installs a SIGINT handler that chains onto Julia's and
## consults the counter `gap_interrupt_depth`: if GAP code is executing, it
## interrupts GAP (which raises a "user interrupt" error, converted into a
## Julia InterruptException by throw_gap_error); otherwise Julia handles the
## signal as usual. The counter lives in JuliaInterface.so; every entry from
## Julia into GAP is wrapped in `@gap_active`, and GAP resets the counter to
## zero while it calls back into Julia.

const _gap_depth_ptr = Ref{Ptr{Cint}}(C_NULL)

@inline function _adjust_gap_depth(delta::Cint)
    p = _gap_depth_ptr[]
    p == C_NULL && return nothing
    unsafe_store!(p, unsafe_load(p) + delta)
    return nothing
end

@inline function _set_gap_depth(value::Cint)
    p = _gap_depth_ptr[]
    p == C_NULL && return nothing
    unsafe_store!(p, value)
    return nothing
end

# Evaluate `expr` with GAP marked as active for the interrupt bridge.
#
# Deliberately no try/finally: GAP may longjmp across this frame (a GAP
# error inside a nested Julia -> GAP -> Julia -> GAP call unwinds to GAP's
# own catch), which would skip popping a Julia exception handler and corrupt
# the handler chain. The counter stays consistent without it: GAP errors
# arise while GAP is active, so landing in a GAP catch needs no adjustment,
# and ThrowObserver resets the counter before throwing into Julia.
macro gap_active(expr)
    quote
        _adjust_gap_depth(Cint(1))
        local result = $(esc(expr))
        _adjust_gap_depth(Cint(-1))
        result
    end
end

# Called during initialization once JuliaInterface.so is loaded. In
# standalone mode (gap.sh) GAP installs its own SIGINT handler instead.
function _install_interrupt_bridge(standalone::Bool)
    _gap_depth_ptr[] = cglobal((:gap_interrupt_depth, JuliaInterface_path), Cint)
    standalone && return nothing
    # readline's state word lets the handler tell "GAP waits for input at a
    # prompt" (Ctrl-C is dropped, as in standalone GAP) from "GAP computes"
    readline_state = Libdl.dlsym(Libdl.dlopen(libgap), :rl_readline_state; throw_error = false)
    @ccall JuliaInterface_path.JuliaInterface_InstallSigintHandler(
        something(readline_state, C_NULL)::Ptr{Cvoid})::Cvoid
    return nothing
end

# Signals whose handlers GAP or autoloaded packages install at startup even
# though Julia owns them in an embedded session: SIGCHLD (GAP kernel,
# iostream.c; io package), SIGTSTP (ncurses, via Browse), SIGWINCH (GAP kernel,
# sysfiles.c). Restoring them keeps Julia's subprocess and terminal handling
# intact; see docs/src/signals.md.
const _SIGNALS_OWNED_BY_JULIA = (:CHLD, :TSTP, :WINCH)
