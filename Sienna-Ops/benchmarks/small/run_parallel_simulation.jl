# filepath: /Users/kpanda/UserApps/HPCApps/ESIFHPC4/Sienna-Ops/benchmarks/small/configure_parallel_simulation_no_torc.jl
using PowerSimulations

include("partitioned_RTS_UC-ED.jl")

# Get the directory of the current script
script_dir = dirname(@__FILE__)
# Get the relative path to Project.toml (one level up from small/ directory)
project_path = joinpath(script_dir, "..")

output_dir="RTS_UC-ED2"
# Delete and recreate output directory if it exists
if isdir(output_dir)
    rm(output_dir, recursive=true)
end
mkdir(output_dir)

run_parallel_simulation(
    build_simulation,
    execute_simulation,
    script="partitioned_RTS_UC-ED.jl",
    output_dir=output_dir,
    name="RTS",
    num_steps=365,
    period=7,
    num_overlap_steps=1,
    num_parallel_processes=50,
    exeflags="--project=$(project_path)",
    force=true,
)