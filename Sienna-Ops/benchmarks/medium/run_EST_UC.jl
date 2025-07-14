using PowerSystems
# using PowerGraphics
using PowerSimulations
using PowerNetworkMatrices
using Dates
using CSV
using HydroPowerSimulations
using DataFrames
using Logging
using TimeSeries
using StorageSystemsSimulations
using HiGHS #solver

using Xpress
#using PowerGrap

const PSY = PowerSystems

include(joinpath(@__DIR__, "utils.jl"))

system_path = joinpath(@__DIR__, "input_data", "extreme_solar_texas", "final_sys_DA.json")
sys_DA = PSY.System(system_path)

# Convert generator costs from quadratic to piecewise linear
quadratic_to_piecewise_linear_sys!(sys_DA, 2)

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
                                                             
# set_device_model!(template_uc, AreaInterchange, StaticBranch)

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

# set_service_model!(template_uc, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
# set_service_model!(template_uc, ServiceModel(VariableReserve{ReserveDown}, RangeReserve))

mip_gap = 0.1

# optimizer = optimizer_with_attributes(
#     Xpress.Optimizer,
#     "MIPRELSTOP" => mip_gap
# )

optimizer = optimizer_with_attributes(
    HiGHS.Optimizer, 
    "mip_rel_gap" => mip_gap, 
    "log_to_console" => true,
    "output_flag" => true,
    "parallel" => "on",
)

initial_date = "2018-03-15"
start_time = DateTime(string(initial_date,"T00:00:00"))
model = DecisionModel(
    template_uc, sys_DA; 
    name = "UC", 
    optimizer = optimizer, 
    horizon = Hour(24), 
    calculate_conflict = true,
    optimizer_solve_log_print = true
)
models = SimulationModels(; decision_models = [model])

steps_sim = 2
current_date = string( today() )
sequence = SimulationSequence(
    models = models,
    # ini_cond_chronology = InterProblemChronology(),
)

output_dir = "EST"
isdir(output_dir) || mkdir(output_dir)

sim = Simulation(
    name = current_date * "_DR-test" * "_" * string(steps_sim)* "steps",
    steps = steps_sim,
    models = models,
    initial_time = DateTime(string(initial_date,"T00:00:00")),
    sequence = sequence,
    simulation_folder = output_dir,
)

build!(sim)

execute!(sim)

############################# RESULTS############################
results = SimulationResults(sim)
uc = get_decision_problem_results(results, "UC")

vre_power =read_realized_variable(uc, "ActivePowerVariable__RenewableDispatch")
thermal_power = read_realized_variable(uc, "ActivePowerVariable__ThermalMultiStart")
thermals_power = read_realized_variable(uc, "ActivePowerVariable__ThermalStandard")

solar = get_component(RenewableDispatch, sys_DA, "Angelina Solar")
ts = get_time_series_array(Deterministic, solar, "max_active_power")

# CSV.write("VRE_Power_Sim.csv", vre_power)
# CSV.write("ThermalMulitStart_Power_Sim.csv", thermal_power)


# lmp = read_realized_duals(uc)
# uc_LMP_data = lmp["AreaParticipationAssignmentConstraint__ACBus"]

# CSV.write("area_lmp.csv", uc_LMP_data)

# plot_dataframe(vre_power)