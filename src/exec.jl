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

# Replacement for the GAP kernel function ExecuteProcess
const use_orig_ExecuteProcess = Ref{Bool}(true)
function GAP_ExecuteProcess(dir::GapObj, prg::GapObj, in::GapInt, out::GapInt, args::GapObj)
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
        fin = @ccall libgap.SyBufFileno(fin::Culong)::Int
        if fin == -1
            error("fin invalid")
        end
        fin = RawFD(fin)
    end

    if fout < 0
        fout = Base.devnull
    else
        fout = @ccall libgap.SyBufFileno(fout::Culong)::Int
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
