using PowerSystems
using PowerSimulations
using HydroPowerSimulations
using PowerSystemCaseBuilder
using Ipopt
using Dates
using JuMP
using PowerFlows
using BenchmarkTools  # Add BenchmarkTools
import PowerNetworkMatrices: VirtualPTDF, PTDF
import InfrastructureSystems
import Xpress
import HSL_jll # works only after getting the HSL license and the files for HSL_jll
using HSL # works only after getting the HSL license and the files for HSL_jll (]dev HSL_jll first)

const PSY = PowerSystems
const PSI = PowerSimulations

"""
CATS System Description:
Static Components
┌───────────────────┬───────┐
│ Type              │ Count │
├───────────────────┼───────┤
│ ACBus             │ 8870  │
│ Arc               │ 10574 │
│ Area              │ 1     │
│ FixedAdmittance   │ 75    │
│ HydroDispatch     │ 341   │
│ Line              │ 10162 │
│ LoadZone          │ 1     │
│ PowerLoad         │ 2472  │
│ RenewableDispatch │ 889   │
│ ThermalStandard   │ 1385  │
│ Transformer2W     │ 661   │
└───────────────────┴───────┘
"""

function set_tight_voltage_limits!(system::PSY.System)
    buses = get_components(ACBus, system)
    for b in buses
        if get_bustype(b) ∈ (ACBusTypes.REF, ACBusTypes.PV)
            set_voltage_limits!(b, (min = 0.99, max = 1.01))
            set_magnitude!(b, 1.0)
        end
    end
end

function transform_ts!(system::PSY.System, system_ed::PSY.System)
    transform_single_time_series!(
           system,
           Dates.Hour(HORIZON_UC),  # horizon: 48 hr ahead 
           Dates.Hour(1),   # interval 
       );

    transform_single_time_series!(
        system_ed,
        Dates.Hour(HORIZON_ED),  # horizon: 1 hr ahead
        Dates.Hour(1),  # interval 
    );
end

function setup_uc_problem(
    system::PSY.System,
    ac_pf::Bool,
    ds::Bool,
    q_lim::Bool,
)
    ptdf = VirtualPTDF(system;
        tol = V_PTDF_TOL,
        max_cache_size = 10000,
        )
    network_model_uc = nothing
    if ac_pf
        if ds
            network_model_uc = NetworkModel(
                PTDFPowerModel; 
                power_flow_evaluation=PowerFlows.ACPowerFlow(
                    ;
                    calculate_loss_factors=true, 
                    check_reactive_power_limits=q_lim,
                )
            )
        else
            network_model_uc = NetworkModel(
                PTDFPowerModel; 
                power_flow_evaluation=PowerFlows.ACPowerFlow(
                    ;
                    calculate_loss_factors=true,
                    check_reactive_power_limits=q_lim,
                )
             )
        end
    else
        network_model_uc = NetworkModel(PTDFPowerModel)
    end

    template_uc = ProblemTemplate(network_model_uc)
    set_device_model!(template_uc, ThermalStandard, ThermalBasicUnitCommitment)
    set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
    set_device_model!(template_uc, HydroDispatch, HydroDispatchRunOfRiver)
    set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
    set_device_model!(template_uc, Line, StaticBranch)

    solver_xpress = JuMP.optimizer_with_attributes(
        Xpress.Optimizer,
        "MIPRELSTOP" => 0.2
    )

    problem_uc = DecisionModel(
        template_uc, 
        system; 
        optimizer = solver_xpress, 
        optimizer_solve_log_print = true, 
        name = "UC"
    )

    return problem_uc
end

function setup_ed_problem(system::PSY.System)
    network_model_ed = NetworkModel(
        ACPPowerModel; 
        use_slacks=true, 
    )

    template_ed = ProblemTemplate(network_model_ed)
    set_device_model!(template_ed, ThermalStandard, ThermalBasicDispatch)
    set_device_model!(template_ed, RenewableDispatch, RenewableFullDispatch)
    set_device_model!(template_ed, HydroDispatch, HydroDispatchRunOfRiver)
    set_device_model!(template_ed, PowerLoad, StaticPowerLoad)
    set_device_model!(template_ed, Line, StaticBranchUnbounded)
    set_device_model!(template_ed, Transformer2W, StaticBranchUnbounded)

    solver_ipopt = JuMP.optimizer_with_attributes(
        Ipopt.Optimizer,
        "print_level" => 5,
        "hsllib" => HSL_jll.libhsl_path, # uncomment after getting the HSL license and the files for HSL_jll
        "linear_solver" => "ma97", # uncomment after getting the HSL license and the files for HSL_jll
        "tol" => 1e-6,
        "acceptable_tol" => 1e-3,
        "max_iter" => 500,
    )

    problem_ed = DecisionModel(
        template_ed, 
        system; 
        optimizer = solver_ipopt,
        optimizer_solve_log_print = true, 
        name = "ED"
    )

    return problem_ed
end

function setup_simulation(problem_uc, problem_ed)
    models = SimulationModels(;
        decision_models = [
            problem_uc,
            problem_ed,
        ],
    )

    sequence = SimulationSequence(;
        models = models,
        feedforwards = Dict(
            "ED" => [
                SemiContinuousFeedforward(;
                    component_type = ThermalStandard,
                    source = OnVariable,
                    affected_values = [ActivePowerVariable],
                ),
            ],
        ),
        ini_cond_chronology = InterProblemChronology(),
    )

    simulation_folder = joinpath(@__DIR__, "simulations", "CATS_UC_ED_ACPF")
    isdir(simulation_folder) || mkpath(simulation_folder)
    sim = Simulation(;
        name = "CATS",
        steps = 1,
        models = models,
        sequence = sequence,
        simulation_folder = simulation_folder,
    )

    return sim
end

function build_execute_problem!(problem)
    build_out = build!(problem; output_dir = mktempdir())
    @assert build_out == InfrastructureSystems.Optimization.ModelBuildStatusModule.ModelBuildStatus.BUILT
    solve_out = solve!(problem)
    @assert solve_out == InfrastructureSystems.Simulation.RunStatusModule.RunStatus.SUCCESSFULLY_FINALIZED
end

function build_execute_sim!(sim)
    build_out = build!(sim)
    @assert build_out == PSI.SimulationBuildStatus.BUILT

    exports = Dict(
        "models" => [
            Dict(
                "name" => "UC",
                "store_all_variables" => true,
                "store_all_parameters" => true,
                "store_all_duals" => true,
                "store_all_aux_variables" => true,
            ),
            Dict(
                "name" => "ED",
                "store_all_variables" => true,
                "store_all_parameters" => true,
                "store_all_duals" => true,
                "store_all_aux_variables" => true,
            ),
        ],
        "path" => mktempdir(),
        "optimizer_stats" => true,
    )
    execute_out = execute!(sim; exports = exports, in_memory = true)
    @assert execute_out == PSI.RunStatus.SUCCESSFULLY_FINALIZED

end

function get_uc_ed_results(sim)
    results = SimulationResults(sim);
    uc_results = get_decision_problem_results(results, "UC")
    ed_results = get_decision_problem_results(results, "ED")
    return uc_results, ed_results
end

function benchmark_uc_only(system; samples=1)
    """Benchmark UC-only execution"""
    return @benchmark begin
        problem_uc = setup_uc_problem($system, false, $DIST_SLACK, $Q_LIMITS)
        build_execute_problem!(problem_uc)
        uc_results = OptimizationProblemResults(problem_uc)
        vd = read_variables(uc_results)
        ad = read_aux_variables(uc_results)
    end samples=samples seconds=300  # max 5 minutes per sample
end

function benchmark_uc_ed_simulation(system, system_ed; samples=1)
    """Benchmark full UC+ED simulation"""
    return @benchmark begin
        problem_uc = setup_uc_problem($system, false, $DIST_SLACK, $Q_LIMITS)
        problem_ed = setup_ed_problem($system_ed)
        sim = setup_simulation(problem_uc, problem_ed)
        build_execute_sim!(sim)
        uc_results, ed_results = get_uc_ed_results(sim)
        vd = read_variables(ed_results)
        ad = read_aux_variables(ed_results)
    end samples=samples seconds=300  # max 5 minutes per sample
end

function run_benchmarks(; samples=1)
    """Run all benchmarks and display results"""
    println("="^60)
    println("CATS UC-ED ACPF Benchmarks")
    println("="^60)
    
    # Setup systems (not benchmarked)
    system_path = joinpath(@__DIR__, "input_data", "CATS", "sys.json")
    system = PSY.System(system_path)
    system_ed = deepcopy(system)
    set_tight_voltage_limits!(system_ed)
    transform_ts!(system, system_ed)
    
    if UC_ONLY
        println("\nBenchmarking UC-only execution...")
        uc_benchmark = benchmark_uc_only(system; samples=samples)

        println("\nUC-Only Results:")
        println("─"^40)
        display(uc_benchmark)
        
        # Extract key metrics
        min_time = minimum(uc_benchmark.times) / 1e9  # Convert to seconds
        mean_time = mean(uc_benchmark.times) / 1e9
        memory_mb = uc_benchmark.memory / (1024^2)  # Convert to MB
        allocs = uc_benchmark.allocs
        
        println("\nSummary Metrics:")
        println("  Min time:     $(round(min_time, digits=2)) seconds")
        println("  Mean time:    $(round(mean_time, digits=2)) seconds")
        println("  Memory used:  $(round(memory_mb, digits=2)) MB")
        println("  Allocations:  $(allocs)")
        
    else
        println("\nBenchmarking full UC+ED simulation...")
        full_benchmark = benchmark_uc_ed_simulation(system, system_ed; samples=samples)

        println("\nFull UC+ED Simulation Results:")
        println("─"^40)
        display(full_benchmark)
        
        # Extract key metrics
        min_time = minimum(full_benchmark.times) / 1e9  # Convert to seconds
        mean_time = mean(full_benchmark.times) / 1e9
        memory_mb = full_benchmark.memory / (1024^2)  # Convert to MB
        allocs = full_benchmark.allocs
        
        println("\nSummary Metrics:")
        println("  Min time:     $(round(min_time, digits=2)) seconds")
        println("  Mean time:    $(round(mean_time, digits=2)) seconds")
        println("  Memory used:  $(round(memory_mb, digits=2)) MB")
        println("  Allocations:  $(allocs)")
        
        # Optional: Benchmark individual components
        println("\nBenchmarking individual components...")
        
        # Benchmark UC problem setup
        uc_setup_bench = @benchmark setup_uc_problem($system, false, $DIST_SLACK, $Q_LIMITS) samples=10
        println("\nUC Problem Setup:")
        println("  Time: $(round(minimum(uc_setup_bench.times) / 1e6, digits=2)) ms")
        println("  Memory: $(round(uc_setup_bench.memory / 1024, digits=2)) KB")
        
        # Benchmark ED problem setup
        ed_setup_bench = @benchmark setup_ed_problem($system_ed) samples=10
        println("\nED Problem Setup:")
        println("  Time: $(round(minimum(ed_setup_bench.times) / 1e6, digits=2)) ms")
        println("  Memory: $(round(ed_setup_bench.memory / 1024, digits=2)) KB")
    end
    
    println("\n" * "="^60)
end

##############################

UC_ONLY = true
DIST_SLACK = true
Q_LIMITS = true
V_PTDF_TOL = eps()  # defaults to eps()
V_PTDF_CACHESIZE = 1e5
HORIZON_UC = Hour(6)
HORIZON_ED = Hour(6)

# Run benchmarks instead of direct execution
run_benchmarks()