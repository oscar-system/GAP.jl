#
# This is a very hacky prototype calling libgap from julia
#

import Base: length

immutable GapObj
    data :: Ptr{Void}
end

function libgap_initialize( argv::Array{String,1} )
    ccall( (:libgap_initialize, "libgap")
           , Void
           , (Int32, Ptr{Ptr{UInt8}})
           , length(argv)
           , argv)
end

function libgap_finalize( )
    ccall( (:libgap_finalize, "libgap")
           , Void
           , () )
end

function libgap_eval_string( cmd :: String )
    return GapObj( ccall( (:libgap_eval_string, "libgap")
                          , Ptr{Void}
                          , (Ptr{UInt8},)
                          , cmd ) );
end

function libgap_call_func_list( func :: GapObj, list :: GapObj )
    return GapObj( ccall( (:CallFuncList, "libgap")
                          , Ptr{Void}
                          , (Ptr{Void}, Ptr{Void})
                          , func.data, list.data ) );
end

libgap_initialize( ["binary/lol", "-l", "/home/makx/dev/gap", "-T", "-r", "-A", "-q", "-m", "512m"] )



# libgap_eval_print("1+1+1;\n")
# libgap_eval_print("g:=FreeGroup(2);\n");
# libgap_eval_print("a:=g.1;\n");
# libgap_eval_print("b:=g.2;\n");
# libgap_eval_print("lis:=[a^2, a^2, b*a];\n");
# libgap_eval_print("h:=g/lis;\n");
# libgap_eval_print("c:=h.1;\n");
# libgap_eval_print("Set([1..1000000], i->Order(c));\n");

# libgap_finalize()
