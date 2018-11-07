using Test

include("runtests_dir.jl")

if ! @isdefined(libgap)
    include(INIT_FILE)
end

if !libgap.gap_is_initialized
    libgap.run_it(GAPPATH)
end

include("basics.jl")
include("convenience.jl")
