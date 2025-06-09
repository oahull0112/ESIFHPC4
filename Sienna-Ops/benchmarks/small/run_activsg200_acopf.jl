using PowerSystems
using PowerSimulations
using Logging
using Dates
using Ipopt
using HydroPowerSimulations

import PowerModels

# Constants
const PSI = PowerSimulations
const PSY = PowerSystems

function configure_ED_template(sys, horizon, interval)

    PSY.transform_single_time_series!(sys, horizon, interval)

    # Create a `template`
    template = template_economic_dispatch(network=NetworkModel(ACPPowerModel, use_slacks=true))

    set_device_model!(template, Line, StaticBranchUnbounded)
    set_device_model!(template, TapTransformer, StaticBranchUnbounded)
    set_device_model!(template, MonitoredLine, StaticBranch)
    set_device_model!(template, ThermalStandard, ThermalBasicDispatch)
    set_device_model!(template, RenewableDispatch, RenewableFullDispatch)
    set_device_model!(template, PowerLoad, StaticPowerLoad)
    set_device_model!(template, TwoTerminalHVDCLine, HVDCTwoTerminalLossless)

    return template
end

# Output simulation directory
sim_name = "ill"
sim_folder = mkpath(joinpath(sim_name * "-sim"))

usts_system_path_RT = joinpath(@__DIR__, "input_data", "ACTIVSg200", "sys.json")

sys_RT = PSY.System(usts_system_path_RT; assign_new_uuids = true)

solver_ED = optimizer_with_attributes(
    Ipopt.Optimizer,
    "linear_solver" => "ma27",
    "print_level" => 5,
)

horizon_RT = Dates.Hour(1)
interval_RT = Dates.Hour(1)
template_rt = configure_ED_template(sys_RT, horizon_RT, interval_RT)

models = SimulationModels(
    decision_models=[
        DecisionModel(
            template_rt,
            sys_RT,
            name="RT",
            optimizer=solver_ED,
            optimizer_solve_log_print=true,
            system_to_file=false,
            check_numerical_bounds=false,
            calculate_conflict=true,
            store_variable_names=true,
            resolution = Dates.Hour(1),
            warm_start=false,
        ),
    ]
)

sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(),
    ini_cond_chronology = InterProblemChronology(),
)

steps = 24*7
sim = Simulation(
    name=sim_name * "-test",
    steps=steps,
    models=models,
    sequence=sequence,
    simulation_folder=sim_name * "-sim",
    initial_time=DateTime("2017-08-03T12:00:00"),
)

build!(sim,
    console_level=Logging.Info,
    file_level=Logging.Debug,
    recorders=[:simulation],
)
execute!(sim, enable_progress_bar=false) # Execute the simulation

results = SimulationResults(sim);
ed_results = get_decision_problem_results(results, "RT") # ED stage result metadata

@show ed_results