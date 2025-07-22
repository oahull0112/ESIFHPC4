using PowerSimulations

include("partitioned_RTS_UC-ED.jl")

# Get the directory of the current script
script_dir = dirname(@__FILE__)
# Get the relative path to Project.toml (one level up from small/ directory)
project_path = joinpath(script_dir, "..")

output_dir="Parallel_RTS_UC-ED"
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
    num_parallel_processes=51,
    exeflags="--project=$(project_path)",
    force=true,
)