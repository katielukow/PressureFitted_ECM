module PIECM

using CSV, DataFrames, Dates, Infiltrator, JLD2, Interpolations, XLSX, Statistics, DataStructures, Optim, PlotlyJS, Evolutionary
using StatsBase: sqL2dist, rmsd
 
export data_import_csv, data_import_excel, pressure_dateformat_fix, pressurematch, hppc_pulse, pocv, sqrzeros, HPPC, hppc_fun, hppc_calc, ecm_err_range,rmins, pres_contour, soc_loop_2RC
export ecm_discrete, costfunction, HPPC_n, data_imp, pres_avg, Capacity_Fade, ecm_fit, soc_loop, incorrect_pres, soc_range, soc_range_2RC, ecm_err_range_2RC

# --------------- Fitting data import and filtering -----------------------------

sqrzeros(A) = zeros(A,A)

function data_import_csv(file_name, format) 
	df = CSV.read(file_name, DataFrame)
	if format == "new"
		rename!(df,"Step Index" => "Step_Index")
		rename!(df,"Test Time (s)" => "Test_Time(s)")
		rename!(df,"Step Time (s)" => "Step_Time(s)")
		rename!(df,"Date Time" => "Date_Time")
		rename!(df,"Cycle Index" => "Cycle_Index")
		rename!(df,"Voltage (V)" => "Voltage(V)")
		rename!(df,"Current (A)" => "Current(A)")
		rename!(df,"Internal Resistance (Ohm)" => "Internal_Resistance(Ohm)")
		rename!(df,"Discharge Capacity (Ah)" => "Discharge_Capacity(Ah)")
		rename!(df,"Discharge Energy (Wh)" => "Discharge_Energy(Wh)")
		rename!(df,"Charge Capacity (Ah)" => "Charge_Capacity(Ah)")
		rename!(df,"Aux_Temperature_1 (C)" => "Aux_Temperature_1(C)")
	end

	return df
end
data_import_excel(file_name, sheet_name) = DataFrame(XLSX.readtable(file_name, sheet_name))

# Imports pressure data as a DataFrame and matches date format to yyyy/mm/dd HH:MM:SS
function pressure_dateformat_fix(file_name)
    data = CSV.read(file_name, DataFrame)
    data.Time = Dates.format.(data.Time, "HH:MM:SS")
    data.Date = Date.(data.Date, "dd/mm/yyyy")
    data.Date = Dates.format.(data.Date, "yyyy/mm/dd")
    data.Date_Time = data.Date .* " " .* data.Time
    return data
end

# Convert force to pressure and match date-time 
function pressurematch(cell_data, pressure_data, A_cell)
    pressure_data.Pressure = pressure_data.Force ./ A_cell # Convert force to pressure (Pa)
	return leftjoin(cell_data, pressure_data, on = :Date_Time)
end

function data_imp(hppc_file, pres_file, Acell)
    
    cd = data_import_csv(hppc_file, "new")
    A_cell = Acell[1] * Acell[2]
    pd = pressure_dateformat_fix(pres_file)
    data = pressurematch(cd, pd, A_cell)
    
    return sort!(data,["Date_Time"])

end

function pres_avg(pres_file, data, Area, digits)
    p = pressure_dateformat_fix(pres_file)
    return round(mean(filter(!ismissing, pressurematch(data, p, Area[1] * Area[2])[:,"Pressure"]))/1000, digits=digits)
end


function pocv(file_name, POCV_discharge_step, POCV_charge_step, OCV_steps)
	df = data_import_csv(file_name, "old")

	POCVc = Array{Float64}(undef,(OCV_steps+1),2)
	POCVd = Array{Float64}(undef,(OCV_steps+1),3)
		
	# Select relavent data
	dis = select(filter(row -> row."Step_Index" == POCV_discharge_step, df), "Voltage(V)", "Discharge_Capacity(Ah)", "Discharge_Energy(Wh)")
	char = select(filter(row -> row."Step_Index" == POCV_charge_step, df), "Voltage(V)", "Charge_Capacity(Ah)", "Charge_Energy(Wh)")

	# Normalize capacities 
	dis[:,"Discharge_Capacity(Ah)"] .-= dis[1,"Discharge_Capacity(Ah)"]
	dis[:,"Discharge_Energy(Wh)"] .-= dis[1,"Discharge_Energy(Wh)"]
	char[:,"Charge_Capacity(Ah)"] .-= char[1,"Charge_Capacity(Ah)"]

	# Calculate and append SOC to the relavent dataframe
	dis[!, "SOC"] = 100 .- dis[:,"Discharge_Capacity(Ah)"] ./ dis[end,"Discharge_Capacity(Ah)"] .* 100
	char[!, "SOC"] = char[:,"Charge_Capacity(Ah)"] ./ char[end,"Charge_Capacity(Ah)"] .* 100

	# Select normalized data points for usable SOC table
	j = 1
	for i in 0:(100 / OCV_steps):100 # iterating through SOC points
		min_c = findmin(abs.(char[:,"SOC"] .- i))
		POCVc[j,1] = round(char[!, "SOC"][min_c[2]],digits=1)
		POCVc[j,2] = char[min_c[2],"Voltage(V)"]

		min_d = findmin(abs.(dis[:,"SOC"] .- i))
		POCVd[j,1] = round(dis[!, "SOC"][min_d[2]],digits=1)
		POCVd[j,2] = dis[min_d[2],"Voltage(V)"]
		POCVd[j,3] = dis[min_d[2],"Discharge_Energy(Wh)"]

		j += 1
	end

	# Find average between charge and discharge curves
	POCV_SOC = ((POCVd[:,1] .+ POCVc[:,1]) ./ 2) ./ 100
	POCV_V = (POCVd[:,2] .+ POCVc[:,2]) ./ 2

	# @infiltrate cond=true


	return DataFrame(State_of_Charge=POCV_SOC, Voltage=POCV_V,DischargeVoltage=POCVd[:,2],ChargeVoltage=POCVc[:,2],DischargeEnergy=POCVd[:,3])
end

function hppc_pulse(data, soc, soc_increment, pulse_rate, dis_pulse_step, char_pulse_step)
	
    df = filter(row -> row."TC_Counter1" == round(((100 - soc) / soc_increment)), data)
	# df = filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1) || row."Step_Index" == (dis_pulse_step-1), df)
	
	d = filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1) || row."Step_Index" == (dis_pulse_step-1), df)
	return d[4:end,:]
end

function hppc_pulse(data, soc::Vector, soc_increment, pulse_rate, dis_pulse_step, char_pulse_step)
	
    df = filter(row -> row."TC_Counter1" == ((100 - soc[1]) / soc_increment) || row."TC_Counter1" == ((100 - soc[2]) / soc_increment), data)
	# df = filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1) || row."Step_Index" == (dis_pulse_step-1), df)
	
	d = filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1) || row."Step_Index" == (dis_pulse_step-1) || row."Step_Index" == (char_pulse_step+2) || row."Step_Index" == (char_pulse_step+3), df)
	return d[5:end,:]
end

function HPPC(data, soc_increment, cycle, dis_pulse_step, char_pulse_step, dis_step, initial_cap_step, DCIR_step)

    γ = Dict()

	initial_capacity = filter(row -> row."Step_Index" == initial_cap_step, data)[end,"Discharge_Capacity(Ah)"]

	DCIR = unique(select(filter(row -> row."Step_Index" == DCIR_step, data), "Internal_Resistance(Ohm)"))

	soc_steps = 100 ÷ soc_increment #length(collect(0:soc_increment:100))-1
	# SOC = Array{Float64}(undef, soc_steps, 1)
	SOC = zeros(soc_steps,1)
	∇_discharge = DataFrame([[], [], [], [], [], [], [], [], []], ["SOC","Start Voltage(V)","End Voltage(V)", "Resistance", "Average Power (W)", "Max Power (W)", "Min Power (W)", "Max Current(A)", "Min Current(A)"])	
	∇_charge = DataFrame([[], [], [], [], [], [], [], [], []], ["SOC","Start Voltage(V)","End Voltage(V)", "Resistance", "Average Power (W)", "Max Power (W)", "Min Power (W)", "Max Current(A)", "Min Current(A)"])

	dpulse_v = filter(row -> row."Step_Index" == (dis_pulse_step-1) && row."Cycle_Index" == cycle, data)
	cpulse_v = filter(row -> row."Step_Index" == (char_pulse_step-1) && row."Cycle_Index" == cycle, data)
	df_dpulse = filter(row -> row."Step_Index" == dis_pulse_step && row."Cycle_Index" == cycle, data) 
	df_cpulse = filter(row -> row."Step_Index" == char_pulse_step && row."Cycle_Index" == cycle, data)
	df_discharge = filter(row -> row."Step_Index" == dis_step && row."Cycle_Index" == cycle, data)

	# Calculate State of Charge based on capacities - Discharge to next step + discharge pulse - charge pulse
	# for g in 0:(soc_steps-1) 0:findmax(df_discharge[:,"TC_Counter1"])


	for g in 1:(soc_steps-1)
		o = filter(row -> row."TC_Counter1" == g, df_discharge)
		dis_step_cap = o[end, "Discharge_Capacity(Ah)"] - o[1, "Discharge_Capacity(Ah)"]
		k = filter(row -> row."TC_Counter1" == g, df_dpulse)
		pulse_cap_d = k[end, "Discharge_Capacity(Ah)"] - k[1, "Discharge_Capacity(Ah)"]
		p = filter(row -> row."TC_Counter1" == g, df_cpulse)
		pulse_cap_c = p[end, "Charge_Capacity(Ah)"] - p[1, "Charge_Capacity(Ah)"]

		SOC[g+1] = dis_step_cap + pulse_cap_d - pulse_cap_c
	end

	# print(SOC)
	SOC = cumsum(SOC[:,1])
	SOC = 100 .- SOC ./ initial_capacity .* 100

	# Calculate relevant data for each SOC point
	for j in 1:(soc_steps)
		dpulse_vi = filter(row -> row."TC_Counter1" == j-1, dpulse_v)[end,"Voltage(V)"]
		discharge = hppc_calc(df_dpulse, j, dpulse_vi)
		push!(∇_discharge, [SOC[j], dpulse_vi, filter(row -> row."TC_Counter1" == j-1, df_dpulse)[end,"Voltage(V)"],  discharge[1], discharge[2], discharge[3], discharge[4], discharge[5], discharge[6]])
	end

	for q in 1:(soc_steps)
		cpulse_vi = filter(row -> row."TC_Counter1" == q-1, cpulse_v)[end,"Voltage(V)"]
		charge = hppc_calc(df_cpulse, q, cpulse_vi)
		push!(∇_charge, [SOC[q], cpulse_vi, filter(row -> row."TC_Counter1" == q-1, df_cpulse)[end,"Voltage(V)"], charge[1], charge[2], charge[3], charge[4], charge[5], charge[6]])
	end

	γ = Dict("Charge" => ∇_charge, "Discharge" => ∇_discharge)

	return γ
end

function hppc_calc(df, i, init_V)
	# df = filter(row -> row."TC_Counter1" == (i), dataframe)

	# r = abs((init_V - df[end,"Voltage(V)"]) / abs(mean(df[:,"Current(A)"])))
	# P = df[:,"Voltage(V)"] .* df[:,"Current(A)"]
	# P_min = findmin(abs.(P))[1]
	# P_max = findmax(abs.(P))[1]
	# P_avg = mean(P)
	# I_min = findmin(abs.(df[:,"Current(A)"]))[1]
	# I_max = findmax(abs.(df[:,"Current(A)"]))[1]

	# t = [P_max P_min I_max I_min]

	# if df[1, "Current(A)"] < 0
	# 	t .= -t
	# end

	# return [r, P_avg, t[1], t[2], t[3], t[4]]
	Ineg = filter(row -> row."Current(A)" < 0, df)
	return abs((init_V - minimum(df[:,"Voltage(V)"])) / abs(mean(Ineg[:,"Current(A)"])))
end

function Capacity_Fade(df, d_stepinit, d_step)
	SOH = Array{Float64}(undef, 6, 4)
	
	discharge = filter(row -> row.Step_Index == d_step, df)
	capinit = filter(row -> row.Step_Index == d_stepinit, df)[end, "Discharge_Capacity(Ah)"] - filter(row -> row.Step_Index == d_stepinit, df)[1, "Discharge_Capacity(Ah)"]
	energyinit = filter(row -> row.Step_Index == d_stepinit, df)[end, "Discharge_Energy(Wh)"] - filter(row -> row.Step_Index == d_stepinit, df)[1, "Discharge_Energy(Wh)"]
	# presinit = mean(skipmissing(filter(row -> row.Step_Index == d_stepinit, df)[:, "Pressure"]))
	presinit = filter(row -> row.Step_Index == d_stepinit, df)[1, "Pressure"]
	SOH[1,:] = [0.0,100.0, energyinit, presinit]
	j = 1

	for i in 21:20:101
		Qtemp = filter(row -> row.Cycle_Index == i, discharge)[end, "Discharge_Capacity(Ah)"] - filter(row -> row.Cycle_Index == i, discharge)[1, "Discharge_Capacity(Ah)"]
		Etemp = filter(row -> row.Cycle_Index == i, discharge)[end, "Discharge_Energy(Wh)"] - filter(row -> row.Cycle_Index == i, discharge)[1, "Discharge_Energy(Wh)"]
		# Ptemp = mean(skipmissing(filter(row -> row.Cycle_Index == i, discharge)[:, "Pressure"]))
		Ptemp = filter(row -> row.Cycle_Index == i, discharge)[1, "Pressure"]
		SOH[j+1,:] = [i, Qtemp / capinit * 100, Etemp, Ptemp]
		j += 1
	end

	return SOH
end

function hppc_fun(pd, soc, soc_step, pulse_rate, dis_step, char_step, cycle_index)
    
    hppc = hppc_pulse(pd, soc, soc_step, pulse_rate, dis_step, char_step)
    hppc = filter(row -> row."Cycle_Index" == cycle_index, hppc)
    hppc."Test_Time(s)" .-= hppc."Test_Time(s)"[1]

    return sort!(hppc,"Date_Time")
end
# ----------------------------------
# x = [Rᵢ, Cᵢ, R₀]
# n_RC = number of RC pairs
# uᵢ = current vector input for prediction [A]
# Δ = timestep [s]
# η = coloumbic efficiency 
# Q = capacity [Ah]

# Static time step forward model
function ecm_discrete(x, n_RC, uᵢ, Δ :: Float64, eta, Q, OCV, Init_SOC)
    
	interp_linear = linear_interpolation(OCV."State_of_Charge", OCV."Voltage") # Interpolation function for OCV based on capacity change
	
	# # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)

    z = Array{Float64}(undef, length(uᵢ))
    iᵣ = Array{Float64}(undef, length(uᵢ))
    v = Array{Float64}(undef, length(uᵢ))

    uᵢ = uᵢ .* -1 # Changes charge / discharge convention to match Plett ISBN:978-1-63081-023-8

	# Initial Values
    z[1] = Init_SOC
	if iᵣ[1] < 0
		η = 1
		z[2] = z[1] - (η*((Δ)/3600) / Q) * uᵢ[1]
	else
	end
	v[1] = interp_linear(Init_SOC)
    v[1] = interp_linear(Init_SOC)
    iᵣ[1]=0 # can this be a proper term?

	# for α in 1:n_RC
    #     F = exp(-Δ/(x[1]*x[2]))
    #     A_RC[α,α] = F
    #     B_RC[α] = (1-F)
    # end

	for k in eachindex(uᵢ)
		if i == 1
			continue
		end
		A_RC = exp(-(Δ)/(x[1]*x[2]))
        B_RC = 1 - exp(-(Δ)/(x[1]*x[2]))
        z[k+1] = z[k] - (η*((Δ)/3600) / Q) * uᵢ[k]
		iᵣ[k+1] = - A_RC * iᵣ[k] - B_RC * uᵢ[k] # solve matrix dimensionality issues for multiple RC pairs
		v[k] = interp_linear(z[k]) - (x[1] * iᵣ[k]) - (x[3] * uᵢ[k])
    end

    # v[end] = v[end-1]

    return v

end

function ecm_discrete(x, n_RC, uᵢ, Δ ::Vector , eta, Q, OCV, Init_V)
        
	interp_linear_init = linear_interpolation(OCV."Voltage", OCV."State_of_Charge") # Interpolation function for OCV based on capacity change
	interp_linear = linear_interpolation(OCV."State_of_Charge", OCV."Voltage")

	# # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)

	num_points = length(uᵢ)
    z = zeros(num_points)
    v = zeros(num_points)
    τ = diff([0; Δ]) # Calculate τ directly
	τ[1] = 0 

	uᵢ = -uᵢ # Changes charge / discharge convention to match Plett ISBN:978-1-63081-023-8

	# Initial Values
    v[1] = Init_V

	if Init_V > OCV."Voltage"[end]
		z[1] = 1
	else
		z[1] = interp_linear_init(Init_V)
	end

    iᵣ = zeros(num_points,n_RC)


    # for k in 1:length(uᵢ)-1
	for k in eachindex(uᵢ)
		if k == length(uᵢ)
			continue
		end
		
		if uᵢ[k] > 0
			η = 1
		else
			η = 0.999
		end

		for α in 1:n_RC
			F = exp(-τ[k]/(x[α]*x[(n_RC+α)]))
			A_RC[α,α] = F
			B_RC[α] = (1-F)
		end

        z[k+1] = z[k] - (η*((τ[k])/3600) / Q) * uᵢ[k]
		iᵣ[k+1,:] = (A_RC * iᵣ[k,:] + B_RC * uᵢ[k])

		v[k] = interp_linear(z[k]) -  sum(x[1:n_RC] .* iᵣ[k,:]') - (x[end] * uᵢ[k]) 

    end

	v[end] = v[end-1]
    
	return v

end

x_1RC = [0.01, 1000, 0.01]
x_2RC = [0.01, 0.01, 10000, 10000, 0.01]

function costfunction(x, n_RC, uᵢ, Δ, η, Q, OCV, Init_SOC, data)
	if n_RC == 1
		x = x .* x_1RC
	else n_RC == 2
		x = x .* x_2RC
	end
	v = ecm_discrete(x, n_RC, uᵢ, Δ, η, Q, OCV, Init_SOC)
	return sqL2dist(v,data[:,"Voltage(V)"]) 
end

function ecm_fit(data, capacity, open_circuit_voltage, state_of_charge, init_params, num_RC)
    current = data."Current(A)"
    time = data."Test_Time(s)"
	efficiency = 0.999

    costfunction_closed = κ->costfunction(κ, num_RC, current, time, efficiency, capacity, open_circuit_voltage, data[1, "Voltage(V)"], data)
    # result = Evolutionary.optimize(costfunction_closed, init_params, CMAES(sigma0=.1))
	lower_bounds = zeros(length(init_params)) .+ 0.0001
	upper_bounds = zeros(length(init_params)) .+ 10
	inner_optimiser = LBFGS()
	optimiser = Fminbox(inner_optimiser)

	result = Optim.optimize(costfunction_closed, lower_bounds, upper_bounds, init_params, optimiser, Optim.Options(iterations=1000));
	if num_RC == 1
		params = result.minimizer .* x_1RC
	else num_RC == 2
		params = result.minimizer .* x_2RC
	end
	# params = result.minimizer .* [0.01, 1000, 0.01]
    voltage = ecm_discrete(params, num_RC, data."Current(A)", data."Test_Time(s)", efficiency, capacity, open_circuit_voltage, data[1, "Voltage(V)"])
    return voltage, params, result
end

function soc_loop(data, max_soc, min_soc, capacity, open_circuit_voltage, discharge_step, charge_step, soc_step)
    # print("-------------- \n")
    voltages = OrderedDict()
    all_params = DataFrame([[],[],[],[],[]], ["SOC", "R1", "C1", "R0", "Error"])
    # error = DataFrame([[],[],[]], ["RMSE", "MaxError", "L2dist"])
	results = []
    for j in max_soc:-0.1:min_soc
        hppc_data = hppc_fun(data, j*100, soc_step, 1, discharge_step, charge_step, 1)
        
		voltage_temp, params_temp, results_temp = ecm_fit(hppc_data, capacity, open_circuit_voltage, j, [0.9, 1, 0.9], 1)
        
		push!(all_params, [j, params_temp[1], params_temp[2], params_temp[3], sqL2dist(voltage_temp, hppc_data[:,"Voltage(V)"])])
        
		# push!(error, [rmsd(voltage_temp, hppc_data[:,"Voltage(V)"]), maximum(voltage_temp.-hppc_data[:,"Voltage(V)"]), sqL2dist(voltage_temp, hppc_data[:,"Voltage(V)"])])
        voltages[j] = [voltage_temp, hppc_data[:,"Test_Time(s)"]]
		
		results = results_temp
    end

    return voltages, all_params, results
end

function soc_loop_2RC(data, max_soc, min_soc, capacity, open_circuit_voltage, discharge_step, charge_step, soc_step)

	# print("--------------\n")
    voltages = OrderedDict()
    all_params = DataFrame([[],[],[],[],[],[],[]], ["SOC", "R1", "R2", "C1", "C2", "R0", "Error"])
    # error = DataFrame([[],[],[]], ["RMSE", "MaxError", "L2dist"])
	results = []
    for j in max_soc:-0.1:min_soc
        hppc_data = hppc_fun(data, j*100, soc_step, 1, discharge_step, charge_step, 1)
        
		voltage_temp, params_temp, results_temp = ecm_fit(hppc_data, capacity, open_circuit_voltage, j, [0.9, 0.9, 1, 1, 0.9], 2)
        
		push!(all_params, [j, params_temp[1], params_temp[2], params_temp[3], params_temp[4], params_temp[5], sqL2dist(voltage_temp, hppc_data[:,"Voltage(V)"])])
        
		# push!(error, [rmsd(voltage_temp, hppc_data[:,"Voltage(V)"]), maximum(voltage_temp.-hppc_data[:,"Voltage(V)"]), sqL2dist(voltage_temp, hppc_data[:,"Voltage(V)"])])
        voltages[j] = [voltage_temp, hppc_data[:,"Test_Time(s)"]]
		
		results = results_temp
		print(j)
    end

    return voltages, all_params, results
    # print("-------------- \n")
    # vmod = OrderedDict()
    # xmod = DataFrame([[],[],[],[],[],[]], ["SOC", "R1", "R2", "C1", "C2", "R0"])
    # err = DataFrame([[],[],[]], ["RMSE", "MaxError", "L2dist"])
    # for j in min_soc:0.1:max_soc
    #     hppcdata = hppc_fun(data, j*100, soc_step, 1, dis_step, char_step, 1)
    #     vtemp, xtemp = ecm_fit(hppcdata, Q, ocv, j, [0.005, 0.005, 30000, 100000, 0.010], 2)
    #     push!(xmod, [j, xtemp[1], xtemp[2], xtemp[3], xtemp[4], xtemp[5]])
    #     push!(err, [rmsd(vtemp, hppcdata[:,"Voltage(V)"]), maximum(vtemp.-hppcdata[:,"Voltage(V)"]), sqL2dist(vtemp, hppcdata[:,"Voltage(V)"])])
    #     vmod[j] = [vtemp, hppcdata[:,"Test_Time(s)"]]

    # end
    # return vmod, xmod, err
end

function incorrect_pres(model_data, exp_data, dis_step, char_step, soc_step)
    err = Array{Float64}(undef, length(model_data),2)
    k = 1
    for i in eachindex(model_data)
        data = hppc_fun(exp_data, i*100, soc_step, 1, dis_step, char_step, 1)[:,"Voltage(V)"]
        if length(data) > length(model_data[i][1])
            err[k,1] = rmsd(model_data[i][1], data[1:end-(length(data)-length(model_data[i][1]))])
            err[k,2] = maximum(abs.(model_data[i][1] .- data[1:end-(length(data)-length(model_data[i][1]))]))
        else 
            err[k,1] = rmsd(model_data[i][1][1:end-(length(model_data[i][1])-length(data))], data)
            err[k,2] = maximum(abs.(model_data[i][1][1:end-(length(model_data[i][1])-length(data))] .- data))
        end

        k += 1
    end

    return err
end

function ecm_err_range(data, Q, ocv, soc, soc_increment, dstep, C1_range, R1_range)
    df = hppc_fun(data, soc*100, soc_increment, 1, dstep, dstep+2, 1)
    r0_init = hppc_calc(df, round(((100 - soc*100) / soc_increment)), df[:,"Voltage(V)"][1])
	xrng = R1_range[1]:R1_range[2]:R1_range[3]
    yrng = C1_range[1]:C1_range[2]:C1_range[3]
	zrng = r0_init-0.01:0.001:r0_init+0.01
    errors = OrderedDict{Float64, Matrix{Float64}}()
    current = df."Current(A)"
    test_time = df."Test_Time(s)"
    voltage_end = df."Voltage(V)"[1:end-1]
    
    err_matrix = zeros(length(xrng) + 1, length(yrng) + 1)
    err_matrix[1, 2:end] .= yrng
    err_matrix[2:end, 1] .= xrng
    
    # print(r0, "\n")
    # for k in r0 * 0.5:0.0005:r0*1.5
    for (k,r0) in enumerate(zrng)
        for (i,r1) in enumerate(xrng)
            for (j,c1) in enumerate(yrng)
                v_model = ecm_discrete([r1, c1, r0], 1, current, test_time, 0.999, Q, ocv, soc)
                err = sqL2dist(v_model, voltage_end)
                err_matrix[i+1, j+1] = err
            end
        end
        
        errors[round(r0, digits = 6)] = copy(err_matrix)
    end
    return errors
end

function rmins(data)
    r = DataFrame([[],[],[],[],[],[]], ["Error", "R0", "R1", "C1", "i", "j"])
    j = 1
    
    for i in eachindex(data)
        mincart = argmin(data[i][2:end, 2:end])
        push!(r,[round(minimum(data[i][2:end,2:end]), digits = 3),
					 round(i,digits=6), 
					 data[i][mincart[1]+1, 1], 
					 data[i][1, mincart[2]+1], 
					 mincart[1], 
					 mincart[2]])
        j += 1
    end
	
    return sort!(r, :Error)
end

function pres_contour(dict, min, title)
	t1 = contour(z=dict[min[1,:R0]][2:end, 2:end], x=dict[min[1,:R0]][1, 2:end], y=dict[min[1,:R0]][2:end,1], contours_start = 0, contours_end = 0.5, contours_size = 0.025, colorbar_title="Error", showscale=true)
	t2 = scatter(x=[min[1,:C1]],y=[min[1,:R1]], mode="markers", showlegend = false)
	layout1 = Layout(title=title)
	
	return plot([t1,t2], layout1)

end

function soc_range(df, Q, ocv, soc_increment, d_step, r1_range, c1_range, soc_range)

	srng = soc_range[1]:soc_range[2]:soc_range[3]
	Z = OrderedDict()
    print("-------------- \n")
    err = DataFrame([[], [],[],[], []], [:SOC, :R0, :R1, :C1, :err])
    for i in srng
		print(i, "\n")
        z = ecm_err_range(df, Q, ocv, i, soc_increment, d_step, r1_range, c1_range);
        min = rmins(z)
        push!(err, [i min[1, :R0] min[1, :R1] min[1, :C1] min[1, :Error]])
		Z[i] = z
    end
    return err, Z
end

function soc_range_2RC(df, Q, ocv, soc_increment, d_step, C_range, R_range, soc_range)
	srng = soc_range[1]:soc_range[2]:soc_range[3]
	Z = OrderedDict()
	print("-------------- \n")
	err = DataFrame([[], [],[],[], [], [], []], [:SOC, :R0, :R1, :R2, :C1, :C2, :err])
	for i in srng
		print(i, "\n")
		z = ecm_err_range_2RC(df, Q, ocv, i, soc_increment, d_step, C_range, R_range);
		# min = rmins(z)
		# min = sort!(z, :Err)
		# push!(err, [i min[1, :R0] min[1, :R1] min[1, :R2] min[1, :C1] min[1, :C2] min[1, :Err]])
		Z[i] = z
	end
	return Z
end


function ecm_err_range_2RC(data, Q, ocv, soc, soc_increment, dstep, C_range, R_range)

    df = hppc_fun(data, soc*100, soc_increment, 1, dstep, dstep+2, 1)
    r0_init = hppc_calc(df, round(((100 - soc*100) / soc_increment)), df[:,"Voltage(V)"][1])
	zrng = r0_init-0.005:0.001:r0_init+0.002
    zrng_array = collect(enumerate(zrng))  # Convert to array for threading


    current = df."Current(A)"
    test_time = df."Test_Time(s)"
    voltage_end = df."Voltage(V)"

    results = DataFrame(R0 = Float64[], R1 = Float64[], R2 = Float64[], C1 = Float64[], C2 = Float64[], Err = Float64[])
    # resize!(results, length(R_range) * length(C_range) * length(R_range) * length(C_range) * length(zrng_array))

    z = 1
    for (k,r0) in zrng_array
        # print(k, "\n")
        for i in eachindex(R_range)
            for j in eachindex(R_range)
                for m in eachindex(C_range)
                    for n in eachindex(C_range)
                        r1 = R_range[i]
                        r2 = R_range[j]
                        c1 = C_range[m]
                        c2 = C_range[n]

                        v_model = ecm_discrete([r1,r2, c1,c2, r0], 2, current, test_time, 0.999, Q, ocv, voltage_end[1])
                        err = sqL2dist(v_model, voltage_end)
                        push!(results, [r0, r1, r2, c1, c2, err])
                        # results[z, :] = [r0, r1, r2, c1, c2, err]
                        z+=1
                    end
                end
            end
        end
        # append!(results, local_results)
        # errors[round(r0, digits = 6)] = df
        # errors[round(r0, digits = 6)] = copy(err_matrix)
    end

    return results
end

end
