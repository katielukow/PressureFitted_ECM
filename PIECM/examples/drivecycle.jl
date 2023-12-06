using PIECM, DataFrames, PlotlyJS, JLD2
# ECM param import
err25 = jldopen("err25.jld2")["data"]
err40 = jldopen("err40.jld2")["data"]
err130 = jldopen("err130.jld2")["data"]

err0 = jldopen("err0.jld2")["data"]
err50 = jldopen("err50.jld2")["data"]
err100 = jldopen("err100.jld2")["data"]

# raw data import
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")

P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", "new")
mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
mbpf100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.csv", "new")

ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)
ocv2 = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", 11, 13, 1000)

# Data filtering
dc_40 = filter(row -> row."Step_Index" == 13, mbpf40kpa)
dc_130 = filter(row -> row."Step_Index" == 13, mbpf130kpa)

dc_0 = filter(row -> row."Step_Index" == 12, P0kpa)
dc_50 = filter(row -> row."Step_Index" == 12, mbpf50kpa)
dc_100 = filter(row -> row."Step_Index" == 12, mbpf100kpa)

dc_40."Test_Time(s)" .= dc_40."Test_Time(s)" .- dc_40[1,"Test_Time(s)"]
dc_130."Test_Time(s)" .= dc_130."Test_Time(s)" .- dc_130[1,"Test_Time(s)"]


# ECM runs
soc = 1.0
v40_2RC = ecm_discrete([x40_2RC[1, :R1],x40_2RC[1, :R2], x40_2RC[1, :C1],x40_2RC[1, :C2], x40_2RC[end, :R0]], 2, dc_40."Current(A)", dc_40."Test_Time(s)", 0.999, Q40, ocv1, dc_40[1,"Voltage(V)"])

v130_2RC = ecm_discrete([x130_2RC[1, :R1],x130_2RC[1, :R2], x130_2RC[1, :C1],x130_2RC[1, :C2], x130_2RC[end, :R0]], 2, dc_130."Current(A)", dc_130."Test_Time(s)", 0.999, Q130, ocv1, dc_130[1,"Voltage(V)"])



trace1 = scatter(x = dc_40."Test_Time(s)", y = dc_40."Voltage(V)", mode="lines")
trace2 = scatter(x = dc_40[:,"Test_Time(s)"], y = v40_2RC, mode="lines")
trace3 = scatter(x = dc_130."Test_Time(s)", y = dc_130."Voltage(V)", mode="lines")
# trace4 = scatter(x = dc_40[1:end-1,"Test_Time(s)"], y = d40_2RC, mode="lines")
plot([trace1,trace2, trace3])