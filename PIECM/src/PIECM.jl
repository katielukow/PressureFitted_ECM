module PIECM

using CSV, DataFrames, Dates, Infiltrator, JLD2, Interpolations 
using StatsBase: L1dist
 
export data_import, pressure_date_format_fix, pressurematch, POCV, HPPC, hppc_pulse, pocv_calc, avgr0
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
	return filter(row -> row."Step_Index" == dis_pulse_step || row."Step_Index" == char_pulse_step || row."Step_Index" == (char_pulse_step-1)|| row."Step_Index" == (char_pulse_step+1), df)

end

# ----------------------------------
# x = [Rᵢ, Cᵢ, R₀]
# n_RC is number of RC pairs
# uᵢ is current vector input for prediction
# Δ is timestep
# η = coloumbic efficiency 
# R0 is measured ohmic resistance vector from HPPC data
# Q = capacity


function ecm_discrete(x, n_RC, uᵢ, Δ :: Float64, η, Q, OCV, init_cap)
    # # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)

    z = Array{Float64}(undef, length(uᵢ))
    iᵣ = Array{Float64}(undef, length(uᵢ))
    v = Array{Float64}(undef, length(uᵢ))
    # Δ_new = Array{Float64}(undef, length(Δ))

    # for α in 1:n_RC
    #     F = exp(-Δ/(x[1]*x[2]))
    #     A_RC[α,α] = F
    #     B_RC[α] = (1-F)
    # end
    uᵢ = uᵢ .* -1
    z[1] = init_cap
	z[2] = z[1] - (η*((Δ)/3600) / Q) * uᵢ[1]
    # z[2] = init_cap

    interp_linear = linear_interpolation(OCV."State_of_Charge", OCV."Voltage")
    v[1] = interp_linear(init_cap)
    # v[2] = interp_linear(init_cap)
    iᵣ[1]=0

	# Δ = Δ * 1/3600

	for k in 2:length(uᵢ)-1

        z[k+1] = z[k] - (η*((Δ)/3600) / Q) * uᵢ[k]

		iᵣ[k+1] = exp(-(Δ)/(x[1]*x[2])) * iᵣ[k] + (1 - exp(-(Δ)/(x[1]*x[2]))) * uᵢ[k] # solve matrix dimensionality issues for multiple RC pairs
        
		# @infiltrate cond = true

		v[k] = interp_linear(z[k]) - (x[1] * iᵣ[k]) - (x[3] * uᵢ[k])
    end

    v[end] = v[end-1]

    return v

end

function ecm_discrete(x, n_RC, uᵢ, Δ ::Vector , η, Q, OCV, init_cap)
    # # RC Params
    A_RC = sqrzeros(n_RC)
    B_RC = zeros(n_RC)
    z = Array{Float64}(undef, length(uᵢ))
    iᵣ = Array{Float64}(undef, length(uᵢ))
    v = Array{Float64}(undef, length(uᵢ))
    Δ_new = Array{Float64}(undef, length(Δ))

    # for α in 1:n_RC
    #     F = exp(-Δ/(x[1]*x[2]))
    #     A_RC[α,α] = F
    #     B_RC[α] = (1-F)
    # end

    uᵢ = uᵢ .* -1
    z[1] = init_cap
	z[2] = z[1] - (η*(Δ[2]) / Q) * uᵢ[1]

    interp_linear = linear_interpolation(OCV."State_of_Charge", OCV."Voltage")
    v[1] = interp_linear(init_cap)
    iᵣ[1]=-25

    Δ .-= Δ[1]

    for i in 1:length(Δ)-1
        Δ_new[i+1] = Δ[i+1] - Δ[i]
    end

    # Δ_new .*= 1/3600


    for k in 2:length(uᵢ)-1
        A_RC = exp(-(Δ_new[k])/(x[1]*x[2]))

        B_RC = 1 - exp(-(Δ_new[k])/(x[1]*x[2]))

        z[k+1] = z[k] - (η*((Δ_new[k+1])/3600) / Q) * uᵢ[k]

        iᵣ[k+1] = exp(-(Δ_new[k])/(x[1]*x[2])) * iᵣ[k] + (1 - exp(-(Δ_new[k])/(x[1]*x[2]))) * uᵢ[k] # solve matrix dimensionality issues for multiple RC pairs
        

		v[k] = interp_linear(z[k]) - (x[1] * iᵣ[k]) - (x[3] * uᵢ[k])
    end


    v[end] = v[end-1]

    return v

end

function costfunction(data, x, n_RC, uᵢ, Δ, η, Q, OCV, init_cap)

	v = ecm_discrete(x, n_RC, uᵢ, Δ, η, Q, OCV, init_cap)
	return L1dist(v,data."Voltage(V)") 

end


function costfunction_closed(x_mod)
    
    x = x_mod
	fitting_data = arbin_data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv")
	hppc_fit = hppc_pulse(fitting_data, 55, 5, 1, 15, 17)
	ocvd = arbin_data_import("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv")
	ocv = pocv_calc(ocvd, 5, 8, 100)

	data = select(hppc_fit, "Voltage(V)", "Current(A)")
	n_RC = 1
	# uᵢ = [ones(100).*-27.49736; ones(400).*0; ones(100).*5.998779 ;ones(400).*0]
	uᵢ = hppc_fit."Current(A)"
	Δ = 0.1  
	η = 0.999
	Q = 3.7
	init_cap = 55


    return costfunction(data, x, n_RC, uᵢ, Δ, η, Q, ocv, init_cap)

end 


end
