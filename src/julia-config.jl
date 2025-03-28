# This file is based on the file `contrib/julia-config.jl` which is a
# part of Julia. License is MIT: https://julialang.org/license

import Libdl

function shell_escape(str)
    str = replace(str, "'" => "'\''")
    return "'$str'"
end

function libDir()
    return if (@ccall jl_is_debugbuild()::Cint) != 0
        if Base.DARWIN_FRAMEWORK
            joinpath(dirname(abspath(Libdl.dlpath(Base.DARWIN_FRAMEWORK_NAME * "_debug"))),"lib")
        else
            dirname(abspath(Libdl.dlpath("libjulia-debug")))
        end
    else
        if Base.DARWIN_FRAMEWORK
            joinpath(dirname(abspath(Libdl.dlpath(Base.DARWIN_FRAMEWORK_NAME))),"lib")
        else
            dirname(abspath(Libdl.dlpath("libjulia")))
        end
    end
end

private_libDir() = abspath(Sys.BINDIR, Base.PRIVATE_LIBDIR)

function includeDir()
    return abspath(Sys.BINDIR, Base.INCLUDEDIR, "julia")
end

function ldflags()
    fl = "-L$(shell_escape(libDir()))"
    if Sys.iswindows()
        fl = fl * " -Wl,--stack,8388608"
    elseif !Sys.isapple()
        fl = fl * " -Wl,--export-dynamic"
    end
    env_var = get(ENV, "LDFLAGS", nothing)
    if !isnothing(env_var)
        fl = fl * " " * env_var
    end
    return fl
end

function ldlibs()
    libname = if (@ccall jl_is_debugbuild()::Cint) != 0
        "julia-debug"
    else
        "julia"
    end
    if Sys.isunix()
        return "-Wl,-rpath,$(shell_escape(libDir())) " *
            (Sys.isapple() ? string() : "-Wl,-rpath,$(shell_escape(private_libDir())) ") *
            "-l$libname"
    else
        return "-l$libname -lopenlibm"
    end
end

function cflags()
    flags = IOBuffer()
    print(flags, "-std=gnu99")
    include = shell_escape(includeDir())
    print(flags, " -I", include)
    if Sys.isunix()
        print(flags, " -fPIC")
    end
    env_var = get(ENV, "CFLAGS", nothing)
    if !isnothing(env_var)
        print(flags, " ", env_var)
    end
    return String(take!(flags))
end
