using PIECM, Plots

plotly()

# --------------- Data Import ------------------------------
function data_imp(hppc_file, pres_file, Acell)
    
    cd = data_import_csv(hppc_file)
    A_cell = Acell[1] * Acell[2]
    pd = pressure_dateformat_fix(pres_file)
    return pressurematch(cd, pd, A_cell)

end

# hppc_55_cpf90kpa, ocv₁ = data_imp("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv", "data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 55, 5, 2, 15, 17,1)
# mbpf200kpa = xlsx_imp("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.xlsx", "Channel-6_1", "data/PressureData/200kpa_100kpa_Pressure_data.csv", [0.128, 0.036])
mbpf200kpa = data_imp("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.csv", "data/PressureData/200kpa_100kpa_Pressure_data.csv", [0.128, 0.036])
mbpf100kpa = data_imp("data/HPPC/230315_MBPF_Investigation_100kpa_11_0041_Channel_6_Wb_1.csv", "data/PressureData/200kpa_100kpa_Pressure_data.csv", [0.128, 0.036])
mbpf25kpa = data_imp("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv","data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv", [0.128, 0.036])
mbpf40kpa = data_imp("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv","data/PressureData/230321_PressureTest_11_0048.csv", [0.128, 0.036])
mbpf130kpa = data_imp("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv","data/PressureData/230321_PressureTest_11_0044.csv", [0.128, 0.036])
ocv = ocv_fun("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)

# ---------------- DCIR and Power Calculations -------------------------
# Outputs dictionary of calculated values for DC internal resistance and power values at each SOC point
# Two dictionary keys, Discharge and Charge
dcir_200kpa_1 = HPPC(mbpf200kpa, 5, 1, 17, 19, 22, 6, 13)
dcir_25kpa_1 = HPPC(mbpf25kpa, 10, 1, 17, 19, 22, 6, 13)
dcir_40kpa_1 = HPPC(mbpf40kpa, 10, 1, 20, 22, 25, 6, 13)
dcir_130kpa_1 = HPPC(mbpf130kpa, 10, 1, 20, 22, 25, 6, 13)

scatter(dcir_200kpa_1["Discharge"][:, "SOC"], dcir_200kpa_1["Discharge"][:, "Resistance"], label = "200kpa")
scatter!(dcir_25kpa_1["Discharge"][:, "SOC"], dcir_25kpa_1["Discharge"][:, "Resistance"], label = "25kpa")
scatter!(dcir_40kpa_1["Discharge"][:, "SOC"], dcir_40kpa_1["Discharge"][:, "Resistance"], label = "40kpa")
scatter!(dcir_130kpa_1["Discharge"][:, "SOC"], dcir_130kpa_1["Discharge"][:, "Resistance"], label = "130kpa")

scatter(dcir_200kpa_1["Discharge"][:, "SOC"], dcir_200kpa_1["Discharge"][:, "Max Power (W)"], label = "200kpa")
scatter!(dcir_25kpa_1["Discharge"][:, "SOC"], dcir_25kpa_1["Discharge"][:, "Max Power (W)"], label = "25kpa")
scatter!(dcir_40kpa_1["Discharge"][:, "SOC"], dcir_40kpa_1["Discharge"][:, "Max Power (W)"], label = "40kpa")
scatter!(dcir_130kpa_1["Discharge"][:, "SOC"], dcir_130kpa_1["Discharge"][:, "Max Power (W)"], label = "130kpa")

# ------------------- HPPC Pulse Functions ---------------------------------
# Filters HPPC data based on a specific SOC point, currently must be a multiple of the SOC soc_increment

soc = 0.9

mbpf200kpa_1 = hppc_fun(mbpf200kpa, soc*100, 5, 1, 17, 19, 1)
mbpf200kpa_21 = hppc_fun(mbpf200kpa, soc*100, 5, 21, 46, 48, 21)
mbpf100kpa_1 = hppc_fun(mbpf100kpa, soc*100, 5, 1, 17, 19, 1)
mbpf100kpa_21 = hppc_fun(mbpf100kpa, soc*100, 5, 21, 46, 48, 21)
mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)

plt=plot(mbpf40kpa_1[:,"Test_Time(s)"], mbpf40kpa_1[:,"Voltage(V)"], label = string(mean(mbpf25kpa_1[:,"Pressure"]))*" kPa", legend = :bottomright)
plot!(mbpf25kpa_1[:,"Test_Time(s)"], mbpf25kpa_1[:,"Voltage(V)"], label = string(mean(mbpf25kpa_1[:,"Pressure"]))*" kPa")
plot!(mbpf130kpa_1[:,"Test_Time(s)"], mbpf130kpa_1[:,"Voltage(V)"], label = label = string(mean(mbpf25kpa_1[:,"Pressure"]))*" kPa")

# ▱ = plot(mbpf200kpa_1[:,"Test_Time(s)"], mbpf200kpa_1[:,"Voltage(V)"], label = "200kpa Cycle 1")
# plot!(twinx(), mbpf100kpa_1[:,"Test_Time(s)"], mbpf100kpa_1[:,"Pressure"], label = "100kpa Pres Cycle 1",color=:red,xticks=:none)
# plot!(mbpf200kpa_1[:,"Test_Time(s)"], mbpf200kpa_1[:,"Voltage(V)"], label = "200kpa Cycle 1")
# plot!(twinx(), mbpf200kpa_1[:,"Test_Time(s)"], mbpf200kpa_1[:,"Pressure"], label = "200kpa Pres Cycle 1",color=:green,xticks=:none)
# # plot!(twinx(), mbpf25kpa_1[:,"Test_Time(s)"], mbpf25kpa_1[:,"Pressure"], label = "25kpa Pres Cycle 1",color=:pink,xticks=:none)
# display(plt)

# ----------------- Converting voltage to Float64 ----------------------------
# Only needed if XLSX is imported

# mbpf200kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf200kpa_1."Voltage(V)")
# mbpf200kpa_21."Voltage(V)" = convert(Array{Float64}, mbpf200kpa_21."Voltage(V)")
# mbpf100kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf100kpa_1."Voltage(V)")
# mbpf100kpa_21."Voltage(V)" = convert(Array{Float64}, mbpf100kpa_21."Voltage(V)")
# mbpf25kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf25kpa_1."Voltage(V)")
# mbpf40kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf40kpa_1."Voltage(V)")
# mbpf130kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf130kpa_1."Voltage(V)")