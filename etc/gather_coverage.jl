import Pkg
Pkg.add("Coverage")
Pkg.add("JSON")

using Coverage
import JSON

# gather coverage
data = Codecov.process_folder("JuliaInterface")
append!(data, Codecov.process_folder("JuliaExperimental"))
append!(data, Codecov.process_folder("LibGAP.jl"))
data_dict = Codecov.to_json(data)

# write it to a file for the upload script
println("Writing to julia-coverage.json ...")
write("julia-coverage.json", JSON.json(data_dict))
