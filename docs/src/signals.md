# Signals, Ctrl-C, subprocesses and the terminal

```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

Julia, the GAP kernel and GAP packages (`io`, `Browse`/ncurses) all expect
to own process-wide state: signal handlers, the signal mask, child process
reaping and the terminal. This page states who owns what in a GAP.jl
session and what GAP.jl does to enforce it.

## What Julia does

These facts (Julia 1.10 to 1.12, `src/signals-unix.c`) constrain everything
below.

- `SIGINT`, `SIGTERM` and `SIGQUIT` are blocked on all Julia threads and
  consumed by a listener thread. A handler a library installs for them never
  runs on a Julia thread. On macOS `SIGTERM` and `SIGQUIT` are also set to
  `SIG_IGN`.
- The listener re-raises each `SIGINT` through the process disposition, then
  throws `InterruptException` at the next *safepoint*, i.e. only while Julia
  code runs. A long `ccall` is not interruptible.
- `SIGSEGV` and `SIGBUS` implement GC safepoints. Replacing those handlers
  breaks multithreaded Julia.
- Subprocesses are spawned by libuv and reaped per pid. If anyone else reaps
  such a child, e.g. with `waitpid(-1)`, its `Process` never completes and
  `run`/`wait` hang. On Linux libuv also needs its `SIGCHLD` handler.
- A raw `fork()` inherits the blocked mask and the `SIG_IGN` dispositions:
  the child ignores `SIGTERM` unless the forking code resets them first.

## Ownership contract

| Resource | Owner | Everyone else |
|:---|:---|:---|
| `SIGSEGV`, `SIGBUS`, `SIGILL`, `SIGFPE`, `SIGTRAP` | Julia | never touch |
| `SIGINT` | Julia; `JuliaInterface` installs one chaining handler | no other handlers |
| `SIGTERM`, `SIGQUIT`, `SIGUSR2`, signal mask | Julia | never modify |
| `SIGCHLD`, reaping | libuv | reap own children per pid; no handler, no `waitpid(-1)` |
| `fork()` | the forking code | reset mask and termination signals before forking |
| terminal, `SIGTSTP`, `SIGWINCH` | the active REPL | acquire on entry, restore on exit |

`test/signals.jl` checks what can be checked after `using GAP`.

## What GAP.jl does

**Startup.** The GAP kernel installs `SIGCHLD` and `SIGWINCH` handlers
whatever `GAP_Initialize` is told, and loading `Browse` makes ncurses
install a `SIGTSTP` handler. GAP.jl restores Julia's dispositions for these
three signals, and the terminal attributes, once GAP is up. Standalone mode
(`gap.sh`) is left alone.

**Ctrl-C.** `JuliaInterface` installs a `SIGINT` handler that chains onto
Julia's. While GAP code executes it calls GAP's `InterruptExecStat`, which
makes GAP raise `user interrupt` at its next statement; GAP.jl turns that
error into an `InterruptException`. Otherwise the handler forwards to Julia.
"GAP code executes" is a counter maintained around every call from Julia
into GAP and zeroed while GAP calls back into Julia, so the innermost
runtime gets the interrupt.

- GAP acts at statement boundaries. If a call ends before the next
  statement, e.g. because it ran a single kernel function, the
  `InterruptException` is thrown when the call returns.
- Inside [`prompt`](@ref) Ctrl-C enters GAP's break loop. While GAP waits for
  input it is ignored, as in standalone GAP.
- Should a future Julia stop re-raising `SIGINT`, Ctrl-C again takes effect
  only once GAP returns to Julia.

**`GAP.prompt()`** hands the terminal to GAP's REPL and back, also if the
session ends abnormally.

**Diagnostics.** [`signal_report`](@ref) lists the current dispositions and
the library owning each handler. A `SIGCHLD` line owned by `libgap` or `io`,
or a `SIGTSTP`/`SIGWINCH` line owned by `libgap` or `ncurses`, is a contract
violation by something that ran after startup.

```@docs
signal_report
SignalInfo
```

## Known problems

- The `io` package up to 4.10.0 installs a `SIGCHLD` handler that reaps with
  `waitpid(-1)` whenever its process functions run; Julia's `run` hangs
  afterwards, and children it forks cannot be stopped with `SIGTERM`. Both
  are fixed in io 4.10.1. Until GAP.jl ships it, `GAP.use_orig_ExecuteProcess[]`
  stays `true` and the `utils` and `curlInterface` packages are excluded from
  the package tests. `GAPJL_TEST_SIGNALS_IO=1` enables a test documenting
  the hang.
- Without its `SIGCHLD` handler the GAP kernel notices a dead
  `InputOutputLocalProcess` child only when the stream is next used.
- `Browse` initializes ncurses when loaded instead of when it first draws.

Wanted from the GAP kernel: a public `InterruptExecStat` and a way to
recognize a user interrupt in the libgap API; no `SIGWINCH`/`SIGCHLD`
handlers when embedded; a signal reset before `fork` in `ExecuteProcess`.
