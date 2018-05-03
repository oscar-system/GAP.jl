module libgap

import Base: length, convert, finalize

Libdl.dlopen("libgap", Libdl.RTLD_GLOBAL)

function error_handler(message)
    print(message)
end

error_handler_func = cfunction(error_handler,Void,(Ptr{Char},))

function initialize( argv::Array{String,1}, env::Array{String,1} )
    ccall( (:GAP_set_error_handler, "libgap")
            , Void
            , (Ptr{Void},)
            , error_handler_func)
    ccall( (:GAP_initialize, "libgap")
           , Void
           , (Int32, Ptr{Ptr{UInt8}},Ptr{Ptr{UInt8}})
           , length(argv)
           , argv
           , env )
    ccall( (:GAP_EvalString, "libgap")
           , Ptr{Void}
           , (Ptr{UInt8},)
           , "LoadPackage(\"JuliaInterface\");" )
    include("libgap.jl")
end

function finalize( )
    ccall( (:GAP_finalize, "libgap")
           , Void
           , () )
end

end