# Define some replacements which are applied in `docs/make.jl` and `test/testmanual.jl`.
# The idea is that the `jldoctest`ed examples in the source files
# have the format that fits to the "current" Julia,
# and that other Julia versions (such as Julia nightly) may show different formats.
# Each regular expression in `GAP_doctestfilters` gets applied to both the
# expected output and the output obtained in the actual evaluation,
# before the comparison of the two values, and matching text gets replaced
# by the empty string.
GAP_doctestfilters = Regex[
    r"BitVector|BitArray\{1\}",
    r"Dict\{Symbol, Any\}|Dict\{Symbol,Any\}",
    r"Dict\{Symbol, Vector\{Int64\}\}|Dict\{Symbol,Array\{Int64,1\}\}",
    r"Dict\{Symbol, Int64\}|Dict\{Symbol,Int64\}",
    r"Matrix\{Int64\}|Array\{Int64,2\}",
    r"StepRange\{Int8, Int8\}|StepRange\{Int8,Int8\}",
    r"Vector\{Any\}|Array\{Any,1\}",
    r"Vector\{Int64\}|Array\{Int64,1\}",
    r"Vector\{UInt8\}|Array\{UInt8,1\}",
]
