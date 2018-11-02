using Test

include("runtests_dir.jl")

include(INIT_FILE)

libgap.run_it(GAPPATH)

include("basics.jl")
include("convenience.jl")
