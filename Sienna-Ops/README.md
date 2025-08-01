
# Sienna

## Purpose and Description

- The Sienna framework is an open-source ecosystem for simulation and optimization of modern energy systems. It is designed to model, solve, and analyze scheduling problems and dynamic simulations of quasi-static infrastructure systems.
- Sienna consists of three main modules:
  - **Sienna\Data**: Supports efficient intake and use of energy systems input data, including multiple file formats, time series representations, and unit system conversions.
  - **Sienna\Ops**: Enables simulation of system scheduling, including unit commitment, economic dispatch, automatic generation control, and nonlinear optimal power flow.
  - **Sienna\Dyn**: Simulates power system dynamic responses to perturbations, including phasor simulations, electromagnetic transients, and small-signal stability.
- The framework applies advanced computer science, visualization, applied mathematics, and computational science to create a flexible modeling environment for energy systems.

## Licensing Requirements

Sienna is open-source software. Licensing details for its components can be found on the [Sienna GitHub repository](https://github.com/NREL-Sienna).

## Other Requirements

- Sienna requires Julia as the primary programming language and depends on several Julia packages, including `PowerSimulations.jl` and `PowerSystems.jl`.
- For large-scale simulations, an appropriate optimization solver (e.g., JuMP-compatible solvers) is required.

## How to build

Instructions to build and install Sienna components:

1. Install Julia from [JuliaLang.org](https://julialang.org/).

### Option 1: Use an existing Project.toml file
2. Instantiate the `Project.toml` file in this directory. On 
the terminal, assuming that you are in the same directory as this
README.md, run
   ```shell
   julia --project=.
   ```
   ```julia
   ] instantiate
   ```
   This should install all the packages needed to run the benchmark

### Option 2: Build your own Julia environment

2. Add the required packages using the Julia package manager:
   ```julia
   ] add PowerSimulations PowerSystems HydroPowerSimulations
   ```

3. For the latest development version, use:
   ```julia
   ] add PowerSimulations#main
   ```
4. Add requisite solvers
   ```julia
   ] add HiGHS IPOPT
   ```

5. Run the benchmarks as follows
   ```shell
   julia --threads=auto --project=. small/run_RTS_UC.jl
   julia --threads=auto --project=. small/run_RTS_UC-ED.jl
   julia --project=. small/run_parallel_simulation.jl
   julia --threads=auto --project=. small/run_ACTIVSg200_ED.jl
   julia --threads=auto --project=. medium/run_CATS.jl
   julia --threads=auto --project=. medium/run_EST_UC.jl
   ```

## Run Definitions and Requirements

- Sienna benchmarks should be run on single-node only.
- The benchmarks include:
  - Unit Commitment and Economic Dispatch simulations using `PowerSimulations.jl`.

## How to run

1. Prepare input data files for the simulation, including system configurations and time series data.
2. Use the provided Julia scripts to set up and execute the benchmarks.
3. Example commands for running benchmarks:
   ```julia
   using PowerSystems
   using PowerSimulations
   # Define and run a simulation
   ```

## Run Rules

- Benchmarks should be run on CPU nodes.
- The Benchmarks are single node only.
- GPU-compatible Optimizers that are compatible with Julia JuMP may be exercised on GPU nodes. 

## Benchmark test results to report and files to return

The benchmark creates timing data that can be inspected visually for comparison.
