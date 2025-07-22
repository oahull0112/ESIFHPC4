using PowerSystems
using PowerSimulations
using HydroPowerSimulations
using PowerSystemCaseBuilder
using HiGHS # solver
using Dates
using CSV
using DataFrames
using Logging
using BenchmarkTools

const PSI = PowerSimulations
const PSY = PowerSystems

# Setup benchmark output directory
benchmark_output_dir = joinpath(@__DIR__, "benchmark_results")
mkpath(benchmark_output_dir)
benchmark_name = "RTS_UC"

function create_system()
    return build_system(PSISystems, "modified_RTS_GMLC_DA_sys"; skip_serialization = true)
end

function create_template()
    template_uc = ProblemTemplate()

    set_device_model!(template_uc, Line, StaticBranch)
    set_device_model!(template_uc, Transformer2W, StaticBranch)
    set_device_model!(template_uc, TapTransformer, StaticBranch)

    set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
    set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
    set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
    set_device_model!(template_uc, HydroDispatch, HydroDispatchRunOfRiver)
    set_device_model!(template_uc, RenewableNonDispatch, FixedOutput)
    set_service_model!(template_uc, VariableReserve{ReserveUp}, RangeReserve)
    set_service_model!(template_uc, VariableReserve{ReserveDown}, RangeReserve)
    set_network_model!(template_uc, NetworkModel(CopperPlatePowerModel))
    
    return template_uc
end

function create_problem_model(
    template::PSI.ProblemTemplate, 
    sys::PSY.System, 
    optimizer::PSI.MathOptInterface.OptimizerWithAttributes
)
    problem = DecisionModel(
        template, 
        sys; 
        optimizer = optimizer,
        horizon = Hour(24),
        optimizer_solve_log_print = true
    )
    
    return problem
end

function benchmark_build_and_solve(
    template::PSI.ProblemTemplate, 
    sys::PSY.System, 
    optimizer::PSI.MathOptInterface.OptimizerWithAttributes
)
    # Create a fresh problem for each benchmark run
    fresh_problem = create_problem_model(template, sys, optimizer)
    
    # Create output directory
    output_dir = "RTS_UC-store"
    isdir(output_dir) || mkdir(output_dir)
    
    build!(fresh_problem, output_dir = output_dir)
    solve!(fresh_problem, export_problem_results = false)
    return fresh_problem
end

function analyze_results(problem::PSI.DecisionModel)
    res = OptimizationProblemResults(problem)
    params = read_parameters(res)
    return (results=res, parameters=params)
end

function generate_benchmark_report(
    timing_summary::DataFrame, 
    samples::Int,
    max_time_seconds::Int,
    output_dir::String,
    benchmark_name::String
)
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    
    # Save CSV file
    CSV.write(joinpath(output_dir, "$(benchmark_name)_timing_$(timestamp).csv"), timing_summary)
    
    # Create benchmark summary report
    summary_file = joinpath(output_dir, "$(benchmark_name)_summary_$(timestamp).txt")
    open(summary_file, "w") do io
        println(io, "# PowerSimulations.jl Benchmark Summary")
        println(io, "Run date: $(now())")
        println(io, "")
        println(io, "## System Information")
        println(io, "Julia version: $(VERSION)")
        println(io, "CPU model: $(Sys.cpu_info()[1].model)")
        println(io, "CPU cores: $(Sys.CPU_THREADS)")
        println(io, "Total memory: $(round(Sys.total_memory() / 1024^3, digits=2)) GB")
        println(io, "")
        println(io, "## Benchmark Configuration")
        println(io, "Samples per benchmark: $samples")
        println(io, "Max time per benchmark: $max_time_seconds seconds")
        println(io, "")
        println(io, "## Benchmark Results")
        println(io, "")
        println(io, "### Execution Time (seconds)")
        for row in eachrow(timing_summary)
            println(io, "- $(row.component): $(round(row.time_seconds, digits=4))")
        end
        println(io, "- Total: $(round(sum(timing_summary.time_seconds), digits=4))")
        println(io, "")
        println(io, "### Memory Usage")
        for row in eachrow(timing_summary)
            if row.memory_bytes > 0
                println(io, "- $(row.component): $(round(row.memory_bytes / 1024^2, digits=2)) MB")
            end
        end
        println(io, "")
        println(io, "### Allocations")
        for row in eachrow(timing_summary)
            if row.allocations > 0
                println(io, "- $(row.component): $(row.allocations) allocations")
            end
        end
    end
    
    return (csv_file = joinpath(output_dir, "$(benchmark_name)_timing_$(timestamp).csv"),
            summary_file = summary_file,
            timestamp = timestamp)
end

# Create a wrapper function to benchmark
function run_benchmark(;
    samples = 1,  # Number of samples for all benchmarks
    max_time_seconds = 300  # Maximum time to spend on each benchmark
)
    
    # Benchmark system loading
    @info "Benchmarking system loading..."
    system_load_bench = @benchmark $create_system() samples=samples evals=1 seconds=max_time_seconds 
    system_load_time = minimum(system_load_bench.times) / 1e9
    sys = create_system()  # Get the actual result
    @show sys
    
    # Benchmark template creation
    @info "Benchmarking template creation..."
    template_creation_bench = @benchmark $create_template() samples=samples evals=1 seconds=max_time_seconds
    template_creation_time = minimum(template_creation_bench.times) / 1e9
    
    template_uc = create_template()  # Get the actual result

    # Setup optimizer
    solver = optimizer_with_attributes(
        HiGHS.Optimizer, 
        "mip_rel_gap" => 1.e-4, 
        "log_to_console" => true,
        "output_flag" => true,
    )
    
    # Benchmark model creation
    @info "Benchmarking Problem model creation..."
    model_creation_bench = @benchmark $create_problem_model($template_uc, $sys, $solver) samples=samples evals=1 seconds=max_time_seconds
    model_creation_time = minimum(model_creation_bench.times) / 1e9
    
    problem = create_problem_model(template_uc, sys, solver)  # Get the actual result

    # Benchmark build and solve together
    @info "Benchmarking build and solve phases..."    
    build_solve_bench = @benchmark $benchmark_build_and_solve($template_uc, $sys, $solver) samples=samples evals=1 seconds=max_time_seconds
    build_solve_time = minimum(build_solve_bench.times) / 1e9
    
    # Run build and solve once for the main problem for results analysis
    problem = benchmark_build_and_solve(template_uc, sys, solver)
    
    # Benchmark result analysis
    @info "Benchmarking results analysis..."
    analysis_bench = @benchmark $analyze_results($problem) samples=samples evals=1 seconds=max_time_seconds
    analysis_time = minimum(analysis_bench.times) / 1e9
    analysis_results = analyze_results(problem)
    res = analysis_results.results
    
    # Create timing summary
    timing_summary = DataFrame(
        component = ["System Loading", "Template Creation", 
                   "Model Creation", "Build+Solve", "Result Analysis"],
        time_seconds = [system_load_time, template_creation_time,
                       model_creation_time, build_solve_time, analysis_time],
        memory_bytes = [
            system_load_bench.memory,
            template_creation_bench.memory,
            model_creation_bench.memory,
            build_solve_bench.memory,
            analysis_bench.memory
        ],
        allocations = [
            system_load_bench.allocs,
            template_creation_bench.allocs,
            model_creation_bench.allocs,
            build_solve_bench.allocs,
            analysis_bench.allocs
        ]
    )
    
    # Generate reports
    report_files = generate_benchmark_report(timing_summary, samples, max_time_seconds, 
                                            benchmark_output_dir, benchmark_name)
    
    # Return results
    return Dict(
        "problem" => problem,
        "results" => res,
        "timing" => timing_summary,
        "benchmarks" => Dict(
            "system_load" => system_load_bench,
            "template_creation" => template_creation_bench,
            "model_creation" => model_creation_bench,
            "build_solve" => build_solve_bench,
            "analysis" => analysis_bench
        )
    )
end

# Run the benchmark with default settings
@info "Starting benchmark for RTS_UC"
benchmark_results = run_benchmark()

# Alternative: Run with faster testing (fewer samples)
# benchmark_results = run_benchmark(samples = 1, max_time_seconds = 60)

# Alternative: Run with high accuracy (more samples)
# benchmark_results = run_benchmark(samples = 10, max_time_seconds = 600)

@info "Benchmark completed and saved to $(benchmark_output_dir)"

# Extract problem and results for compatibility
problem = benchmark_results["problem"]
res = benchmark_results["results"]

# Print summary of results
println("\nBenchmark Summary:")
println("=================")
println("Component\t\tTime (s)\tMemory (MB)\tAllocations")
for row in eachrow(benchmark_results["timing"])
    memory_mb = row.memory_bytes > 0 ? round(row.memory_bytes / 1024^2, digits=2) : "N/A"
    allocs = row.allocations > 0 ? string(row.allocations) : "N/A"
    println("$(rpad(row.component, 16))\t$(round(row.time_seconds, digits=4))\t\t$(memory_mb)\t\t$(allocs)")
end
println("$(rpad("Total", 16))\t$(round(sum(benchmark_results["timing"].time_seconds), digits=4))")
println("\nDetailed results saved to: $(benchmark_output_dir)")

# Example usage with different sample counts:
# 
# Quick test run (1 sample per benchmark):
# run_benchmark(samples=1)
#
# Default run (3 samples per benchmark, good balance of accuracy and speed):
# run_benchmark(samples=3)
#
# High accuracy run (10 samples per benchmark):
# run_benchmark(samples=10)
#
# Production run with extended time limit:
# run_benchmark(samples=5, max_time_seconds=600)

