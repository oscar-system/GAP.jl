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

# Map a GAP stream id to something `run` accepts as `stdin` / `stdout`.
# Negative ids mean "no stream".
function gap_stream_to_julia(id::Int, name::String)
    id < 0 && return Base.devnull
    fd = @ccall libgap.SyBufFileno(id::Culong)::Int
    fd == -1 && error("$name invalid")
    return RawFD(fd)
end

function GAP_ExecuteProcess(dir::String, prg::String, fin::Int, fout::Int, args::Vector{String})
    # Note: the GAP kernel function `ExecuteProcess` also handles so-called
    # "window mode", for use in xgap and Gap.app -- we do not emulate this here.
    instream = gap_stream_to_julia(fin, "fin")
    outstream = gap_stream_to_julia(fout, "fout")

    # TODO: verify `dir` is a valid dir?
    cd(dir) do
        res = run(pipeline(ignorestatus(`$prg $args`), stdin=instream, stdout=outstream))
        return res.exitcode == 255 ? GAP.Globals.Fail : res.exitcode
    end
end
