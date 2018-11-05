module libgap

import Base: length, convert, finalize

import Libdl

sysinfo = missing

read_sysinfo_gap = function(dir::String)
    d = missing
    open(dir * "/sysinfo.gap") do file
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

function error_handler(message)
    print(message)
end

error_handler_func = @cfunction(error_handler,Cvoid,(Ptr{Char},))

const pkgdir = realpath(dirname(@__FILE__))

function initialize( argv::Array{String,1}, env::Array{String,1} )
    gap_library = Libdl.dlopen("libgap", Libdl.RTLD_GLOBAL)
    ccall( Libdl.dlsym(gap_library, :GAP_Initialize)
           , Cvoid
           , (Int32, Ptr{Ptr{UInt8}},Ptr{Ptr{UInt8}},Ptr{Cvoid},Ptr{Cvoid})
           , length(argv)
           , argv
           , env
           , C_NULL
           , error_handler_func)
    ccall( Libdl.dlsym(gap_library, :GAP_EvalString)
           , Ptr{Cvoid}
           , (Ptr{UInt8},)
           , "BindGlobal(\"JULIAINTERNAL_LOADED_FROM_JULIA\", true );" )
    ccall( Libdl.dlsym(gap_library, :GAP_EvalString)
           , Ptr{Cvoid}
           , (Ptr{UInt8},)
           , "LoadPackage(\"JuliaInterface\");" )
    Base.include( Main.GAP, pkgdir * "/libgap.jl")
end

function finalize( )
    ccall( (:GAP_finalize, "libgap")
           , Cvoid
           , () )
end

gap_is_initialized = false

run_it = function(gapdir::String)
    global sysinfo, gap_is_initialized
    if gap_is_initialized
        throw(ErrorException("GAP already initialized"))
    end
    sysinfo = read_sysinfo_gap(gapdir)
    println("Adding path ", gapdir * "/.libs", " to DL_LOAD_PATH")
    push!( Libdl.DL_LOAD_PATH, gapdir * "/.libs" )
    initialize( [ ""
                       , "-l", sysinfo["GAP_LIB_DIR"]
                       , "-T", "-r", "-A", "--nointeract"
                       , "-m", "512m" ], [""] )
    gap_is_initialized = true
end


end
