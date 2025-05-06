using PowerSystems
using PowerSimulations
using HydroPowerSimulations
using PowerSystemCaseBuilder
using HiGHS # solver
using Dates


sys = build_system(PSISystems, "modified_RTS_GMLC_DA_sys")
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


solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5, "log_to_console" => true)

problem = DecisionModel(template_uc, sys; optimizer = solver, horizon = Hour(24))
build!(problem; output_dir = mktempdir())

@show problem
solve!(problem)

res = OptimizationProblemResults(problem)
# @show res

# get_optimizer_stats(res)