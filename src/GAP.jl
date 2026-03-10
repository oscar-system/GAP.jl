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

"""
GAP.jl is the Julia interface to the GAP computer algebra system.

For the package manual see <https://oscar-system.github.io/GAP.jl/>.

For more information about GAP see <https://www.gap-system.org/>.
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
import Artifacts: find_artifacts_toml, load_artifacts_toml, artifact_path

import GAP_jll: GAP_jll, libgap
import GAP_lib_jll

GAP_jll.is_available() ||
   error("""This platform or julia version is currently not supported by GAP:
            $(Base.BinaryPlatforms.host_triplet())""")

include("setup.jl")

import Libdl
import Random

const sysinfo = Setup.read_sysinfo_gap(joinpath(GAP_jll.find_artifact_dir(), "lib", "gap", "sysinfo.gap"))
const GAP_VERSION = VersionNumber(sysinfo["GAP_VERSION"])

include("types.jl")

"""
    GAP.@include(path)

Read and execute the GAP code in the file at `path`.

Note that `path`  must be either an absolute path or a path relative to
the file where this macro is used. This is similar to julia's built-in
`include` function, but for GAP code instead of Julia code.
"""
macro include(path)
    return :(Wrappers.Read(GapObj(normpath(@__DIR__, $path))))
end

const last_error = Ref{String}("")

const disable_error_handler = Ref{Bool}(false)

function copy_gap_error_to_julia()
    global disable_error_handler
    if disable_error_handler[]
        return
    end
    last_error[] = String(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj)
    @ccall libgap.SET_LEN_STRING(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj, 0::Cuint)::Cvoid
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
    @ccall libgap.ClearError()::Cvoid
    # reset global execution context
    @ccall libgap.SWITCH_TO_BOTTOM_LVARS()::Cvoid
    # at the top of GAP's exception handler chain, turn the GAP exception
    # into a Julia exception
    if depth <= 0
        error("Error thrown by GAP: $(get_and_clear_last_error())")
    end
end

# path to JuliaInterface.so
JuliaInterface_path::String = "" # will be set in __init__()
const _saved_argv = Ref{Ref{Ptr{UInt8}}}()

function initialize(argv::Vector{String})
    @ccall libgap.GAP_InitJuliaMemoryInterface((@__MODULE__)::Any, C_NULL::Ptr{Nothing})::Nothing

    handle_signals = isdefined(Main, :__GAP_ARGS__)  # a bit of a hack...
    error_handler_func = @cfunction(copy_gap_error_to_julia, Cvoid, ())

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

    @ccall libgap.GAP_Initialize(
        length(argv)::Int32,
        _saved_argv[]::Ptr{Ptr{UInt8}},
        C_NULL::Ptr{Cvoid},
        error_handler_func::Ptr{Cvoid},
        handle_signals::Cuint,
    )::Cvoid

    global _GAP_True[] = unsafe_load(cglobal((:GAP_True, libgap), Ptr{Cvoid}))
    global _GAP_False[] = unsafe_load(cglobal((:GAP_False, libgap), Ptr{Cvoid}))

    ## At this point, the GAP module has not been completely initialized, and
    ## hence is not yet available under the global binding "GAP"; but
    ## JuliaInterface needs to access it. To make that possible, we dlopen
    ## its kernel extension already here, and poke a pointer to this module
    ## into the kernel extension's global variable `gap_module`
    @debug "storing pointer to Julia module 'GAP' into JuliaInterface"
    Libdl.dlopen(JuliaInterface_path)
    mptr = pointer_from_objref(@__MODULE__)
    g = cglobal((:gap_module, JuliaInterface_path), Ptr{Cvoid})
    unsafe_store!(g, mptr)

    # also declare a global GAP variable with the path to JuliaInterface.so
    AssignGlobalVariable("_path_JuliaInterface_so", MakeString(JuliaInterface_path))

    # now load init.g
    @debug "about to read init.g"
    if (@ccall libgap.READ_GAP_ROOT("lib/init.g"::Ptr{Cchar})::Int64) == 0
        error("failed to read lib/init.g")
    end
    @debug "finished reading init.g"

    # register our ThrowObserver callback
    f = @cfunction(ThrowObserver, Cvoid, (Cint, ))
    @ccall libgap.RegisterThrowObserver(f::Ptr{Cvoid})::Cvoid

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

    # Redirect error messages, in order not to print them to the screen.
    GAP.@include("../gap/err.g")
    @debug "finished reading gap/err.g"

    return nothing
end

function exit_code()
    return (@ccall libgap.GAP_CallFuncArray(_ValueGlobalVariable("GapExitCode")::Ptr{Cvoid}, 0::Culonglong, C_NULL::Ptr{Cvoid})::Int) >> 2
end

const _GAP_True = Ref(Ptr{Nothing}(0))
const _GAP_False = Ref(Ptr{Nothing}(0))

function __init__()
    # error message at runtime
    if Sys.iswindows()
        windows_error()
    end

    global JuliaInterface_path = Setup.locate_JuliaInterface_so()

    roots = [
            # GAP root for the the actual GAP library, from GAP_lib_jll
            abspath(GAP_lib_jll.find_artifact_dir(), "share", "gap"),
            # GAP root into which PackageManager installs packages by default
            Packages.gap_packages_rootdir(),
            ]
    cmdline_options = ["", "-l", join(roots, ";")]

    # tell GAP about all artifacts that contain GAP packages
    artifacts_toml = find_artifacts_toml(@__FILE__)
    artifacts_toml !== nothing || error("Cannot locate 'Artifacts.toml' file for package GAP")
    artifact_dict = load_artifacts_toml(artifacts_toml)

    pkgdirs = String[]
    for (name, meta) in artifact_dict
        startswith(name, "GAP_pkg_") || continue
        hash = Base.SHA1(meta["git-tree-sha1"]::String)
        push!(pkgdirs, artifact_path(hash; honor_overrides=true))
    end
    push!(pkgdirs, abspath(@__DIR__, "..", "pkg", "JuliaInterface"))
    push!(pkgdirs, abspath(@__DIR__, "..", "pkg", "JuliaExperimental"))
    push!(cmdline_options, "--packagedirs", join(pkgdirs, ';'))

    # If we were started via gap.sh, leave it to `Main.__GAP_ARGS__`
    # whether a GAP banner gets printed.
    # Otherwise we ask GAP not to print the banner,
    # instead we will call the relevant functions ourselves if appropriate.
    if isdefined(Main, :__GAP_ARGS__)
        # we were started via gap.sh, handle user command line arguments
        append!(cmdline_options, Main.__GAP_ARGS__)
    else
        # started regularly
        append!(cmdline_options, ["-b", "--nointeract"])
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

    if haskey(ENV, "GAP_BARE_DEPS")
        push!(cmdline_options, "-A")
    end

    # Start GAP.
    initialize(cmdline_options)

    if !isdefined(Main, :__GAP_ARGS__)
        # We had started GAP with the `-b` option.
        # Reset this option in order to leave it to GAP's `LoadPackage`
        # whether package banners are shown.
        # Note that a second argument `false` of this function suppresses the
        # package banner,
        # but no package banners can be shown if the `-b` option is `true`.
        evalstr_ex("""
            GAPInfo.CommandLineOptions := ShallowCopy(GAPInfo.CommandLineOptions);
            GAPInfo.CommandLineOptions.b := false;
            MakeImmutable(GAPInfo.CommandLineOptions);
        """)

        show_banner = AbstractAlgebra.should_show_banner() &&
                     get(ENV, "GAP_PRINT_BANNER", "true") != "false"

        if show_banner
            Globals.ShowKernelInformation();
            Globals.GAPInfo.ShowPackageInformation();
        end
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

"""
    versioninfo(io::IO = stdout; jll::Bool = false, full::Bool = false)

Print to `io` the versions of GAP.jl and GAP,
and versions and installation paths of all loaded GAP packages.

Note that these paths can be nonstandard because Julia's package manager
does not control which available version of a GAP package gets loaded.

If `jll` or `full` is `true` then also the underlying binary packages (jll),
if available, of all installed (not necessarily loaded) packages
are included in the output.
"""
function versioninfo(io::IO = stdout; jll::Bool = false, full::Bool = false, padding::String = "")
  if full
    jll = true
  end
  println(io, "GAP.jl version ", Base.pkgversion(@__MODULE__))
  GAP.Packages.versioninfo(io; GAP = true, full = full, jll = jll, padding = padding)
end

include("lowlevel.jl")
include("ccalls.jl")
include("globals.jl")

include("macros.jl")
include("wrappers.jl")

include("adapter.jl")

include("conversion.jl")
include("gap_to_julia.jl")
include("constructors.jl")
include("julia_to_gap.jl")

include("utils.jl")
include("help.jl")
include("prompt.jl")
include("exec.jl")
include("doctestfilters.jl")

include("GAP_pkg.jl")
include("packages.jl")

end
