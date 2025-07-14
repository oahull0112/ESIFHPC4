function create_piecewise_linear_curve(
    a::AbstractFloat,
    b::AbstractFloat,
    c::AbstractFloat,
    min_power::AbstractFloat,
    max_power::AbstractFloat,
    n_segments::Integer)
    # Compute the step size
    step = (max_power - min_power) / n_segments

    # Initialize arrays to store breakpoints and corresponding values
    points = Tuple{Float64, Float64}[]

    # Generate breakpoints and evaluate the function at those points (there will be 1 more point than segments)
    for i in 0:n_segments
        x = min_power + i * step
        push!(points, (x, a*x^2 + b*x + c))
    end

    # Return a function that performs linear interpolation between breakpoints
    return PiecewisePointCurve(points)
end

function quadratic_to_piecewise_linear_sys!(sys::System, n_segments::Int = 2)
    # NOTE: We will do everything in base units

    # Ensure the number of segments is at least 1
    if n_segments < 1
        error("Number of segments must be at least 1")
    end

    th_quadratic_cc = get_components(x -> isa(x.operation_cost.variable, CostCurve{QuadraticCurve}), ThermalGen, sys)
    th_quadratic_fc = get_components(x -> isa(x.operation_cost.variable, FuelCurve{QuadraticCurve}), ThermalGen, sys)

    # # Transform the system to natural units
    # old_units = get_units_base(sys)
    # @show old_units
    # set_units_base_system!(sys, "NATURAL_UNITS")

    # Generation cost curves
    for (idx, th) in enumerate(th_quadratic_cc)
        # Get the operation cost
        op_cost = get_operation_cost(th)
        
        # Get the variable and its value curve
        variable = get_variable(op_cost)
        val_curve = get_value_curve(variable)
        units = get_power_units(variable)
        vom_cost = get_vom_cost(variable)
        
        # Get the quadratic curve parameters
        a = get_quadratic_term(val_curve)
        b = get_proportional_term(val_curve)
        c = get_constant_term(val_curve)
        
        if a == 0.0
            continue
        end
        
        @show idx, th.name, a, b, c
        if units != UnitSystem.DEVICE_BASE
            error("Power units of cost function must be in base units of generator $(th.name)")
        end

        min_power, max_power = get_active_power_limits(th)

        # Create the piecewise linear function
        piecewise_linear_curve = create_piecewise_linear_curve(a, b, c, min_power, max_power, n_segments)

        # Create a new CostCurve with the piecewise linear function
        new_op_cost = ThermalGenerationCost(
            variable = CostCurve(
                value_curve = piecewise_linear_curve,
                power_units = units,
                vom_cost = vom_cost,
            ),
            fixed = get_fixed(op_cost),
            start_up = get_start_up(op_cost),
            shut_down = get_shut_down(op_cost),
        )

        # Set the new operation cost
        set_operation_cost!(th, new_op_cost)
    end

    # Fuel curve
    for th in th_quadratic_fc
        # Get the operation cost
        op_cost = get_operation_cost(th)

        # Get the variable and its value curve
        variable = get_variable(op_cost)
        val_curve = get_value_curve(variable)
        units = get_power_units(variable)
        if units != UnitSystem.DEVICE_BASE
            error("Power units of cost function must be in base units of generator $(th.name)")
        end
        fuel_cost = get_fuel_cost(variable)
        vom_cost = get_vom_cost(variable)

        # Get the quadratic curve parameters
        a = get_quadratic_term(val_curve)
        b = get_proportional_term(val_curve)
        c = get_constant_term(val_curve)

        if a == 0.0
            continue
        end

        min_power, max_power = get_active_power_limits(th)

        # Create the piecewise linear function
        piecewise_linear_curve = create_piecewise_linear_curve(a, b, c, min_power, max_power, n_segments)

        # Create a new CostCurve with the piecewise linear function
        new_op_cost = ThermalGenerationCost(
            variable = FuelCurve(
                value_curve = piecewise_linear_curve,
                power_units = units,
                fuel_cost = fuel_cost,
                vom_cost = vom_cost,
            ),
            fixed = get_fixed(op_cost),
            start_up = get_start_up(op_cost),
            shut_down = get_shut_down(op_cost),
        )

        # Set the new operation cost
        set_operation_cost!(th, new_op_cost)
    end

    # Revert the system to its original units
    # set_units_base_system!(sys, old_units)

    return nothing
end