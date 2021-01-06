# Define some replacements which are applied in `docs/make.jl` and `test/testmanual.jl`.
GAP_doctestfilters = Regex[
    r"BitVector|BitArray\{1\}",
    r"Dict\{Symbol,Any\}|Dict\{Symbol, Any\}",
    r"Dict\{Symbol,Array\{Int64,1\}\}|Dict\{Symbol, Vector\{Int64\}\}",
    r"Dict\{Symbol,Int64\}|Dict\{Symbol, Int64\}",
    r"Matrix\{Int64\}|Array\{Int64,2\}",
    r"StepRange\{Int8,Int8\}|StepRange\{Int8, Int8\}",
    r"Vector\{Any\}|Array\{Any,1\}",
    r"Vector\{Int64\}|Array\{Int64,1\}",
    r"Vector\{UInt8\}|Array\{UInt8,1\}",
]
