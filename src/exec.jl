# Replacement for the GAP kernel function ExecuteProcess
const use_orig_ExecuteProcess = Ref{Bool}(true)
function GAP_ExecuteProcess(dir::GAP.Obj, prg::GAP.Obj, in::GAP.Obj, out::GAP.Obj, args::GAP.Obj)
    if use_orig_ExecuteProcess[]
        return GAP.Globals._ORIG_ExecuteProcess(dir, prg, in, out, args)
    end
    return GAP_ExecuteProcess(String(dir), String(prg), Int(in), Int(out), Vector{String}(args))
end

function GAP_ExecuteProcess(dir::String, prg::String, fin::Int, fout::Int, args::Vector{String})
    # Note: the GAP kernel function `ExecuteProcess` also handles so-called
    # "window mode", for use in xgap and Gap.app -- we do not emulate this here.
    if fin < 0
        fin = Base.devnull
    else
        fin = ccall((:SyBufFileno, libgap), Int, (Culong, ), fin)
        if fin == -1
            error("fin invalid")
        end
        fin = RawFD(fin)
    end

    if fout < 0
        fout = Base.devnull
    else
        fout = ccall((:SyBufFileno, libgap), Int, (Culong, ), fout)
        if fout == -1
            error("fout invalid")
        end
        fout = RawFD(fout)
    end

    # TODO: verify `dir` is a valid dir?
    cd(dir) do
        res = run(pipeline(ignorestatus(`$prg $args`), stdin=fin, stdout=fout))
        return res.exitcode == 255 ? GAP.Globals.Fail : res.exitcode
    end
end
