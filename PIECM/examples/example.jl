using PIECM, Plots, DataFrames

plotly()



A_cell₁ = .128 * .036 # m2
cd₁ = data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv")
pd₁ = pressure_dateformat_fix("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_pres.csv")
ocvd₁ = data_import("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv")
hppc_55 = hppc_pulse(cd₁, 55, 5, 1, 15, 17)
hppc_55."Test_Time(s)" .-= hppc_55."Test_Time(s)"[1]

p₁ = pressurematch(cd₁, pd₁, A_cell₁)

ocv₁ = pocv_calc(ocvd₁, 5, 8, 100)

x1 = [0.008, 38000, 0.012]
# v1 = ecm_discrete(x1, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 47)


x2 = [0.008, 3000, 0.012]
# v2 = ecm_discrete(x1, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 47)
# plot!(v2)

# err = costfunction(select(hppc_55, "Voltage(V)", "Current(A)"), x1, 1, hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 47)

uₜ = [ones(100).*-27.49736; ones(400).*0; ones(100).*5.998779 ;ones(400).*0]

# vt = ecm_discrete(x1, 1, uₜ, 0.1, 0.999, 3.7, ocv₁, 55)
# vt2 = ecm_discrete(x2, 1, uₜ, 0.1, 0.999, 3.7, ocv₁, 55)
v1 = ecm_discrete(x1, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 55)
v2 = ecm_discrete(x2, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 55)
# plot(collect(0.1:0.1:100),vt, label = "x1")
# plot!(collect(0.1:0.1:100),vt2, label = "x2")
plot(hppc_55."Test_Time(s)",v1, label = "x1")
plot!(hppc_55."Test_Time(s)",v2, label = "x2")
plot!(hppc_55."Test_Time(s)", hppc_55."Voltage(V)", label = "Experimental")

# vt2 = ecm_discrete(x2, 1, uₜ, 0.1, 0.999, 3.7, ocv₁, 47)
# plot!(vt2)