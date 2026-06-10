using Revise
using JET

struct AnyFrameMethod <: ReportMatcher
    m::Union{Function,Method,Symbol}
end

function JET.match_report(matcher::AnyFrameMethod, @nospecialize(report::JET.InferenceErrorReport))
    # check all VirtualFrames in the VirtualStackTrace for a match to the specified method
    m = matcher.m
    if m isa Symbol
        return any(vf -> vf.linfo.def.name === m, report.vst)
    elseif m isa Method
        return any(vf -> vf.linfo.def === m, report.vst)
    else # if m isa Function
        return any(vf -> vf.linfo.def in methods(m), report.vst)
    end
end

using GAP; report_package(GAP; ignored_modules=[
        AnyFrameMethod(:is_loaded_directly),
        AnyFrameMethod(:ca_roots_path),
        ])
