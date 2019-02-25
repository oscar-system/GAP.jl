using Test

include("runtests_dir.jl")

if ! @isdefined(GAP)
    include(INIT_FILE)
end

if !GAP.gap_is_initialized
    GAP.run_it(GAPPATH)
end

include("basics.jl")
include("convenience.jl")
include("conversion.jl")
