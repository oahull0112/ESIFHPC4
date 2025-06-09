using PowerSystems
using PowerSimulations
using HydroPowerSimulations
using PowerSystemCaseBuilder
using HiGHS # solver
using Dates

sys = build_system(PSISystems, "modified_RTS_GMLC_DA_sys"; skip_serialization = true)
@show sys

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

solver = optimizer_with_attributes(
    HiGHS.Optimizer, 
    "mip_rel_gap" => 1.e-4, 
    "log_to_console" => true,
    "output_flag" => true,
)

problem = DecisionModel(
    template_uc, 
    sys; 
    optimizer = solver,
    horizon = Hour(24),
    optimizer_solve_log_print=true
)

isdir("RTS-store") || mkdir("RTS-store")

build!(problem, output_dir = "RTS_UC-store")

solve!(
    problem,
    export_problem_results = false,
)

res = OptimizationProblemResults(problem)

read_parameters(res)

