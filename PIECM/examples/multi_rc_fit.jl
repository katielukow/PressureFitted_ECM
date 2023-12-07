using PIECM, DataStructures, DataFrames, JLD2

# mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.CSV", "old")
# mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.CSV", "old")
# mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")
# Q25 = filter(row -> row.Step_Index == 6, mbpf25kpa)[end,"Discharge_Capacity(Ah)"]
# Q40 = filter(row -> row.Step_Index == 6, mbpf40kpa)[end,"Discharge_Capacity(Ah)"]
# Q130 = filter(row -> row.Step_Index == 6, mbpf130kpa)[end,"Discharge_Capacity(Ah)"]
# ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.CSV", 5, 8, 500)

# P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", "new")
# mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.CSV", "new")
# mbpf100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.CSV", "new")
# Q0 = filter(row -> row.Step_Index == 6, P0kpa)[end,"Discharge_Capacity(Ah)"]
# Q50 = filter(row -> row.Step_Index == 6, mbpf50kpa)[end,"Discharge_Capacity(Ah)"]
# Q100 = filter(row -> row.Step_Index == 6, mbpf100kpa)[end,"Discharge_Capacity(Ah)"]
# ocv2 = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", 11, 13, 200)
time1 = time()
df25 = soc_range_2RC(mbpf25kpa, Q25, ocv1, 10, 17, LinRange(1000,40000,10), LinRange(0.00001, .010001, 10), [0.2, .1, 1])
time2 = time()
# println(time2-time1, "\n")
# df40 = soc_range_2RC(mbpf40kpa, Q40, ocv1, 10, 20, LinRange(1000,40000,80), LinRange(0.00001, .010001, 10), [0.2, .1, 1])
# df130 = soc_range_2RC(mbpf130kpa, Q130, ocv1, 10, 20, LinRange(1000,40000,80), LinRange(0.00001, .010001, 10), [0.2, .1, 1])

# df0 = soc_range_2RC(P0kpa, Q0, ocv2, 5, 19, LinRange(1000,100000,100), LinRange(0.00001, .010001, 10), [0.2, .1, 1])
# df50 = soc_range_2RC(mbpf50kpa, Q50, ocv2, 5, 19, LinRange(1000,100000,100), LinRange(0.00001, .010001, 10), [0.2, .1, 1])
# df100 = soc_range_2RC(mbpf100kpa, Q100, ocv2, 5, 19, LinRange(1000,100000,100), LinRange(0.00001, .010001, 10), [0.2, .1, 1])

# jldsave("err25_2RC.jld2", data=df25)
# jldsave("err40_2RC.jld2", data=df40)
# jldsave("err130_2RC.jld2", data=df130)

# jldsave("err0_2RC.jld2", data=df0)
# jldsave("err50_2RC.jld2", data=df50)
# jldsave("err100_2RC.jld2", data=df100)