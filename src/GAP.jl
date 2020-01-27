module GAP

# In order to locate the GAP installation, 'deps/build.jl' generate a file
# 'deps/deps.jl' for us which sets the variable GAPROOT. We read this file
# here.
include(abspath(joinpath(@__DIR__, "..", "deps", "deps.jl")))

"""
    FFE

> Wraps a pointer to a GAP FFE immediate object
> This type is defined in the JuliaInterface C code.
"""

primitive type FFE 64 end

export FFE

import Base: length, convert, finalize

import Libdl

abstract type GapObj end

export GapObj

const Obj = Union{GapObj,FFE,Int64,Bool,Nothing}

sysinfo = missing

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
            d[s[1]] = strip(s[2], [ '"' ])
        end
    end
    return d
end

function error_handler()
    error("Error thrown by GAP")
end

function initialize( argv::Array{String,1}, env::Array{String,1}, error_handler_func::Ptr{Nothing} )
    gap_library = Libdl.dlopen("libgap", Libdl.RTLD_GLOBAL)
    ccall( Libdl.dlsym(gap_library, :GAP_Initialize)
           , Cvoid
           , (Int32, Ptr{Ptr{UInt8}},Ptr{Cvoid},Ptr{Cvoid},Cuint)
           , length(argv)
           , argv
           , C_NULL
           , error_handler_func
           , Cuint(0) )
    ccall( Libdl.dlsym(gap_library, :GAP_EvalString)
           , Ptr{Cvoid}
           , (Ptr{UInt8},)
           , "BindGlobal(\"__JULIAINTERNAL_LOADED_FROM_JULIA\", true );" )
    ccall( Libdl.dlsym(gap_library, :GAP_EvalString)
           , Ptr{Cvoid}
           , (Ptr{UInt8},)
           , "_JULIAINTERNAL_JULIAINTERFACE_LOADED := LoadPackage(\"JuliaInterface\");" )
    loadpackage_return = ccall( Libdl.dlsym(gap_library, :GAP_EvalString)
           , Ptr{Cvoid}
           , (Ptr{UInt8},)
           , "_JULIAINTERNAL_JULIAINTERFACE_LOADED;" )
    if loadpackage_return == Libdl.dlsym(gap_library, :GAP_Fail )
        throw(ErrorException( "JuliaInterface could not be loaded" ))
    end
end

function finalize( )
    ccall( (:GAP_finalize, "libgap"), Cvoid, () )
end

function register_GapObj()
    # TODO: for now we try to stay compatible with older GAP versions that
    # don't have GAP_register_GapObj yet, but we should remove this ASAP
    try
        ccall( :GAP_register_GapObj, Cvoid, (Any, ), GapObj )
    catch
        # silently ignore for now
    end
end


gap_is_initialized = false

run_it = function(gapdir::String, error_handler_func::Ptr{Nothing})
    global sysinfo, gap_is_initialized
    if gap_is_initialized
        error("GAP already initialized")
    end
    sysinfo = read_sysinfo_gap(gapdir)
    gapdir = joinpath(gapdir, ".libs")
    println("Adding path ", gapdir, " to DL_LOAD_PATH")
    push!( Libdl.DL_LOAD_PATH, gapdir )
    gaproots = abspath(joinpath(@__DIR__, "..")) * ";" * sysinfo["GAP_LIB_DIR"]
    initialize( [ ""
                       , "-l", gaproots
                       , "-T", "-r", "-A", "--nointeract"
                       , "-m", "1000m" ], [""], error_handler_func )
    gap_is_initialized = true
end

function __init__()
    error_handler_func = @cfunction(error_handler, Cvoid, ())

    ## Older versions of GAP need a pointer to the GAP.jl module during
    ## initialization, but at this point Main.GAP is not yet bound. So instead
    ## we assign this module to the name __JULIAGAPMODULE.
    ## TODO: Newer versions of GAP won't need this; we should get rid of
    ## __JULIAGAPMODULE as soon as we can.
    gap_module = @__MODULE__
    Base.MainInclude.eval(:(__JULIAGAPMODULE = $gap_module))

    # TODO: try to get rid of __GAPINTERNAL_LOADED_FROM_GAP, too
    if ! isdefined(Main, :__GAPINTERNAL_LOADED_FROM_GAP) || Main.__GAPINTERNAL_LOADED_FROM_GAP != true
        run_it(GAPROOT, error_handler_func)
    end
    register_GapObj()

    ## FIXME: Hack because abstract types cannot be endowed with methods in Julia 1.1.
    ## With Julia 1.2, this will be possible and this hack could then be replaced with the
    ## corresponding function call in in ccalls.jl (func::GapObj)(...)
    MPtr = Base.MainInclude.eval(:(ForeignGAP.MPtr))
    Base.MainInclude.eval(:(
        (func::$MPtr)(args...; kwargs...) = $(GAP.call_gap_func)(func, args...; kwargs...)
    ))
end

include( "ccalls.jl" )
include( "adapter.jl" )
include( "packages.jl" )
include( "macros.jl" )
include( "gap_to_julia.jl" )
include( "julia_to_gap.jl" )
include( "utils.jl" )
include( "help.jl" )

end
