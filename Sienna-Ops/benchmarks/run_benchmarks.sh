#!/bin/bash
#SBATCH --job-name=sienna
#SBATCH --partition=short
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --output=sienna_benchmarks_%j.out
#SBATCH --error=sienna_benchmarks_%j.err

# Load required modules
module load julia
module load xpressmp

# Set working directory to the benchmarks folder
cd /projects/msoc/kpanda/ESIFHPC4/ESIFHPC4/Sienna-Ops/benchmarks

# Instantiate the Julia environment
echo "Instantiating Julia environment..."
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Attempt to install optional dependencies if available
echo "Attempting to install optional dependencies..."
julia --project=. -e "
using Pkg
optional_packages = [\"HSL_jll\", \"HSL\", \"Xpress\"]
for pkg in optional_packages
    try
        Pkg.add(pkg)
        println(\"✓ Successfully installed \$pkg\")
    catch e
        @warn \"✗ Could not install \$pkg: \$e\"
    end
end
"

# Run the benchmark suite
echo "Starting Sienna benchmarks..."

echo "Running RTS UC benchmark..."
julia --threads=auto --project=. small/run_RTS_UC.jl

echo "Running RTS UC-ED benchmark..."
julia --threads=auto --project=. small/run_RTS_UC-ED.jl

echo "Running parallel simulation benchmark..."
julia --project=. small/run_parallel_simulation.jl

echo "Running ACTIVSg200 ED benchmark..."
julia --threads=auto --project=. small/run_ACTIVSg200_ED.jl

echo "Running CATS benchmark..."
julia --threads=auto --project=. medium/run_CATS.jl

echo "Running EST UC benchmark..."
julia --threads=auto --project=. medium/run_EST_UC.jl

echo "All benchmarks completed!"