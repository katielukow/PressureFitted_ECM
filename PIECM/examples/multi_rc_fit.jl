using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PlotlyJS, JLD2
using Base.Threads



mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.CSV", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.CSV", "old")
ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.CSV", 5, 8, 1000)

P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", "new")
mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.CSV", "new")
mbpf100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.CSV", "new")
ocv2 = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", 11, 13, 1000)

df25 = soc_range_2RC(mbpf25kpa, 3.7, ocv1, 10, 17, LinRange(1000,30000,40), LinRange(0.00001, .010001, 10), [0.1, .1, 1])
df40 = soc_range_2RC(mbpf40kpa, 3.7, ocv1, 10, 20, LinRange(1000,30000,40), LinRange(0.00001, .010001, 10), [0.1, .1, 1])
df130 = soc_range_2RC(mbpf130kpa, 3.7, ocv1, 10, 20, LinRange(1000,30000,40), LinRange(0.00001, .010001, 10), [0.1, .1, 1])

df0 = soc_range_2RC(P0kpa, 5.5, ocv2, 5, 19, LinRange(1000,30000,40), LinRange(0.00001, .010001, 10), [0.1, .1, 1])
df50 = soc_range_2RC(mbpf50kpa, 5.5, ocv2, 5, 19, LinRange(1000,600000,20), LinRange(0.00001, .020001, 10), [0.5, .1, 0.5])
df100 = soc_range_2RC(mbpf100kpa, 5.5, ocv2, 5, 19, LinRange(1000,30000,40), LinRange(0.00001, .010001, 10), [0.1, .1, 1])

jldsave("err25_2RC.jld2", data=df25)
jldsave("err40_2RC.jld2", data=df40)
jldsave("err130_2RC.jld2", data=df130)

jldsave("err0_2RC.jld2", data=df0)
jldsave("err50_2RC.jld2", data=df50)
jldsave("err100_2RC.jld2", data=df100)