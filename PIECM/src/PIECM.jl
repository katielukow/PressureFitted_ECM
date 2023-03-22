module PIECM

using CSV, DataFrames, Dates, Infiltrator, JLD2, Interpolations, XLSX, Statistics 
using StatsBase: L2dist
 
export data_import_csv, data_import_excel, pressure_dateformat_fix, pressurematch, hppc_pulse, pocv_calc, sqrzeros, HPPC, hppc_fun
export ecm_discrete, costfunction

# --------------- Fitting data import and calculations -----------------------------

sqrzeros(A) = zeros(A,A)
data_import_csv(file_name) = CSV.read(file_name, DataFrame)
data_import_excel(file_name, sheet_name) = DataFrame(XLSX.readtable(file_name, sheet_name))

# Imports pressure data and matches date format to the Arbin format
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
    # p_updated = innerjoin(cell_data, pressure_data, on = :Date_Time) # Match date times
    # return select(p_updated, "Date_Time", "Step_Index", "Cycle_Index", "TC_Counter1", "TC_Counter2", "Current(A)", "Voltage(V)", "Pressure", "Discharge_Capacity(Ah)", "Charge_Capacity(Ah)")
	return leftjoin(cell_data, pressure_data, on = :Date_Time)
end

function pocv_calc(df, POCV_discharge_step, POCV_charge_step, OCV_steps)

	POCVc_updated = Array{Float64}(undef,(OCV_steps+1),2)
	POCVd_updated = Array{Float64}(undef,(OCV_steps+1),3)
	step_size = 100 / OCV_steps
		
	# Select relavent data
	dis_temp = select(filter(row -> row."Step_Index" == POCV_discharge_step, df), "Voltage(V)", "Discharge_Capacity(Ah)", "Discharge_Energy(Wh)")
	char_temp = select(filter(row -> row."Step_Index" == POCV_charge_step, df), "Voltage(V)", "Charge_Capacity(Ah)", "Charge_Energy(Wh)")

	# Normalize capacities 
	dis_temp[:,"Discharge_Capacity(Ah)"] .-= dis_temp[1,"Discharge_Capacity(Ah)"]
	dis_temp[:,"Discharge_Energy(Wh)"] .-= dis_temp[1,"Discharge_Energy(Wh)"]
	char_temp[:,"Charge_Capacity(Ah)"] .-= char_temp[1,"Charge_Capacity(Ah)"]

	# Calculate and append SOC to the relavent dataframe
	dis_temp[!, "SOC"] = 100 .- dis_temp[:,"Discharge_Capacity(Ah)"] ./ dis_temp[end,"Discharge_Capacity(Ah)"] .* 100
	char_temp[!, "SOC"] = char_temp[:,"Charge_Capacity(Ah)"] ./ char_temp[end,"Charge_Capacity(Ah)"] .* 100

	# Select normalized data points for usable SOC table
	j = 1
	for i in 0:step_size:100 # iterating through SOC points
		min_c = findmin(abs.(char_temp[:,"SOC"] .- i))
		POCVc_updated[j,1] = round(char_temp[!, "SOC"][min_c[2]],digits=1)
		POCVc_updated[j,2] = char_temp[min_c[2],"Voltage(V)"]

		min_d = findmin(abs.(dis_temp[:,"SOC"] .- i))
		POCVd_updated[j,1] = round(dis_temp[!, "SOC"][min_d[2]],digits=1)
		POCVd_updated[j,2] = dis_temp[min_d[2],"Voltage(V)"]
		POCVd_updated[j,3] = dis_temp[min_d[2],"Discharge_Energy(Wh)"]

		j += 1
	end

	# Find average between charge and discharge curves
	POCV_SOC = ((POCVd_updated[:,1] .+ POCVc_updated[:,1]) ./ 2) ./ 100
	POCV_V = (POCVd_updated[:,2] .+ POCVc_updated[:,2]) ./ 2


	return DataFrame(State_of_Charge=POCV_SOC, Voltage=POCV_V, DisVoltage=POCVd_updated[:,2], DisSOC=POCVd_updated[:,1], CharVoltage=POCVc_updated[:,2], CharSOC=POCVc_updated[:,1], DisEnergy=POCVd_updated[:,3])
end

function hppc_pulse(data, soc, soc_increment, pulse_rate, dis_pulse_step, char_pulse_step)
	
    df = filter(row -> row."TC_Counter1" == ((100 - soc) / soc_increment), data)
	# df = filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1) || row."Step_Index" == (dis_pulse_step-1), df)
	
	return filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1), df)
	# return df[3:end,:]
end

function HPPC(data, soc_increment, cycle, dis_pulse_step, char_pulse_step, dis_step, initial_cap_step, DCIR_step)

    γ = Dict()

	initial_capacity = filter(row -> row."Step_Index" == initial_cap_step, data)[end,"Discharge_Capacity(Ah)"]

	DCIR = unique(select(filter(row -> row."Step_Index" == DCIR_step, data), "Internal_Resistance(Ohm)"))

	soc_steps = 100 ÷ soc_increment #length(collect(0:soc_increment:100))-1
	SOC = Array{Float64}(undef, soc_steps, 1)
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

function hppc_calc(dataframe, i, init_V)
	df = filter(row -> row."TC_Counter1" == (i-1), dataframe)

	r = abs((init_V - df[end,"Voltage(V)"]) / abs(mean(df[:,"Current(A)"])))
	P = df[:,"Voltage(V)"] .* df[:,"Current(A)"]
	P_min = findmin(abs.(P))[1]
	P_max = findmax(abs.(P))[1]
	P_avg = mean(P)
	I_min = findmin(abs.(df[:,"Current(A)"]))[1]
	I_max = findmax(abs.(df[:,"Current(A)"]))[1]

	t = [P_max P_min I_max I_min]

	if df[1, "Current(A)"] < 0
		t .= -t
	end

	return [r, P_avg, t[1], t[2], t[3], t[4]]
end

function hppc_fun(pd, soc, soc_step, pulse_rate, dis_step, char_step, cycle_index)
    
    hppc = hppc_pulse(pd, soc, soc_step, pulse_rate, dis_step, char_step)
    hppc = filter(row -> row."Cycle_Index" == cycle_index, hppc)
    hppc."Test_Time(s)" .-= hppc."Test_Time(s)"[1]

    return hppc
end
# ----------------------------------
# x = [Rᵢ, Cᵢ, R₀]
# n_RC = number of RC pairs
# uᵢ = current vector input for prediction [A]
# Δ = timestep [s]
# η = coloumbic efficiency 
# Q = capacity [Ah]

# Static time step forward model
function ecm_discrete(x, n_RC, uᵢ, Δ :: Float64, η, Q, OCV, Init_SOC)
    
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
	z[2] = z[1] - (η*((Δ)/3600) / Q) * uᵢ[1]
    v[1] = interp_linear(Init_SOC)
    iᵣ[1]=0 # can this be a proper term?

	# for α in 1:n_RC
    #     F = exp(-Δ/(x[1]*x[2]))
    #     A_RC[α,α] = F
    #     B_RC[α] = (1-F)
    # end

	for k in 2:length(uᵢ)-1
		A_RC = exp(-(Δ)/(x[1]*x[2]))
        B_RC = 1 - exp(-(Δ)/(x[1]*x[2]))
        z[k+1] = z[k] - (η*((Δ)/3600) / Q) * uᵢ[k]
		iᵣ[k+1] = A_RC * iᵣ[k] + B_RC * uᵢ[k] # solve matrix dimensionality issues for multiple RC pairs
		v[k] = interp_linear(z[k]) - (x[1] * iᵣ[k]) - (x[3] * uᵢ[k])
    end

    v[end] = v[end-1]

    return v

end

function ecm_discrete(x, n_RC, uᵢ, Δ ::Vector , η, Q, OCV, Init_SOC)
        
	interp_linear = linear_interpolation(OCV."State_of_Charge", OCV."Voltage") # Interpolation function for OCV based on capacity change
	
	# # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)

    z = Array{Float64}(undef, length(uᵢ))
    v = Array{Float64}(undef, length(uᵢ))
    τ = Array{Float64}(undef, length(Δ))

	# Change time vector to τ for each index 
	Δ .-= Δ[1]
	for i in 1:length(Δ)-1
		τ[i+1] = Δ[i+1] - Δ[i]
	end

	# Initial Values
    z[1] = Init_SOC
    v[1] = interp_linear(Init_SOC)
    iᵣ = zeros(length(uᵢ),n_RC)

    for k in 1:length(uᵢ)-1
		for α in 1:n_RC
			F = exp(-τ[k]/(x[α]*x[(n_RC+α)]))
			A_RC[α,α] = F
			B_RC[α] = (1-F)
		end

        z[k+1] = z[k] - (η*((τ[k+1])/3600) / Q) * -uᵢ[k]

		iᵣ[k+1,:] = (A_RC * iᵣ[k,:] + B_RC * -uᵢ[k])'

		v[k] = interp_linear(z[k]) - sum(x[1:n_RC] .* iᵣ[k,:]') - (x[end] * -uᵢ[k])
    end

    return v[1:end-1]

end

function costfunction(x, n_RC, uᵢ, Δ, η, Q, OCV, Init_SOC, data)
	v = ecm_discrete(x, n_RC, uᵢ, Δ, η, Q, OCV, Init_SOC)
	return L2dist(v,data[1:end-1,"Voltage(V)"]) 
end

# function costfunction_closed(x)
	
# 	# data import
# 	cd₁ = data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv")
# 	hppc = hppc_pulse(cd₁, 55, 5, 1, 15, 17)
# 	hppc."Test_Time(s)" .-= hppc."Test_Time(s)"[1]

# 	ocvd₁ = data_import("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv")
# 	ocv₁ = pocv_calc(ocvd₁, 5, 8, 1000)

# 	# Forward model parameters

# 	# n_RC = (length(x) - 1) ÷ 2
# 	n_RC = 2
# 	# uᵢ = [ones(100).*-27.49736; ones(400).*0; ones(100).*5.998779 ;ones(400).*0]
# 	uᵢ = hppc."Current(A)"
# 	Δ = hppc."Test_Time(s)"  
# 	η = 0.999
# 	Q = 3.7
# 	Init_SOC = 55

#     return costfunction(hppc, x, n_RC, uᵢ, Δ, η, Q, ocv₁, Init_SOC)

# end 


end
