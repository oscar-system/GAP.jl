@doc Markdown.doc"""
  GAP.jl is the Julia interface to the GAP-System.

  For more information about GAP see https://www.gap-system.org/
"""
module GAP

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


"""
    FFE

Wraps a pointer to a GAP FFE immediate object.
This type is defined in the JuliaInterface C code.
"""
primitive type FFE 64 end

export FFE

import Base: length, finalize

import Libdl
import Markdown

"""
    GapObj

TODO
"""
abstract type GapObj end

export GapObj

# TODO: should we document Obj? What about ForeignGAP.MPtr?
const Obj = Union{GapObj,FFE,Int64,Bool,Nothing}

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
    Globals.CloseStream(Globals.ERROR_OUTPUT)
    EvalString("_JULIAINTERFACE_ERROR_OUTPUT:= \"\";")
    Globals.MakeReadWriteGlobal(julia_to_gap("ERROR_OUTPUT"))
    EvalString("ERROR_OUTPUT:= OutputTextString( _JULIAINTERFACE_ERROR_OUTPUT, true );")
    Globals.MakeReadOnlyGlobal(julia_to_gap("ERROR_OUTPUT"))
end

function error_handler()
    str = gap_to_julia(Globals._JULIAINTERFACE_ERROR_OUTPUT)
    reset_GAP_ERROR_OUTPUT()
    error("Error thrown by GAP: ", str)
end

function initialize(argv::Array{String,1})
    lib = joinpath(GAPROOT, ".libs", "libgap")
    gap_library = Libdl.dlopen(lib, Libdl.RTLD_GLOBAL)
    error_handler_func = @cfunction(error_handler, Cvoid, ())
    ccall(
        Libdl.dlsym(gap_library, :GAP_Initialize),
        Cvoid,
        (Int32, Ptr{Ptr{UInt8}}, Ptr{Cvoid}, Ptr{Cvoid}, Cuint),
        length(argv),
        argv,
        C_NULL,
        error_handler_func,
        Cuint(0),
    )
    ccall(
        Libdl.dlsym(gap_library, :GAP_EvalString),
        Ptr{Cvoid},
        (Ptr{UInt8},),
        "BindGlobal(\"__JULIAINTERNAL_LOADED_FROM_JULIA\", true );",
    )
    loadpackage_return = ccall(
        Libdl.dlsym(gap_library, :GAP_EvalString),
        Ptr{Cvoid},
        (Ptr{UInt8},),
        "LoadPackage(\"JuliaInterface\");",
    )
    if loadpackage_return == Libdl.dlsym(gap_library, :GAP_Fail)
        throw(ErrorException("JuliaInterface could not be loaded"))
    end

    # Redirect error messages, in order not to print them to the screen.
    ccall(
        Libdl.dlsym(gap_library, :GAP_EvalString),
        Ptr{Cvoid},
        (Ptr{UInt8},),
        "_JULIAINTERFACE_ERROR_OUTPUT:= \"\";",
    )
    ccall(
        Libdl.dlsym(gap_library, :GAP_EvalString),
        Ptr{Cvoid},
        (Ptr{UInt8},),
        "MakeReadWriteGlobal( \"ERROR_OUTPUT\" );",
    )
    ccall(
        Libdl.dlsym(gap_library, :GAP_EvalString),
        Ptr{Cvoid},
        (Ptr{UInt8},),
        "ERROR_OUTPUT:= OutputTextString( _JULIAINTERFACE_ERROR_OUTPUT, true );",
    )
    ccall(
        Libdl.dlsym(gap_library, :GAP_EvalString),
        Ptr{Cvoid},
        (Ptr{UInt8},),
        "MakeReadOnlyGlobal( \"ERROR_OUTPUT\" );",
    )
end

function finalize()
    ccall((:GAP_finalize, "libgap"), Cvoid, ())
end

function register_GapObj()
    # TODO: for now we try to stay compatible with older GAP versions that
    # don't have GAP_register_GapObj yet, but we should remove this ASAP
    try
        ccall(:GAP_register_GapObj, Cvoid, (Any,), GapObj)
    catch
        # silently ignore for now
    end
end


function run_it()
    gaproots = abspath(joinpath(@__DIR__, "..")) * ";" * sysinfo["GAP_LIB_DIR"]
    cmdline_options = ["", "-l", gaproots, "-T", "-A", "--nointeract", "-m", "1000m"]
    if get(ENV, "GAP_SHOW_BANNER", "false") != "true"
        # Do not show the main GAP banner by default.
        push!(cmdline_options, "-b")
    end
    initialize(cmdline_options)
end

function __init__()
    ## Older versions of GAP need a pointer to the GAP.jl module during
    ## initialization, but at this point Main.GAP is not yet bound. So instead
    ## we assign this module to the name __JULIAGAPMODULE.
    ## TODO: Newer versions of GAP won't need this; we should get rid of
    ## __JULIAGAPMODULE as soon as we can.
    gap_module = @__MODULE__
    Base.MainInclude.eval(:(__JULIAGAPMODULE = $gap_module))

    # check if GAP was already loaded
    try
        sym = cglobal("GAP_Initialize")
    catch e
        # GAP was not yet loaded, do so now
        run_it()
    end
    register_GapObj()

    if get(ENV, "GAP_SHOW_BANNER", "false") != "true"
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
end

function gap_exe()
    return joinpath(GAPROOT, "bin", "gap.sh")
end
export gap_exe

include("lowlevel.jl")
include("ccalls.jl")
include("adapter.jl")
include("macros.jl")
include("gap_to_julia.jl")
include("constructors.jl")
include("julia_to_gap.jl")
include("utils.jl")
include("help.jl")
include("packages.jl")

end
