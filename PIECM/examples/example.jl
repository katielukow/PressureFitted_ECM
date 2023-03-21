using PIECM, Plots, Optim

plotly()
# gr() 

# Data 
function xlsx_imp(hppc_file, sheet_name, pres_file, Acell)
    
    return data_import_excel(hppc_file, sheet_name)
    # A_cell = Acell[1] * Acell[2]
    # pd = pressure_dateformat_fix(pres_file)
    # return pressurematch(cd, pd, A_cell)

end

function ocv_fun(ocv_file, char, dis, ocv_points)
    ocvd = data_import_csv(ocv_file)
    return pocv_calc(ocvd, char, dis, ocv_points)
end

function hppc_fun(pd, soc, soc_step, pulse_rate, dis_step, char_step, cycle_index)
    
    hppc = hppc_pulse(pd, soc, soc_step, pulse_rate, dis_step, char_step)
    hppc = filter(row -> row."Cycle_Index" == cycle_index, hppc)
    hppc."Test_Time(s)" .-= hppc."Test_Time(s)"[1]

    return hppc
end


# hppc_55_cpf90kpa, ocv₁ = data_imp("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv", "data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 55, 5, 2, 15, 17,1)
# mbpf200kpa = xlsx_imp("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.xlsx", "Channel-6_1", "data/PressureData/200kpa_100kpa_Pressure_data.csv", [0.128, 0.036])
mbpf200kpa = data_import_csv("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.csv")
# mbpf100kpa = xlsx_imp("data/HPPC/230315_MBPF_Investigation_100kpa_11_0041_Channel_6_Wb_1.xlsx", "Channel-6_1", "data/PressureData/200kpa_100kpa_Pressure_data.csv", [0.128, 0.036])
# mbpf25kpa = xlsx_imp("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.xlsx", "Channel-6_1", "data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv" , [0.128, 0.036])
mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv")
# ocv = ocv_fun("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)

soc = 0.2

mbpf200kpa_1 = hppc_fun(mbpf200kpa, 20, 5, 1, 17, 19, 1)
mbpf200kpa_21 = hppc_fun(mbpf200kpa, 20, 5, 21, 46, 48, 21)
# mbpf100kpa_1 = hppc_fun(mbpf100kpa, soc*100, 5, 1, 17, 19, 1)
# mbpf100kpa_21 = hppc_fun(mbpf100kpa, soc*100, 5, 21, 46, 48, 21)
mbpf25kpa_1 = hppc_fun(mbpf25kpa, 20, 10, 1, 17, 19, 1)

mbpf200kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf200kpa_1."Voltage(V)")
mbpf200kpa_21."Voltage(V)" = convert(Array{Float64}, mbpf200kpa_21."Voltage(V)")
mbpf100kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf100kpa_1."Voltage(V)")
mbpf100kpa_21."Voltage(V)" = convert(Array{Float64}, mbpf100kpa_21."Voltage(V)")
mbpf25kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf25kpa_1."Voltage(V)")

dcir_200kpa_1, f = HPPC(mbpf200kpa, 5, 1, 17, 19, 22, 6, 13)
dcir_25kpa_1, f = HPPC(mbpf25kpa, 10, 1, 17, 19, 22, 6, 13)

data = mbpf200kpa_1
uᵢ = data."Current(A)"
Δ = data."Test_Time(s)"
η = 0.999
Q = 3.7

costfunction_closed1 = κ->costfunction(κ, 1, uᵢ, Δ, η, Q, ocv, soc, data) 
costfunction_closed2 = κ->costfunction(κ, 2, uᵢ, Δ, η, Q, ocv, soc, data) 

#-----------------------Forward Model Testing--------------------------
x2 = [0.010, 0.008, 3000, 3500, 0.008]
x1 = [0.008, 3000, 0.012]

# v1 = ecm_discrete(x1, 2, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, .55)
# v2 = ecm_discrete(x2, 1, hppc_55_mbpf100kpa_21."Current(A)", hppc_55_mbpf100kpa_21."Test_Time(s)", 0.999, 3.7, ocv, .55)

# err1 = costfunction(x1, 2, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, .55, hppc_55)
# err2 = costfunction(x2, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, .55, hppc_55)

# ---------------------------Optimising-----------------------------

res1 = optimize(costfunction_closed1, x1)
x₁ = Optim.minimizer(res1)
v₁ = ecm_discrete(x₁, 1, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc)

res2 = optimize(costfunction_closed2, x2)
x₂ = Optim.minimizer(res2)
v₂ = ecm_discrete(x₂, 2, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc)
# plt = plot(data."Test_Time(s)", data."Voltage(V)", label = "200kpa Cycle 21")
# plot!(data[1:end-1,"Test_Time(s)"], v₁, label = "Nelder Mead")
# plot!(data[1:end-1,"Test_Time(s)"], v₂, label = "LBFGS()")

▱ = plot(mbpf200kpa_1[:,"Test_Time(s)"], mbpf200kpa_1[:,"Voltage(V)"], label = "200kpa Cycle 1")
# plot!(twinx(), mbpf100kpa_1[:,"Test_Time(s)"], mbpf100kpa_1[:,"Pressure"], label = "100kpa Pres Cycle 1",color=:red,xticks=:none)
# plot!(mbpf200kpa_1[:,"Test_Time(s)"], mbpf200kpa_1[:,"Voltage(V)"], label = "200kpa Cycle 1")
# plot!(twinx(), mbpf200kpa_1[:,"Test_Time(s)"], mbpf200kpa_1[:,"Pressure"], label = "200kpa Pres Cycle 1",color=:green,xticks=:none)
plot!(mbpf25kpa_1[:,"Test_Time(s)"], mbpf25kpa_1[:,"Voltage(V)"], label = "25kpa Cycle 1")
# plot!(twinx(), mbpf25kpa_1[:,"Test_Time(s)"], mbpf25kpa_1[:,"Pressure"], label = "25kpa Pres Cycle 1",color=:pink,xticks=:none)
display(▱)