module PIECM

using CSV, DataFrames, Dates, Infiltrator, JLD2, Interpolations 
using StatsBase: L1dist
 
export data_import, pressure_dateformat_fix, pressurematch, hppc_pulse, pocv_calc, sqrzeros
export ecm_discrete, costfunction, costfunction_closed

# --------------- Fitting data import and calculations -----------------------------

sqrzeros(A) = zeros(A,A)
data_import(file_name) = CSV.read(file_name, DataFrame)

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
    p_updated = innerjoin(cell_data, pressure_data, on = :Date_Time) # Match date times
    return select(p_updated, "Date_Time", "Step_Index", "TC_Counter1", "TC_Counter2", "Current(A)", "Voltage(V)", "Pressure", "Discharge_Capacity(Ah)", "Charge_Capacity(Ah)")
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

function hppc_pulse(data, soc, soc_increment, pulse_rate, dis_pulse_step, char_pulse_step)
	
    df = filter(row -> row."TC_Counter1" == (soc/soc_increment) - 1 && row."TC_Counter2" == pulse_rate - 1, data)
	# df = filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1) || row."Step_Index" == (dis_pulse_step-1), df)
	
	return filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1), df)
	# return df[3:end,:]
end

# ----------------------------------
# x = [Rᵢ, Cᵢ, R₀]
# n_RC = number of RC pairs
# uᵢ = current vector input for prediction [A]
# Δ = timestep [s]
# η = coloumbic efficiency 
# Q = capacity [Ah]

# Static time step forward model
function ecm_discrete(x, n_RC, uᵢ, Δ :: Float64, η, Q, OCV, init_cap)
    
	interp_linear = linear_interpolation(OCV."State_of_Charge", OCV."Voltage") # Interpolation function for OCV based on capacity change
	
	# # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)

    z = Array{Float64}(undef, length(uᵢ))
    iᵣ = Array{Float64}(undef, length(uᵢ))
    v = Array{Float64}(undef, length(uᵢ))

    uᵢ = uᵢ .* -1 # Changes charge / discharge convention to match Plett ISBN:978-1-63081-023-8

	# Initial Values
    z[1] = init_cap
	z[2] = z[1] - (η*((Δ)/3600) / Q) * uᵢ[1]
    v[1] = interp_linear(init_cap)
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

function ecm_discrete(x, n_RC, uᵢ, Δ ::Vector , η, Q, OCV, init_cap)
        
	interp_linear = linear_interpolation(OCV."State_of_Charge", OCV."Voltage") # Interpolation function for OCV based on capacity change
	
	# # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)

    z = Array{Float64}(undef, length(uᵢ))
    iᵣ = Array{Float64}(undef, length(uᵢ), n_RC)
	# iᵣ = Tuple
    v = Array{Float64}(undef, length(uᵢ))
    τ = Array{Float64}(undef, length(Δ))

	uᵢ = uᵢ .* -1 # Changes charge / discharge convention to match Plett ISBN:978-1-63081-023-8

	# Change time vector to τ for each index 
	Δ .-= Δ[1]
	for i in 1:length(Δ)-1
		τ[i+1] = Δ[i+1] - Δ[i]
	end

	# Initial Values
    z[1] = init_cap
	z[2] = z[1] - (η*((τ[1])/3600) / Q) * uᵢ[1]
    v[1] = interp_linear(init_cap)
    iᵣ[1,:]= zeros(n_RC)' # can this be a proper term?





    for k in 2:length(uᵢ)-1

		for α in 1:n_RC
			F = exp(-Δ[k]/(x[α]*x[(n_RC+α)]))
			A_RC[α,α] = F
			B_RC[α] = (1-F)
		end

        # A_RC = exp(-(τ[k])/(x[1]*x[2]))
        # B_RC = 1 - exp(-(τ[k])/(x[1]*x[2]))

        z[k+1] = z[k] - (η*((τ[k+1])/3600) / Q) * uᵢ[k]
		
		# @infiltrate cond = true

		iᵣ[k+1,:] = (A_RC * (iᵣ[k,:]) + B_RC * uᵢ[k])'

		# solve matrix dimensionality issues for multiple RC pairs
		v[k] = interp_linear(z[k])- sum(x[1:n_RC] .* iᵣ[k,:]') - (x[end] * uᵢ[k])
    end

    v[end] = v[end-1]

    return v

end

function costfunction(data, x, n_RC, uᵢ, Δ, η, Q, OCV, init_cap)
	v = ecm_discrete(x, n_RC, uᵢ, Δ, η, Q, OCV, init_cap)
	return L1dist(v,data."Voltage(V)") 
end


function costfunction_closed(x)
	
	# data import
	cd₁ = data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv")
	hppc = hppc_pulse(cd₁, 55, 5, 1, 15, 17)
	hppc."Test_Time(s)" .-= hppc."Test_Time(s)"[1]

	ocvd₁ = data_import("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv")
	ocv₁ = pocv_calc(ocvd₁, 5, 8, 100)

	# Forward model parameters
	data = hppc
	n_RC = 2
	# uᵢ = [ones(100).*-27.49736; ones(400).*0; ones(100).*5.998779 ;ones(400).*0]
	uᵢ = hppc."Current(A)"
	Δ = hppc."Test_Time(s)"  
	η = 0.999
	Q = 3.7
	init_cap = 55

    return costfunction(data, x, n_RC, uᵢ, Δ, η, Q, ocv₁, init_cap)

end 


end
