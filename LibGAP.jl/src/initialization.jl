module libgap

import Base: length, convert, finalize

using Libdl

dlopen("libgap", Libdl.RTLD_GLOBAL)

function error_handler(message)
    print(message)
end

error_handler_func = @cfunction(error_handler,Cvoid,(Ptr{Char},))

const pkgdir = realpath(dirname(@__FILE__))

function initialize( argv::Array{String,1}, env::Array{String,1} )
    ccall( (:GAP_set_error_handler, "libgap")
            , Cvoid
            , (Ptr{Cvoid},)
            , error_handler_func)
    ccall( (:GAP_initialize, "libgap")
           , Cvoid
           , (Int32, Ptr{Ptr{UInt8}},Ptr{Ptr{UInt8}})
           , length(argv)
           , argv
           , env )
    ccall( (:GAP_EvalString, "libgap")
           , Ptr{Cvoid}
           , (Ptr{UInt8},)
           , "LoadPackage(\"JuliaInterface\");" )
    include( pkgdir * "/libgap.jl")
end

function finalize( )
    ccall( (:GAP_finalize, "libgap")
           , Cvoid
           , () )
end

end
