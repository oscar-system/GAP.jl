@doc Markdown.doc"""
  GAP.jl is the Julia interface to the GAP-System.

  For more information about GAP see https://www.gap-system.org/
""" module GAP

# In order to locate the GAP installation, 'deps/build.jl' generate a file
# 'deps/deps-$(julia_version).jl' for us which sets the variable GAPROOT. We
# read this file here.
const julia_version = "$(VERSION.major).$(VERSION.minor)"
deps_jl = abspath(joinpath(@__DIR__, "..", "deps", "deps-$(julia_version).jl"))
if !isfile(deps_jl)
    # HACK: we need to compile GAP once for each Julia version, but Julia only
    # builds it for us once; so we need to check if the package was actually
    # built, and if not, trigger a build now. This *seems* to work well in
    # practice, but I am not sure if we are strictly speaking "allowed" to do
    # this
    import Pkg
    Pkg.build("GAP")
end
include(deps_jl)


import Base: length, finalize
import Libdl
import Markdown
import Random

include("types.jl")

function read_sysinfo_gap(dir::String)
    d = missing
    open(joinpath(dir, "sysinfo.gap")) do file
        d = Dict{String,String}()
        for ln in eachline(file)
            if length(ln) == 0 || ln[1] == '#'
                continue
            end
            s = split(ln, "=")
            if length(s) != 2
                continue
            end
            d[s[1]] = strip(s[2], ['"'])
        end
    end
    return d
end

const sysinfo = read_sysinfo_gap(GAPROOT)


function reset_GAP_ERROR_OUTPUT()
    # Note: strictly speaking we should close the stream here; but since it is
    # a string stream, this does nothing. So we don't do it, which saves us
    # some hassle when calling reset_GAP_ERROR_OUTPUT from `initialize`
    #Globals.CloseStream(Globals.ERROR_OUTPUT)
    evalstr("_JULIAINTERFACE_ERROR_OUTPUT:= \"\";")
    Globals.MakeReadWriteGlobal(julia_to_gap("ERROR_OUTPUT"))
    evalstr("ERROR_OUTPUT:= OutputTextString( _JULIAINTERFACE_ERROR_OUTPUT, true );")
    evalstr("SetPrintFormattingStatus( ERROR_OUTPUT, false )")
    Globals.MakeReadOnlyGlobal(julia_to_gap("ERROR_OUTPUT"))
end

disable_error_handler = false

function error_handler()
    global disable_error_handler
    if disable_error_handler
        return
    end
    str = gap_to_julia(Globals._JULIAINTERFACE_ERROR_OUTPUT)
    reset_GAP_ERROR_OUTPUT()
    error("Error thrown by GAP: ", str)
end

# The following hack is needed only in Julia 1.3, not in later versions.
error_handlerwrap() = Base.invokelatest(error_handler)

# This will be filled out by __init__(), as it must be done at runtime
libgap_path = ""
JuliaInterface_path = ""

# This will be filled out by __init__()
libgap_handle = C_NULL
JuliaInterface_handle = C_NULL

# This must be `const` so that we can use it with `ccall()`
const libgap = "libgap" # extension is automatically added
const JuliaInterface = "JuliaInterface.so"

function initialize(argv::Array{String,1})
    global libgap_path = joinpath(GAPROOT, ".libs", libgap)
    global libgap_handle = Libdl.dlopen(libgap_path, Libdl.RTLD_GLOBAL)

    handle_signals = isdefined(Main, :__GAP_ARGS__)  # a bit of a hack...
    error_handler_func = handle_signals ? C_NULL : @cfunction(error_handlerwrap, Cvoid, ())

    # Initialize __JULIAINTERNAL_LOADED_FROM_JULIA; this also allows us to
    # detect whether GAP_Initialize and GAP's `init.g` completed successfully
    # (if they didn't, then this GAP code won't be called, which we can easily
    # detect by checking for the value of __JULIAINTERNAL_LOADED_FROM_JULIA).
    append!(argv, ["-c", """BindGlobal("__JULIAINTERNAL_LOADED_FROM_JULIA", true );"""])

    ccall(
        Libdl.dlsym(libgap_handle, :GAP_Initialize),
        Cvoid,
        (Int32, Ptr{Ptr{UInt8}}, Ptr{Cvoid}, Ptr{Cvoid}, Cuint),
        length(argv),
        argv,
        C_NULL,
        error_handler_func,
        handle_signals,
    )

    # detect if GAP quit early (e.g due `-h` or `-c` command line arguments)
    # TODO: restrict this to "standalone" mode?
    # HACK: GAP resp. libgap currently offers no good way to detect this
    # (perhaps this could be a return value for GAP_Initialize?), so instead
    # we check for the presence of a global variable which we ensure is
    # declared near the end of init.g via a `-c` command line argument to GAP.
    val = ccall(
        Libdl.dlsym(libgap_handle, :GAP_ValueGlobalVariable),
        Ptr{Cvoid},
        (Ptr{Cuchar},),
        "__JULIAINTERNAL_LOADED_FROM_JULIA",
    )
    if val == C_NULL
        # Ask GAP to quit. Note that this invokes `jl_atexit_hook` so it
        # should be fine. It might be "nicer" to call Julia's `exit` function
        # here; but unfortunately we can't access GAP's exit code, which is
        # stored in `SystemErrorCode`, a statically linked (and hence
        # invisible to us) GAP C kernel variable. Hence we instead call
        # FORCE_QUIT_GAP with no arguments, which just calls the `exit`
        # function of the  C standard library with the appropriate exit code.
        # But as mentioned, just before that, it runs `jl_atexit_hook`.
        FORCE_QUIT_GAP = ccall(
            Libdl.dlsym(libgap_handle, :GAP_ValueGlobalVariable),
            Ptr{Cvoid},
            (Ptr{Cuchar},),
            "FORCE_QUIT_GAP",
        )
        ccall(
            Libdl.dlsym(libgap_handle, :GAP_CallFuncArray),
            Ptr{Cvoid},
            (Ptr{Cvoid}, Culonglong, Ptr{Cvoid}),
            FORCE_QUIT_GAP,
            0,
            C_NULL,
        )
        # we shouldn't get here, but just in case....
        error("FORCE_QUIT_GAP failed")
    end

    # verify our TNUMs are still correct
    # (Base.invokelatest is only needed for Julia 1.3)
    @assert T_INT == Base.invokelatest(ValueGlobalVariable,:T_INT)
    @assert T_INTPOS == Base.invokelatest(ValueGlobalVariable,:T_INTPOS)
    @assert T_INTNEG == Base.invokelatest(ValueGlobalVariable,:T_INTNEG)
    @assert T_RAT == Base.invokelatest(ValueGlobalVariable,:T_RAT)
    @assert T_CYC == Base.invokelatest(ValueGlobalVariable,:T_CYC)
    @assert T_FFE == Base.invokelatest(ValueGlobalVariable,:T_FFE)
    @assert T_MACFLOAT == Base.invokelatest(ValueGlobalVariable,:T_MACFLOAT)
    @assert T_PERM2 == Base.invokelatest(ValueGlobalVariable,:T_PERM2)
    @assert T_PERM4 == Base.invokelatest(ValueGlobalVariable,:T_PERM4)
    @assert T_TRANS2 == Base.invokelatest(ValueGlobalVariable,:T_TRANS2)
    @assert T_TRANS4 == Base.invokelatest(ValueGlobalVariable,:T_TRANS4)
    @assert T_PPERM2 == Base.invokelatest(ValueGlobalVariable,:T_PPERM2)
    @assert T_PPERM4 == Base.invokelatest(ValueGlobalVariable,:T_PPERM4)
    @assert T_BOOL == Base.invokelatest(ValueGlobalVariable,:T_BOOL)
    @assert T_CHAR == Base.invokelatest(ValueGlobalVariable,:T_CHAR)
    @assert T_FUNCTION == Base.invokelatest(ValueGlobalVariable,:T_FUNCTION)
    @assert T_BODY == Base.invokelatest(ValueGlobalVariable,:T_BODY)
    @assert T_FLAGS == Base.invokelatest(ValueGlobalVariable,:T_FLAGS)
    @assert T_LVARS == Base.invokelatest(ValueGlobalVariable,:T_LVARS)
    @assert T_HVARS == Base.invokelatest(ValueGlobalVariable,:T_HVARS)

    # load JuliaInterface
    loadpackage_return = ccall(
        Libdl.dlsym(libgap_handle, :GAP_EvalString),
        Ptr{Cvoid},
        (Ptr{UInt8},),
        "LoadPackage(\"JuliaInterface\");",
    )
    if loadpackage_return == Libdl.dlsym(libgap_handle, :GAP_Fail)
        error("JuliaInterface could not be loaded")
    end

    # If we are in "stand-alone mode", stop here
    if isdefined(Main, :__GAP_ARGS__)
        ccall(Libdl.dlsym(libgap_handle, :SyInstallAnswerIntr), Cvoid, ())
        return
    end

    # open JuliaInterface.so, too
    #global JuliaInterface_path = CSTR_STRING(EvalString("""Filename(DirectoriesPackagePrograms("JuliaInterface"), "JuliaInterface.so");"""))
    global JuliaInterface_path = normpath(joinpath(@__DIR__, "..", "pkg", "JuliaInterface", "bin", sysinfo["GAParch"], JuliaInterface))
    global JuliaInterface_handle = Libdl.dlopen(JuliaInterface_path)

    # Redirect error messages, in order not to print them to the screen.
    Base.invokelatest(reset_GAP_ERROR_OUTPUT)
end

function finalize()
    ccall((:GAP_finalize, "libgap"), Cvoid, ())
end

function run_it()
    gaproots = abspath(joinpath(@__DIR__, "..")) * ";" * sysinfo["GAP_BIN_DIR"] * ";" * sysinfo["GAP_LIB_DIR"]
    cmdline_options = ["", "-l", gaproots, "--norepl"]
    if isdefined(Main, :__GAP_ARGS__)
        append!(cmdline_options, Main.__GAP_ARGS__)
    else
        append!(cmdline_options, ["--nointeract"])
    end

    if haskey(ENV, "GAP_SHOW_BANNER")
        show_banner = ENV["GAP_SHOW_BANNER"] == "true"
    else
        show_banner =
            isinteractive() && !any(x -> x.name in ["Oscar"], keys(Base.package_locks))
    end

    if !show_banner
        # Do not show the main GAP banner by default.
        push!(cmdline_options, "-b")
    end
    initialize(cmdline_options)

    gap_module = @__MODULE__

    if !show_banner
        # Leave it to GAP's `LoadPackage` whether package banners are shown.
        # Note that a second argument `false` of this function suppresses the
        # package banner,
        # but no package banners can be shown if the `-b` option is `true`.
        Base.MainInclude.eval(
            :(
                begin
                    record = $gap_module.Globals.GAPInfo
                    record.CommandLineOptions =
                        $gap_module.Globals.ShallowCopy(record.CommandLineOptions)
                    record.CommandLineOptions.b = false
                    $gap_module.Globals.MakeImmutable(record.CommandLineOptions)
                end
            ),
        )
    end

    # Show some traceback on errors.
    Base.MainInclude.eval(:($gap_module.Globals.AlwaysPrintTracebackOnError = true))
end

function __init__()

    # The following is needed to get readline input to work right; see also
    # https://github.com/JuliaPackaging/Yggdrasil/issues/455 and
    # https://github.com/oscar-system/GAP.jl/issues/415
    if !haskey(ENV, "TERMINFO_DIRS")
        ENV["TERMINFO_DIRS"] = joinpath(@__DIR__, "..", "deps", "usr", "share", "terminfo")
    end

    ## Older versions of GAP need a pointer to the GAP.jl module during
    ## initialization, but at this point Main.GAP is not yet bound. So instead
    ## we assign this module to the name __JULIAGAPMODULE.
    ## Newer versions of GAP won't need this; however, JuliaInterface still
    ## uses it.
    gap_module = @__MODULE__
    Base.MainInclude.eval(:(__JULIAGAPMODULE = $gap_module))

    # check if GAP was already loaded
    try
        sym = cglobal("GAP_Initialize")
        ccall(:GAP_register_GapObj, Cvoid, (Any,), GapObj)
    catch e
        # GAP was not yet loaded, do so now
        run_it()
    end
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
include("adapter.jl")
include("macros.jl")
include("gap_to_julia.jl")
include("constructors.jl")
include("convert.jl")
include("julia_to_gap.jl")
include("utils.jl")
include("help.jl")
include("packages.jl")
include("prompt.jl")
include("obsolete.jl")

end
