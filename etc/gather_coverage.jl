import Pkg
Pkg.add("Coverage")
Pkg.add("JSON")

using Coverage
import JSON

# gather coverage
data = process_folder("src")
data = append!(data, process_folder("pkg"))
data_dict = to_json(data)

# write it to a file for the upload script
println("Writing to julia-coverage.json ...")
write("julia-coverage.json", JSON.json(data_dict))
