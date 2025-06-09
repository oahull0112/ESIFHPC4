using PowerSystems
using PowerSimulations
using HydroPowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder
using Dates
using Xpress
using Ipopt #solver
using HiGHS

import Logging

solver_UC = optimizer_with_attributes(
    HiGHS.Optimizer, 
    "mip_rel_gap" => 0.01, 
    "log_to_console" => true,
    "output_flag" => true,
    "parallel" => "on",
)
solver_ED = optimizer_with_attributes(
    Ipopt.Optimizer,
    "linear_solver" => "ma27",
    "print_level" => 3,
)
sys_DA = build_system(PSISystems, "modified_RTS_GMLC_DA_sys"; skip_serialization = true)
sys_RT = build_system(PSISystems, "modified_RTS_GMLC_RT_sys"; skip_serialization = true)

template_uc = template_unit_commitment(;use_slacks = false)
set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_uc, HydroDispatch, HydroDispatchRunOfRiver)

template_ed = template_economic_dispatch(;
    network = NetworkModel(ACPPowerModel; use_slacks = true),
)
set_device_model!(template_ed, ThermalStandard, ThermalDispatchNoMin)
set_device_model!(template_ed, TwoTerminalHVDCLine, HVDCTwoTerminalLossless)

models = SimulationModels(;
    decision_models = [
        DecisionModel(
            template_uc,
            sys_DA;
            optimizer = solver_UC,
            name = "UC",
            optimizer_solve_log_print = true
        ),
        DecisionModel(template_ed, sys_RT; optimizer = solver_ED, name = "ED",),
    ],
)

feedforward = Dict(
    "ED" => [
        SemiContinuousFeedforward(;
            component_type = ThermalStandard,
            source = OnVariable,
            affected_values = [ActivePowerVariable],
        ),
    ],
)

DA_RT_sequence = SimulationSequence(;
    models = models,
    ini_cond_chronology = InterProblemChronology(),
    feedforwards = feedforward,
)

# Create simulation output directory if it doesn't exist
isdir("RTS-store") || mkdir("RTS-store")

sim = Simulation(;
    name = "rts-test",
    steps = 7,
    models = models,
    sequence = DA_RT_sequence,
    simulation_folder = "RTS-store", # joinpath(".", "rts-store"),
)

build!(
    sim,
    console_level=Logging.Info,
    file_level=Logging.Debug
)
execute!(sim; enable_progress_bar = true)

results = SimulationResults(sim);
uc_results = get_decision_problem_results(results, "UC"); # UC stage result metadata
ed_results = get_decision_problem_results(results, "ED"); # ED stage result metadata


read_variables(uc_results)
read_parameters(uc_results)