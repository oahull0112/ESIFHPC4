using PowerSystems
using PowerSimulations
# using PowerNetworkMatrices
using Dates
using CSV
using HydroPowerSimulations
using DataFrames
using Logging
using TimeSeries
using StorageSystemsSimulations
using HiGHS #solver
using BenchmarkTools
# using Statistics

include(joinpath(@__DIR__, "utils.jl"))

const PSI = PowerSimulations
const PSY = PowerSystems

# Setup benchmark output directory
benchmark_output_dir = joinpath(@__DIR__, "benchmark_results")
mkpath(benchmark_output_dir)
benchmark_name = "EST_UC"

function create_template()
    template_uc = template_unit_commitment(;
    network = NetworkModel(AreaBalancePowerModel; use_slacks = true))
    set_device_model!(template_uc, HydroDispatch, HydroDispatchRunOfRiver)
    set_device_model!(template_uc, ThermalStandard, ThermalBasicUnitCommitment)
    set_device_model!(template_uc, ThermalMultiStart, ThermalBasicUnitCommitment)
    set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch,) 
    set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
    set_device_model!(template_uc, DeviceModel(Line, 
                                            StaticBranch;
                                            use_slacks =true))

    set_device_model!(template_uc, DeviceModel(Transformer2W, 
                                            StaticBranch;
                                            use_slacks =true))  
                                                                
    storage_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict(
            "reservation" => true,
            "energy_target" => false,
            "cycling_limits" => false,
            "regularization" => true,
        ),
    )
    set_device_model!(template_uc, storage_model)
    
    return template_uc
end

function create_simulation_model(
    template::PSI.ProblemTemplate, 
    sys::PSY.System, 
    optimizer::PSI.MathOptInterface.OptimizerWithAttributes
)
    model = DecisionModel(
        template, sys; 
        name = "UC", 
        optimizer = optimizer, 
        horizon = Hour(24), 
        calculate_conflict = true,
        optimizer_solve_log_print = true
    )
    models = SimulationModels(; decision_models = [model])

    steps_sim = 1
    current_date = string(today())
    sequence = SimulationSequence(
        models = models,
    )

    output_dir = "EST"
    isdir(output_dir) || mkdir(output_dir)

    initial_date = "2018-03-15"


    sim = Simulation(
        name = current_date * "_DR-test" * "_" * string(steps_sim)* "steps",
        steps = steps_sim,
        models = models,
        initial_time = DateTime(string(initial_date,"T00:00:00")),
        sequence = sequence,
        simulation_folder = output_dir,
    )
    
    return sim
end

function benchmark_build_and_execute(
    template::PSI.ProblemTemplate, 
    sys::PSY.System, 
    optimizer::PSI.MathOptInterface.OptimizerWithAttributes
)
    # Create a fresh simulation for each benchmark run
    fresh_sim = create_simulation_model(template, sys, optimizer)
    build!(fresh_sim)
    execute!(fresh_sim)
    return fresh_sim
end

function analyze_results(s::PSI.Simulation, sys::PSY.System)
    results = SimulationResults(s)
    uc = get_decision_problem_results(results, "UC")
    
    vre_power = read_realized_variable(uc, "ActivePowerVariable__RenewableDispatch")
    thermal_power = read_realized_variable(uc, "ActivePowerVariable__ThermalMultiStart")
    thermals_power = read_realized_variable(uc, "ActivePowerVariable__ThermalStandard")
    
    solar = get_component(RenewableDispatch, sys, "Angelina Solar")
    ts = get_time_series_array(Deterministic, solar, "max_active_power")
    
    return (results=results, uc=uc, vre_power=vre_power, thermal_power=thermal_power)
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
    # Setup path
    system_path = joinpath(@__DIR__, "input_data", "extreme_solar_texas", "final_sys_DA.json")
    
    # Benchmark system loading
    @info "Benchmarking system loading..."
    load_system_func() = PSY.System(system_path)
    system_load_bench = @benchmark $load_system_func() samples=samples evals=1 seconds=max_time_seconds 
    system_load_time = minimum(system_load_bench.times) / 1e9
    sys_DA = load_system_func()  # Get the actual result
    
    # Benchmark cost conversion
    @info "Benchmarking cost conversion..."
    cost_conversion_func(sys) = quadratic_to_piecewise_linear_sys!(sys, 2)
    cost_conversion_bench = @benchmark $cost_conversion_func($sys_DA) samples=samples evals=1 seconds=max_time_seconds
    cost_conversion_time = minimum(cost_conversion_bench.times) / 1e9
    
    # Benchmark template creation
    @info "Benchmarking template creation..."
    template_creation_bench = @benchmark $create_template() samples=samples evals=1 seconds=max_time_seconds
    template_creation_time = minimum(template_creation_bench.times) / 1e9
    
    template_uc = create_template()  # Get the actual result

    # Setup optimizer and dates
    mip_gap = 0.01
    optimizer = optimizer_with_attributes(
        HiGHS.Optimizer, 
        "mip_rel_gap" => mip_gap, 
        "log_to_console" => true,
        "output_flag" => true,
        "parallel" => "on",
    )
    
    # Benchmark model creation
    @info "Benchmarking Simulation model creation..."
    model_creation_bench = @benchmark $create_simulation_model($template_uc, $sys_DA, $optimizer) samples=samples evals=1 seconds=max_time_seconds
    model_creation_time = minimum(model_creation_bench.times) / 1e9
    
    
    sim = create_simulation_model(template_uc, sys_DA, optimizer)  # Get the actual result

    # Benchmark build and execute together
    @info "Benchmarking build and execute phases..."    
    build_execute_bench = @benchmark $benchmark_build_and_execute($template_uc, $sys_DA, $optimizer) samples=samples evals=1 seconds=max_time_seconds
    build_execute_time = minimum(build_execute_bench.times) / 1e9
    
    # Run build and execute once for the main simulation for results analysis
    sim = benchmark_build_and_execute(template_uc, sys_DA, optimizer)
    
    # Benchmark result analysis
    @info "Benchmarking results analysis..."

    
    analysis_bench = @benchmark $analyze_results($sim, $sys_DA) samples=samples evals=1 seconds=max_time_seconds
    analysis_time = minimum(analysis_bench.times) / 1e9
    analysis_results = analyze_results(sim, sys_DA)
    results = analysis_results.results
    
    # Create timing summary
    timing_summary = DataFrame(
        component = ["System Loading", "Cost Conversion", "Template Creation", 
                   "Model Creation", "Build+Execute", "Result Analysis"],
        time_seconds = [system_load_time, cost_conversion_time, template_creation_time,
                       model_creation_time, build_execute_time, analysis_time],
        memory_bytes = [
            system_load_bench.memory,
            cost_conversion_bench.memory,
            template_creation_bench.memory,
            model_creation_bench.memory,
            build_execute_bench.memory,
            analysis_bench.memory
        ],
        allocations = [
            system_load_bench.allocs,
            cost_conversion_bench.allocs,
            template_creation_bench.allocs,
            model_creation_bench.allocs,
            build_execute_bench.allocs,
            analysis_bench.allocs
        ]
    )
    
    # Generate reports
    report_files = generate_benchmark_report(timing_summary, samples, max_time_seconds, 
                                            benchmark_output_dir, benchmark_name)
    
    # Return results
    return Dict(
        "sim" => sim,
        "results" => results,
        "timing" => timing_summary,
        "benchmarks" => Dict(
            "system_load" => system_load_bench,
            "cost_conversion" => cost_conversion_bench,
            "template_creation" => template_creation_bench,
            "model_creation" => model_creation_bench,
            "build_execute" => build_execute_bench,
            "analysis" => analysis_bench
        )
    )
end

# Run the benchmark with default settings
@info "Starting benchmark for EST_UC"
benchmark_results = run_benchmark()

# Alternative: Run with faster testing (fewer samples)
# benchmark_results = run_benchmark(samples = 1, max_time_seconds = 60)

# Alternative: Run with high accuracy (more samples)
# benchmark_results = run_benchmark(samples = 10, max_time_seconds = 600)

@info "Benchmark completed and saved to $(benchmark_output_dir)"

# Extract sim and results for compatibility
sim = benchmark_results["sim"]
results = benchmark_results["results"]

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