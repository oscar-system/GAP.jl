# Signals, interrupts, subprocesses and the terminal

```@meta
CurrentModule = GAP
DocTestSetup = :(using GAP)
```

This page is the reference for how GAP.jl deals with process-wide
resources that both Julia and GAP want to own: signal dispositions, the
signal mask, child process reaping, and the terminal. It documents the
facts about Julia's runtime that an embedded library has to respect, the
ownership contract GAP.jl enforces, the measures implemented in GAP.jl,
and what is still pending in GAP, in GAP packages, and upstream in Julia.
It doubles as guidance for other Julia packages that embed a computer
algebra system (e.g. Singular.jl, Polymake.jl).

## Why this page exists

GAP was written as a standalone program that owns its process. When it is
embedded into Julia, three runtimes compete for the same process-wide
state:

- Julia (and its I/O library libuv),
- the GAP kernel,
- GAP packages with kernel extensions: `io` (child processes, its own
  `SIGCHLD` handler), `Browse` (ncurses, terminal and `SIGTSTP`).

Every incident in the following list is one of these runtimes clobbering
state that another one relied on:

- Ctrl-C killing Julia with GAP's `you hit Ctrl-C twice` message
  ([GAP.jl#74](https://github.com/oscar-system/GAP.jl/issues/74),
  [gap#3256](https://github.com/gap-system/gap/pull/3256));
- `Process` hanging after `IO_Popen3` was used
  ([GAP.jl#902](https://github.com/oscar-system/GAP.jl/issues/902)),
  the crashes that led to disabling the Julia implementation of
  `ExecuteProcess`
  ([GAP.jl#905](https://github.com/oscar-system/GAP.jl/issues/905),
  [#906](https://github.com/oscar-system/GAP.jl/pull/906),
  [#908](https://github.com/oscar-system/GAP.jl/issues/908)),
  and the wish to replace GAP's child process functions altogether
  ([GAP.jl#241](https://github.com/oscar-system/GAP.jl/issues/241),
  [#1107](https://github.com/oscar-system/GAP.jl/issues/1107));
- the test suites of the `utils` and `curlInterface` packages hanging
  forever under GAP.jl because a forked helper process never receives
  the `SIGTERM` meant to stop it;
- the io package's own `SIGCHLD` handler losing the race against another
  reaper, first seen with HPC-GAP
  ([io#5](https://github.com/gap-packages/io/issues/5),
  [gap#3380](https://github.com/gap-system/gap/issues/3380));
- the terminal being garbled after suspending and resuming a Julia
  session with the `Browse` package loaded
  ([GAP.jl#741](https://github.com/oscar-system/GAP.jl/issues/741)),
  and Browse's ncurses initialization emitting stray output
  ([gap#430](https://github.com/gap-system/gap/issues/430)).

## How Julia handles signals

These facts hold for Julia 1.10 through 1.12 (see `src/signals-unix.c`,
`src/signal-handling.c` and `src/safepoint.c` in the Julia sources).

**Blocked signals and the listener thread.** At startup Julia blocks
`SIGINT`, `SIGTERM`, `SIGQUIT` (plus `SIGINFO` on macOS, `SIGUSR1` on
Linux) on the main thread; all threads created later inherit that mask.
A dedicated *signal listener* thread consumes these signals, via
`sigwaitinfo` on Linux and via kqueue on macOS. Because kqueue does not
dequeue the signals it observes, on macOS the dispositions of `SIGTERM`
and `SIGQUIT` are set to `SIG_IGN` so that the kernel discards them.
Consequences:

- A handler installed for one of these signals by a library never runs
  on a Julia thread — the *mask*, not the disposition, disables it.
- Children created by a raw `fork()` inherit the blocked mask and the
  `SIG_IGN` dispositions. Neither Julia nor libuv registers
  `pthread_atfork` handlers. Unless the forking code resets the signal
  state itself, such a child cannot be terminated with `SIGTERM`.
  libuv's own spawn path does reset everything before `exec`.

**Ctrl-C.** When the listener thread receives `SIGINT`, it first
re-raises the signal on itself with `SIGINT` temporarily unblocked
(`jl_ignore_sigint`), which dispatches it through the current process
disposition; only if Julia's own handler ran does it proceed to deliver
an `InterruptException` — and it delivers it exclusively at a
*safepoint*, i.e. when Julia code is executing. A long `ccall` into a C
library is therefore not interruptible; repeated Ctrl-C eventually
force-throws the exception through the foreign C frames, which is unsafe.
`Base.disable_sigint` defers delivery, and `jl_gc_safepoint()` is the
sanctioned way for foreign code to poll for a pending interrupt.

**Fault signals.** `SIGSEGV` and `SIGBUS` (and on Linux `SIGUSR2`) are
integral to Julia's garbage collector: safepoints are implemented as
faults on a protected page. Replacing these handlers breaks multithreaded
Julia. `--handle-signals=no` disables them too and is therefore not an
option for a process that uses more than one thread.

**Child processes.** Julia spawns processes exclusively through libuv.
On macOS and the BSDs libuv installs no `SIGCHLD` handler at all and
watches its children with kqueue; on Linux it installs a process-wide
`SIGCHLD` handler that merely wakes the event loop. In both cases libuv
reaps strictly per pid with `waitpid(pid, WNOHANG)`. If another party
reaped the child first, libuv sees `ECHILD`, concludes that "someone
stole the waitpid", and silently never completes the `Process` — every
`wait`/`success`/`run` on it hangs forever. On Linux a foreign `SIGCHLD`
handler additionally replaces libuv's and stops the loop from ever
noticing exited children.

**Terminal.** Julia installs no handlers for `SIGTSTP`, `SIGCONT` or
`SIGWINCH`. The REPL raises `SIGTSTP` itself on Ctrl-Z and polls the
terminal size on demand.

## The ownership contract

In a process that embeds GAP into Julia:

| Resource | Owner | Everyone else |
|:---|:---|:---|
| `SIGSEGV`, `SIGBUS`, `SIGILL`, `SIGFPE`, `SIGTRAP` | Julia (GC safepoints, error reporting) | never touch |
| `SIGINT` | Julia delivers it; `JuliaInterface` may install a single *chaining* handler | no other handlers, no temporary `SIG_IGN` |
| `SIGTERM`, `SIGQUIT`, `SIGUSR2`, the signal mask | Julia | never modify |
| `SIGCHLD` | libuv | reap only your own children, per pid; `waitpid(-1)` is forbidden; no handlers |
| `fork()` | the forking code | reset mask and dispositions of the termination signals *before* forking and restore them in the parent; children created by `fork`+`exec` inherit both |
| terminal (raw mode, `SIGTSTP`, `SIGWINCH`) | whoever runs the active REPL | acquire on entry, restore on exit; never at library load time |

The test file `test/signals.jl` asserts the parts of this contract that
can be checked after `using GAP`.

## What GAP.jl implements

**Startup.** The GAP kernel installs handlers for `SIGCHLD`
(`ChildStatusChanged` in `src/iostream.c`) and `SIGWINCH`
(`syWindowChangeIntr` in `src/sysfiles.c`) unconditionally — the
`handleSignals` argument of `GAP_Initialize` only controls `SIGINT` — and
loading the `Browse` package initializes ncurses, which installs a
`SIGTSTP` handler. `GAP.initialize` saves the dispositions of these three
signals and the terminal attributes before starting GAP and reinstates
them afterwards. In standalone mode (`gap.sh`), where GAP runs its own
REPL, nothing is touched.

**`GAP.prompt()`.** The GAP REPL legitimately takes over the terminal.
`prompt` hands it over and, in a `finally` block, hands it back to Julia
together with the error-handling state, so an abnormal exit from the GAP
session cannot leave Julia's REPL in a broken state.

**Diagnostics.** [`signal_report`](@ref) prints the current
dispositions, attributing every handler to the shared library that owns
it. Run it whenever Ctrl-C, subprocesses, or the terminal misbehave:

```julia
julia> GAP.signal_report();
SIGINT    handler  sigint_handler [libjulia-internal.1.12.7.dylib]  blocked
SIGQUIT   ignore     blocked
SIGILL    handler  sigdie_handler [libjulia-internal.1.12.7.dylib]
...
```

A `SIGCHLD` line owned by `libgap` or `io`, or a `SIGTSTP`/`SIGWINCH`
line owned by `libgap` or `ncurses`, means the contract has been
violated by something that ran after startup.

```@docs
signal_report
SignalInfo
```

## Ctrl-C and interrupts

GAP's own interrupt mechanism is embedder-friendly: the kernel function
`InterruptExecStat` is a single asynchronous-signal-safe store that makes
the interpreter raise a `user interrupt` error at the next statement
boundary. GAP.jl uses it as follows (the *interrupt bridge*):

- `JuliaInterface` installs one chaining `SIGINT` handler and remembers
  Julia's. Because of the re-raise described above, this handler runs for
  every Ctrl-C, on Julia's listener thread, without any change to the
  signal mask.
- A depth counter records whether GAP code is currently executing. It is
  maintained around the entry points from Julia into GAP and reset to
  zero while GAP calls back into Julia, so that the innermost runtime
  owns Ctrl-C. Maintaining it costs a few nanoseconds per call.
- If GAP is active, the handler calls `InterruptExecStat`; otherwise it
  forwards to Julia's handler, and Julia behaves as usual.
- While GAP waits for input at a prompt (detected through readline's
  state word, since GAP's command line editor runs GAP code for every
  key), Ctrl-C is dropped — the behavior of a standalone GAP session.
- The resulting GAP `user interrupt` error travels through GAP.jl's
  normal error bridge and is converted into a Julia `InterruptException`
  at the boundary, so that generic Julia code handles Ctrl-C uniformly.
- Inside `GAP.prompt()` Ctrl-C enters GAP's break loop, as in a
  standalone GAP session. GAP's own `SIGINT` handler, whose
  double-Ctrl-C path terminates the whole process from inside a signal
  handler, is not used.

Interrupts arrive at GAP statement boundaries only; a long computation
inside a single kernel function is not interruptible, as in standalone
GAP. The design relies on Julia re-dispatching `SIGINT` through the
process disposition; should a future Julia stop doing that, the bridge
degrades to the previous behavior (Ctrl-C takes effect when control
returns to Julia) and never to a crash.

## Child processes and `SIGCHLD`

Three code paths in a GAP.jl session create child processes:

- GAP's `Process`/`Exec` (kernel `ExecuteProcess`). `JuliaInterface`
  replaces it by a Julia implementation based on `run`, controlled by
  `GAP.use_orig_ExecuteProcess[]`. The replacement is currently disabled
  because the io package's reaping steals libuv's children (the hang of
  GAP.jl#902); it will be enabled by default once an io release that
  follows the contract is shipped.
- GAP's pty-based `InputOutputLocalProcess` (kernel `iostream.c`), which
  reaps its own children per pid but relied on the `SIGCHLD` handler to
  notice a dead child early. Without the handler, a dead child is noticed
  when the stream is next used or closed.
- The io package (`IO_fork`, `IO_Popen*`, `IO_WaitPid`), which installs
  its own `SIGCHLD` handler and reaps with `waitpid(-1)` whenever its
  process functions are used. This is the remaining contract violation:
  after it, Julia's subprocess handling hangs. The fix (embedded and
  HPC-GAP mode: no handler, per-pid reaping of registered children only)
  belongs to io 4.10.1 together with the pre-fork signal reset that makes
  forked children terminable again. Until GAP.jl ships that io version,
  the `utils` and `curlInterface` packages stay excluded from the package
  distro tests, and `test/signals.jl` keeps an opt-in test
  (`GAPJL_TEST_SIGNALS_IO=1`) documenting the breakage.

## Terminal

The GAP kernel enters raw mode only while reading from a terminal, and
its `SIGTSTP` handling is scoped to raw mode — that is the right handover
pattern. `SIGWINCH` is installed at startup and will be gated on embedded
mode in a future GAP release. `Browse` initializes ncurses when it is
loaded rather than when it first draws on the screen; a patch making that
initialization lazy, with ncurses's handlers installed only while a
Browse application is on screen, fixes both GAP.jl#741 and gap#430.

## Guidance for other embedded libraries

A Julia package that embeds a C/C++ library should:

1. Never let the library install handlers for the fault signals. If its
   initialization does so, save and restore the dispositions with
   `sigaction` (not `signal`) around the call, as `GAP.initialize` does;
   the helpers in `src/signals.jl` can be copied.
2. Configure the library not to handle `SIGINT` at all (like RCall's
   `R_SignalHandlers = 0`), or install a chaining handler plus a depth
   counter as described above if interruptible computations are wanted.
   Wrapping every call in `Base.disable_sigint` (Polymake.jl's approach)
   is safe but makes Ctrl-C ineffective during the call.
3. Make sure the library reaps only its own children, per pid, and
   never installs a `SIGCHLD` handler or calls `waitpid(-1)`.
4. If the library forks, reset the signal mask and the dispositions of
   the termination signals before forking (see `FuncIO_fork` in io ≥
   4.10.1 for a template).
5. Add a test that prints the equivalent of [`signal_report`](@ref)
   after loading the library and asserts that the fault signals and
   `SIGINT` still belong to Julia and that `SIGCHLD` is untouched.

## Compatibility

| Behavior | released GAP + io | with io ≥ 4.10.1 | with the next GAP release |
|:---|:---|:---|:---|
| Julia's `run()` after `using GAP` | works | works | works |
| Julia's `run()` after io process functions | hangs | works | works |
| `SIGTERM` to children forked by io | ignored | works | works |
| Ctrl-C during a GAP computation | interrupt bridge (GAP.jl) | same | same, with a public kernel API |
| Julia implementation of `ExecuteProcess` | disabled | enabled | enabled |
| `SIGWINCH` handler after startup | restored by GAP.jl | same | not installed by GAP |
| dead pty child noticed | on next use/close | same | on next use (kernel polls) |

## Open items

- GAP kernel (next release): public `GAP_InterruptExecStat` and a way to
  tell a user interrupt from an error in the libgap API; gate the
  `SIGWINCH` handler and the process-exit path of `syAnswerIntr` on
  embedded mode; replace the `SIGCHLD` handler by polling at the points
  that consume its information; reset the signal state before forking in
  `SyExecuteProcess`.
- io package: 4.10.1 with the pre-fork signal reset and per-pid reaping
  in embedded/HPC-GAP mode (closes io#5).
- Browse package: lazy ncurses initialization.
- Julia: a supported save/restore API for signal handlers
  ([julia#46076](https://github.com/JuliaLang/julia/issues/46076));
  GAP.jl depends on the `SIGINT` re-dispatch in `jl_ignore_sigint`.
