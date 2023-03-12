module PIECM

using CSV, DataFrames, Dates, Infiltrator, BenchmarkTools, Plots, JLD2

plotly()




# Functions

sqrzeros(A) = zeros(A,A)

function arbin_data_import(file_name)
    return  CSV.read(file_name, DataFrame)
end

# Only use if date format does not match Arbin date format
function pressure_data_import(file_name)
    data = CSV.read(file_name, DataFrame)
    data.Time = Dates.format.(data.Time, "HH:MM:SS")
    data.Date = Date.(data.Date, "dd/mm/yyyy")
    data.Date = Dates.format.(data.Date, "yyyy/mm/dd")
    data.Date_Time = data.Date .* " " .* data.Time

    return data
end

function pressurematch(cell_data, pressure_data, A_cell)
    # look at dynamic time warping?
 
    pressure_data.Pressure = pressure_data.Force ./ A_cell # Pascal
    p_updated = innerjoin(cell_data, pressure_data, on = :Date_Time)
    
    p_updated = select(p_updated, "Date_Time", "Step_Index", "TC_Counter1", "TC_Counter2", "Current(A)", "Voltage(V)", "Pressure", "Discharge_Capacity(Ah)", "Charge_Capacity(Ah)")
    return p_updated

end

function POCV(file_name, POCV_discharge_step, POCV_charge_step, OCV_steps, init_temp)
	m = load(file_name)
	α = Dict()

	for i in 0:(length(m)-1)
		n = string((init_temp+i*10))

		if length(m) > 1
			df = m[n*"C"]
		else
			df = m["data"]
		end

		if length(m) > 1
			α[n*"C"] = pocv_calc(df, POCV_discharge_step, POCV_charge_step, OCV_steps)
		else
			α["data"] = pocv_calc(df, POCV_discharge_step, POCV_charge_step, OCV_steps)
		end
	end

    return α

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
		POCVc_updated[j,1] = round(char_temp[!, "SOC"][min_c[2]],digits=0)
		POCVc_updated[j,2] = char_temp[min_c[2],"Voltage(V)"]

		min_d = findmin(abs.(dis_temp[:,"SOC"] .- i))
		POCVd_updated[j,1] = round(dis_temp[!, "SOC"][min_d[2]],digits=0)
		POCVd_updated[j,2] = dis_temp[min_d[2],"Voltage(V)"]
		POCVd_updated[j,3] = dis_temp[min_d[2],"Discharge_Energy(Wh)"]

		j += 1
	end

	# Find average between charge and discharge curves
	POCV_SOC = (POCVd_updated[:,1] .+ POCVc_updated[:,1]) ./ 2
	POCV_V = (POCVd_updated[:,2] .+ POCVc_updated[:,2]) ./ 2

	return DataFrame(State_of_Charge=POCV_SOC, Voltage=POCV_V, DisVoltage=POCVd_updated[:,2], DisSOC=POCVd_updated[:,1], CharVoltage=POCVc_updated[:,2], CharSOC=POCVc_updated[:,1], DisEnergy=POCVd_updated[:,3])
end

function HPPC(data, soc_increment, no_pulse_rates, dis_pulse_step, char_pulse_step, dis_step, initial_cap_step, DCIR_step)
        
    γ = Dict()
		initial_capacity = select(filter(row -> row."Step_Index" == initial_cap_step, data), "Discharge_Capacity(Ah)")

		DCIR = unique(select(filter(row -> row."Step_Index" == DCIR_step, data), "Internal_Resistance(Ohm)"))

		for b in 0:(no_pulse_rates-1)
			soc_steps = length(collect(0:soc_increment:100))-1
			SOC = Array{Float64}(undef, soc_steps, 1)
			∇_discharge = DataFrame([[], [], [], [], [], [], []], ["SOC", "Resistance", "Average Power (W)", "Max Power (W)", "Min Power (W)", "Max Current(A)", "Min Current(A)"])	
			∇_charge = DataFrame([[], [], [], [], [], [], []], ["SOC", "Resistance", "Average Power (W)", "Max Power (W)", "Min Power (W)", "Max Current(A)", "Min Current(A)"])

			dpulse_v = filter(row -> row."Step_Index" == (dis_pulse_step-1) && row."TC_Counter2" == b, data)
			cpulse_v = filter(row -> row."Step_Index" == (char_pulse_step-1) && row."TC_Counter2" == b, data)
			df_dpulse = filter(row -> row."Step_Index" == dis_pulse_step && row."TC_Counter2" == b, data) 
			df_cpulse = filter(row -> row."Step_Index" == char_pulse_step && row."TC_Counter2" == b, data)
			df_discharge = filter(row -> row."Step_Index" == dis_step && row."TC_Counter2" == b, data)

			# Calculate State of Charge based on capacities - Discharge to next step + discharge pulse - charge pulse
			# for g in 0:(soc_steps-1)

			for g in 0:findmax(df_discharge[:,"TC_Counter1"])[1]
				o = filter(row -> row."TC_Counter1" == g, df_discharge)
				dis_step_cap = o[end, "Discharge_Capacity(Ah)"] - o[1, "Discharge_Capacity(Ah)"]
				k = filter(row -> row."TC_Counter1" == g, df_dpulse)
				pulse_cap_d = k[end, "Discharge_Capacity(Ah)"] - k[1, "Discharge_Capacity(Ah)"]
				p = filter(row -> row."TC_Counter1" == g, df_cpulse)
				pulse_cap_c = p[end, "Charge_Capacity(Ah)"] - p[1, "Charge_Capacity(Ah)"]

				SOC[g+1] = dis_step_cap + pulse_cap_d - pulse_cap_c
			end

			SOC = cumsum(SOC[:,1])
			SOC = 100 .- SOC ./ initial_capacity[end,1] .* 100

			# Calculate relevant data for each SOC point
			for j in 1:(findmax(df_dpulse[:,"TC_Counter1"])[1]+1)
				dpulse_vi = filter(row -> row."TC_Counter1" == j-1, dpulse_v)[end,"Voltage(V)"]
				discharge = hppc_calc(df_dpulse, j, dpulse_vi)
				push!(∇_discharge, [SOC[j], discharge[1], discharge[2], discharge[3], discharge[4], discharge[5], discharge[6]])
			end

			for q in 1:(findmax(df_cpulse[:,"TC_Counter1"])[1]+1)
				cpulse_vi = filter(row -> row."TC_Counter1" == q-1, cpulse_v)[end,"Voltage(V)"]
				charge = hppc_calc(df_cpulse, q, cpulse_vi)
				push!(∇_charge, [SOC[q], charge[1], charge[2], charge[3], charge[4], charge[5], charge[6]])
			end
			
			# ∇_charge[:,"SOC"] = 100 .- ∇_charge[:,"SOC"]

			rate = string((b+1))

			γ["Pulse Rate " * rate] = Dict("Charge" => ∇_charge, "Discharge" => ∇_discharge)

		end

	return γ, DCIR
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

function avgr0(hppc_data)
    data = DataFrame()
    soc = DataFrame()

    for i in eachindex(hppc_data)
        for j in eachindex(hppc_data[i])
            data[:,i*" "*j] = hppc_data[i][j][:, "Resistance"]
            soc[:,i*" "*j] = hppc_data[i][j][:, "SOC"]
        end
    end

    combine(data, AsTable(:) => ByRow(mean), renamecols=true)
    combine(soc, AsTable(:) => ByRow(mean), renamecols=true)
    
    return data
end


# Fitting Data
# SLPB7336128HV

A_cell₁ = .128 * .036 # m2
cd₁ = arbin_data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv")
pd₁ = pressure_data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_pres.csv")
ocvd₁ = arbin_data_import("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv")

p₁ = pressurematch(cd₁, pd₁, A_cell₁)

ocv₁ = pocv_calc(ocvd₁, 5, 8, 100)
hppc₁, r₁ = HPPC(cd₁,5, 2, 15, 17, 20, 5, 11)

R0₁ = avgr0(hppc₁)
# ----------------------------------


function ecmfit(OCV_data, Q, fitting_data, R0)

    # Q = 0
    # η = 0
    # Δ = 0.1 # time step Δt
    # x = [0,0] # R1 C1
    R0 = mean(R0[1,:])
    # p = [R1 C1]
    p = [RC1]
    v = fitting_data.Voltage
    i = fitting_data.Current

    # u[1] = z ? am I doing this right?!
    # u[2] = iᵣ ? am I doing this right?!

    for j in 1:length(fittingdata[:,1])
        du[1] = -i[j] / Q
        # du[2] = diᵣ = - 1 / (p[1] * p[2]) * u[2] + 1 / (p[1] * p[2]) * i
        # v = OCV_data(u[1]) + p[1] * u[2] - R0 * i
        v[j] = OCV_data(u[1]) + p[1] - R0 * i[j]
    end


end

# x = [Rᵢ, Cᵢ]
# n_RC is number of RC pairs
# uᵢ is current vector input for prediction
# Δ is timestep
# η = coloumbic efficiency 
# R0 is measured ohmic resistance vector from HPPC data
# Q = capacity

function ecm_discrete(x, n_RC, uᵢ, Δ, η, R₀, Q, OCV)
    # # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)

    z = Array{Float64}(undef, length(uᵢ))
    iᵣ = Array{Float64}(undef, length(uᵢ))
    v = Array{Float64}(undef, length(uᵢ))

    # for α in 1:n_RC
    #     F = exp(-Δ/(x[1]*x[2]))
    #     A_RC[α,α] = F
    #     B_RC[α] = (1-F)
    # end

    A_RC = exp(-Δ/(x[1]*x[2]))
    B_RC = 1 - exp(-Δ/(x[1]*x[2]))

    for k in 1:length(uᵢ)-1
        z[k+1] = z[k] + (-η * Δ / Q) * uᵢ[k]
        iᵣ[k+1] = A_RC * iᵣ[k] + B_RC * uᵢ[k] # solve matrix dimensionality issues for multiple RC pairs
        # v[k] = filter(row -> row.State_of_Charge == round(z[k], digits=0), OCV)[:,:Voltage] + x[1] * iᵣ[k] - R₀ * uᵢ[k]
        v[k] = OCV + x[1] * iᵣ[k] - R₀ * uᵢ[k]
    end

    return v

end

end
    