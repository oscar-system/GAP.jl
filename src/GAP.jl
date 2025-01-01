"""
  GAP.jl is the Julia interface to the GAP-System.

  For the package manual see https://oscar-system.github.io/GAP.jl/.

  For more information about GAP see https://www.gap-system.org/.
"""
module GAP

# Show a more helpful error message for users on Windows.
windows_error() = error("""

    This package unfortunately does not run natively under Windows.
    Please install Julia using Windows subsystem for Linux and try again.
    See also https://www.oscar-system.org/install/.
    """)

# error message at precompile time
if Sys.iswindows()
  windows_error()
end

import AbstractAlgebra # for should_show_banner()
import Artifacts: find_artifacts_toml, @artifact_str
import TOML

import GAP_jll: GAP_jll, libgap

GAP_jll.is_available() ||
   error("""This platform or julia version is currently not supported by GAP:
            $(Base.BinaryPlatforms.host_triplet())""")

# Julia >= 1.10 will at some point add support for (de)serializing foreign
# types (the types, not the instances, at least not yet). We want (and need)
# to use that if available, which also requires changes in GAP resp. GAP_jll.
# To determine whether to use it, we therefore check two conditions:
# (1) whether the Julia kernel exports `jl_reinit_foreign_type`, and
# (2) whether or not GAP_jll defines GapObj.
# See https://github.com/JuliaLang/julia/pull/44527
# and https://github.com/JuliaLang/julia/pull/47407
function use_jl_reinit_foreign_type()
    if isdefined(GAP_jll, :GapObj)
        # GAP_jll still provides GapObj => use the old system
        return false
    end
    # otherwise try to use the new system
    try
        cglobal(:jl_reinit_foreign_type) != C_NULL
    catch
        false
    end
end

include("setup.jl")

import Libdl
import Random

# setup the initial sysinfo dictionary; we'll update this later in __init__
# this also ensures that Setup.regenerate_gaproot gets precompiled, reducing
# the startup time a little bit
const sysinfo = Setup.regenerate_gaproot()


include("types.jl")

const last_error = Ref{String}("")

const disable_error_handler = Ref{Bool}(false)

function copy_gap_error_to_julia()
    global disable_error_handler
    if disable_error_handler[]
        return
    end
    last_error[] = String(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj)
    ccall((:SET_LEN_STRING, libgap), Cvoid, (GapObj, Cuint), Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj, 0)
end

function get_and_clear_last_error()
    err = last_error[]
    last_error[] = ""
    return err
end

function ThrowObserver(depth::Cint)
    global disable_error_handler
    if disable_error_handler[]
        return
    end

    # signal to the GAP interpreter that errors are handled
    ccall((:ClearError, libgap), Cvoid, ())
    # reset global execution context
    ccall((:SWITCH_TO_BOTTOM_LVARS, libgap), Cvoid, ())
    # at the top of GAP's exception handler chain, turn the GAP exception
    # into a Julia exception
    if depth <= 0
        error("Error thrown by GAP: $(get_and_clear_last_error())")
    end
end

# path to JuliaInterface.so
const real_JuliaInterface_path = Ref{String}()
JuliaInterface_path() = real_JuliaInterface_path[]
const _saved_argv = Ref{Ref{Ptr{UInt8}}}()

function initialize(argv::Vector{String})
    if use_jl_reinit_foreign_type()
        ccall((:GAP_InitJuliaMemoryInterface, libgap), Nothing, (Any, Ptr{Nothing}), @__MODULE__, C_NULL)
    end

    handle_signals = isdefined(Main, :__GAP_ARGS__)  # a bit of a hack...
    error_handler_func = handle_signals ? C_NULL : @cfunction(copy_gap_error_to_julia, Cvoid, ())

    # Tell GAP to read a file during startup (after its `lib/system.g`),
    # such that `JuliaInterface` is added to the autoloaded GAP packages,
    # and such that (in GAP standalone mode) files read from the GAP command
    # line are not read before the Julia module `GAP` is available;
    # these files will be read via a function call in `gap.sh`
    # (which is created by `setup.jl`).
    append!(argv, ["--systemfile", abspath(@__DIR__, "..", "gap", "systemfile.g")])

    if ! handle_signals
        # Tell GAP to show some traceback on errors.
        append!(argv, ["--alwaystrace"])
    end

    # instruct GAP to not load init.g at the end of GAP_Initialize
    # TODO: turn this into a proper libgap API
    unsafe_store!(cglobal((:SyLoadSystemInitFile, libgap), Int64), 0)

    # the C data corresponding to argv needs to live forever
    # as this is kept in the global SyOriginalArgv pointer in GAP
    _saved_argv[] = Base.cconvert(Ptr{Ptr{UInt8}}, argv)

    ccall(
        (:GAP_Initialize, libgap),
        Cvoid,
        (Int32, Ptr{Ptr{UInt8}}, Ptr{Cvoid}, Ptr{Cvoid}, Cuint),
        length(argv),
        _saved_argv[],
        C_NULL,
        error_handler_func,
        handle_signals,
    )

    # HACK HACK HACK workaround
    Base.GC.gc(true)

    ## At this point, the GAP module has not been completely initialized, and
    ## hence is not yet available under the global binding "GAP"; but
    ## JuliaInterface needs to access it. To make that possible, we dlopen
    ## its kernel extension already here, and poke a pointer to this module
    ## into the kernel extension's global variable `gap_module`
    @debug "storing pointer to Julia module 'GAP' into JuliaInterface"
    Libdl.dlopen(JuliaInterface_path())
    mptr = pointer_from_objref(@__MODULE__)
    g = cglobal((:gap_module, JuliaInterface_path()), Ptr{Cvoid})
    unsafe_store!(g, mptr)

    # also declare a global GAP variable with the path to JuliaInterface.so
    AssignGlobalVariable("_path_JuliaInterface_so", MakeString(JuliaInterface_path()))

    # now load init.g
    @debug "about to read init.g"
    if ccall((:READ_GAP_ROOT, libgap), Int64, (Ptr{Cchar},), "lib/init.g") == 0
        error("failed to read lib/init.g")
    end
    @debug "finished reading init.g"

    # register our ThrowObserver callback
    f = @cfunction(ThrowObserver, Cvoid, (Cint, ))
    ccall((:RegisterThrowObserver, libgap), Cvoid, (Ptr{Cvoid},), f)

    # detect if GAP quit early (e.g due `-h` or `-c` command line arguments)
    # TODO: restrict this to "standalone" mode?
    # HACK: GAP resp. libgap currently offers no good way to detect this
    # (perhaps this could be a return value for GAP_Initialize?),
    # so instead we check for the presence of the global variable
    # `ProcessInitFiles` which is declared near the end of GAP's `init.g`;
    val = _ValueGlobalVariable("ProcessInitFiles")

    if val == C_NULL
        exit(exit_code())
    end

    # verify our TNUMs are still correct
    @assert T_INT == ValueGlobalVariable(:T_INT)
    @assert T_INTPOS == ValueGlobalVariable(:T_INTPOS)
    @assert T_INTNEG == ValueGlobalVariable(:T_INTNEG)
    @assert T_RAT == ValueGlobalVariable(:T_RAT)
    @assert T_CYC == ValueGlobalVariable(:T_CYC)
    @assert T_FFE == ValueGlobalVariable(:T_FFE)
    @assert T_MACFLOAT == ValueGlobalVariable(:T_MACFLOAT)
    @assert T_PERM2 == ValueGlobalVariable(:T_PERM2)
    @assert T_PERM4 == ValueGlobalVariable(:T_PERM4)
    @assert T_TRANS2 == ValueGlobalVariable(:T_TRANS2)
    @assert T_TRANS4 == ValueGlobalVariable(:T_TRANS4)
    @assert T_PPERM2 == ValueGlobalVariable(:T_PPERM2)
    @assert T_PPERM4 == ValueGlobalVariable(:T_PPERM4)
    @assert T_BOOL == ValueGlobalVariable(:T_BOOL)
    @assert T_CHAR == ValueGlobalVariable(:T_CHAR)
    @assert T_FUNCTION == ValueGlobalVariable(:T_FUNCTION)
    @assert T_BODY == ValueGlobalVariable(:T_BODY)
    @assert T_FLAGS == ValueGlobalVariable(:T_FLAGS)
    @assert T_LVARS == ValueGlobalVariable(:T_LVARS)
    @assert T_HVARS == ValueGlobalVariable(:T_HVARS)
    @assert FIRST_EXTERNAL_TNUM == ValueGlobalVariable(:FIRST_EXTERNAL_TNUM)

    # check that JuliaInterface has been loaded
    # (it binds the GAP variable `Julia`)
    if _ValueGlobalVariable("Julia") == C_NULL
        error("JuliaInterface could not be loaded")
    end

    GAP.Globals.Read(GapObj(joinpath(@__DIR__, "..", "gap", "exec.g")))
    @debug "finished reading gap/exec.g"

    # If we are in "stand-alone mode", stop here
    if handle_signals
        ccall((:SyInstallAnswerIntr, libgap), Cvoid, ())
        return
    end

    # Redirect error messages, in order not to print them to the screen.
    GAP.Globals.Read(GapObj(joinpath(@__DIR__, "..", "gap", "err.g")))
    @debug "finished reading gap/err.g"

    return nothing
end

function exit_code()
    return ccall(
            (:GAP_CallFuncArray, libgap),
            Int,
            (Ptr{Cvoid}, Culonglong, Ptr{Cvoid}),
            _ValueGlobalVariable("GapExitCode"),
            0,
            C_NULL,
        ) >> 2
end

function __init__()
    # error message at runtime
    if Sys.iswindows()
        windows_error()
    end

    # always regenerate our custom GAP root dir, to accommodate for changes
    # in the system configuration (artifact paths, available compilers, ...)
    global sysinfo
    merge!(sysinfo, Setup.regenerate_gaproot())

    real_JuliaInterface_path[] = Setup.locate_JuliaInterface_so(sysinfo)

    gaproots = sysinfo["GAPROOTS"]
    cmdline_options = ["", "-l", gaproots]

    # tell GAP about all artifacts that contain GAP packages
    pkg_artifacts = filter(startswith("GAP_pkg_"), keys(TOML.parsefile(find_artifacts_toml(@__FILE__))))
    pkgdirs = join((realpath(@artifact_str(name)) for name in pkg_artifacts), ';')
    append!(cmdline_options, ["--packagedirs", pkgdirs])

    if isdefined(Main, :__GAP_ARGS__)
        # we were started via gap.sh, handle user command line arguments
        append!(cmdline_options, Main.__GAP_ARGS__)
    else
        # started regularly
        append!(cmdline_options, ["--nointeract"])
    end

    # ensure GAP exit handler is run when we exit
    Base.atexit() do
        try
            GAP.Globals.PROGRAM_CLEAN_UP()
        catch e
            showerror(stderr, e, catch_backtrace())
            exit(1) # signal error
        end
    end

    show_banner = AbstractAlgebra.should_show_banner() &&
                 get(ENV, "GAP_PRINT_BANNER", "true") != "false"

    if !show_banner
        # Do not show the main GAP banner by default.
        push!(cmdline_options, "-b")
    end

    if haskey(ENV, "GAP_BARE_DEPS")
        push!(cmdline_options, "-A")
    end

    initialize(cmdline_options)

    if !show_banner
        # Leave it to GAP's `LoadPackage` whether package banners are shown.
        # Note that a second argument `false` of this function suppresses the
        # package banner,
        # but no package banners can be shown if the `-b` option is `true`.
        evalstr_ex("""
            GAPInfo.CommandLineOptions := ShallowCopy(GAPInfo.CommandLineOptions);
            GAPInfo.CommandLineOptions.b = false;
            MakeImmutable(GAPInfo.CommandLineOptions);
        """)
    end

    Packages.init_packagemanager()
end

"""
    GAP.randseed!([seed::Integer])

Reseed GAP's global RNG with `seed`.

The given `seed` must be a non-negative integer.
When `seed` is not specified, a random seed is generated from Julia's global RNG.

For a fixed seed, the stream of generated numbers is allowed to change between
different versions of GAP.
"""
function randseed!(seed::Union{Integer,Nothing}=nothing)
    seed = something(seed, rand(UInt128))
    Globals.Reset(Globals.GlobalMersenneTwister, seed)
    # when GlobalRandomSource is reset, the seed is taken modulo 2^28, so we just
    # pass an already reduced seed here
    Globals.Reset(Globals.GlobalRandomSource, seed % Int % 2^28)
    nothing
end

include("lowlevel.jl")
include("ccalls.jl")
include("globals.jl")

include("macros.jl")
include("wrappers.jl")

include("adapter.jl")
include("gap_to_julia.jl")
include("constructors.jl")
include("julia_to_gap.jl")
include("utils.jl")
include("help.jl")
include("packages.jl")
include("prompt.jl")
include("exec.jl")
include("doctestfilters.jl")

include("GAP_pkg.jl")

end
