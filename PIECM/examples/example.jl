using PIECM, Plots


A_cell₁ = .128 * .036 # m2
cd₁ = arbin_data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv")
pd₁ = pressure_data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_pres.csv")
ocvd₁ = arbin_data_import("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv")
hppc_55 = hppc_pulse(cd₁, 55, 5, 1, 15, 17)

p₁ = pressurematch(cd₁, pd₁, A_cell₁)

ocv₁ = pocv_calc(ocvd₁, 5, 8, 100)
hppc₁, r₁ = HPPC(cd₁,5, 2, 15, 17, 20, 5, 11)

R0₁ = avgr0(hppc₁)



v = ecm_discrete([0.003,14049, 0.011], 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 4, ocv₁, 55)