using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PGFPlotsX, JLD2, BenchmarkTools

# ECM param import
# err25 = jldopen("JLD2_ECMParam/err25.jld2")["data"]
# err40 = jldopen("JLD2_ECMParam/err40.jld2")["data"]
# err130 = jldopen("JLD2_ECMParam/err130.jld2")["data"]

# err0 = jldopen("JLD2_ECMParam/err0.jld2")["data"]
# err50 = jldopen("JLD2_ECMParam/err50.jld2")["data"]
# err100 = jldopen("JLD2_ECMParam/err100.jld2")["data"]

# err25_2RC = jldopen("JLD2_ECMParam/err25_2RC.jld2")["data"]
# err40_2RC = jldopen("JLD2_ECMParam/err40_2RC.jld2")["data"]
# err130_2RC = jldopen("JLD2_ECMParam/err130_2RC.jld2")["data"]

# err0_2RC = jldopen("JLD2_ECMParam/err0_2RC.jld2")["data"]
# err50_2RC = jldopen("JLD2_ECMParam/err50_2RC.jld2")["data"]
# err100_2RC = jldopen("JLD2_ECMParam/err100_2RC.jld2")["data"]

# Data Import
mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.CSV", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.CSV", "old")
mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")
Q25 = filter(row -> row.Step_Index == 6, mbpf25kpa)[end,"Discharge_Capacity(Ah)"]
Q40 = filter(row -> row.Step_Index == 6, mbpf40kpa)[end,"Discharge_Capacity(Ah)"]
Q130 = filter(row -> row.Step_Index == 6, mbpf130kpa)[end,"Discharge_Capacity(Ah)"]
ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.CSV", 5, 8, 500)

P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", "new")
mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.CSV", "new")
mbpf100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.CSV", "new")
Q0 = filter(row -> row.Step_Index == 6, P0kpa)[end,"Discharge_Capacity(Ah)"]
Q50 = filter(row -> row.Step_Index == 6, mbpf50kpa)[end,"Discharge_Capacity(Ah)"]
Q100 = filter(row -> row.Step_Index == 6, mbpf100kpa)[end,"Discharge_Capacity(Ah)"]
ocv2 = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", 11, 13, 200)


# ECM param fitting
v40, x40, error_40 =  soc_loop(mbpf40kpa, 1.0, 0.2, Q40, ocv1, 20, 22, 10)
v25, x25, error_25 = soc_loop(mbpf25kpa, 1, 0.2, Q25, ocv1,  17, 19, 10)
v130, x130, error_130 = soc_loop(mbpf130kpa, 1, 0.2, Q130, ocv1, 20, 22, 10)

v0, x0, error_0 = soc_loop(P0kpa, 1, 0.2, Q0, ocv2, 19, 21, 5)
v50, x50, error_50 = soc_loop(mbpf50kpa, 1, 0.2, Q50, ocv2, 19, 21, 5)
v100, x100, error_100 = soc_loop(mbpf100kpa, 1, 0.2, Q100, ocv2, 19, 21, 5)

# ECM param fitting 2RC
v40_2RC, x40_2RC, error_40_2RC = soc_loop_2RC(mbpf40kpa, 1, 0.2, Q40, ocv1, 20, 22, 10);
v25_2RC, x25_2RC, error_25_2RC = soc_loop_2RC(mbpf25kpa, 1, 0.2, Q25, ocv1, 17, 19, 10);
v130_2RC, x130_2RC, error_130_2RC = soc_loop_2RC(mbpf130kpa, 1, 0.2, Q130, ocv1, 20, 22, 10);

v0_2RC, x0_2RC, error_0_2RC = soc_loop_2RC(P0kpa, 1, 0.2, Q0, ocv2, 19, 21, 5);
v50_2RC, x50_2RC, error_50_2RC = soc_loop_2RC(mbpf50kpa, 1, 0.2, Q50, ocv2, 19, 21, 5);
v100_2RC, x100_2RC, error_100_2RC = soc_loop_2RC(mbpf100kpa, 1.0, 0.2, Q100, ocv2, 19, 21, 5);


# p1 = scatter(x = x40[1:end-1,"SOC"], y = x40[1:end-1,"Error"], mode="lines", name="40 kPa")
# p2 = scatter(x = x40_2RC[1:end-1,"SOC"], y = x40_2RC[1:end-1,"Error"], mode="lines", name="40 2RC kPa")
# p3 = scatter(x = x25[1:end-1,"SOC"], y = x25[1:end-1,"Error"], mode="lines", name="25 kPa")
# p4 = scatter(x = x25_2RC[1:end-1,"SOC"], y = x25_2RC[1:end-1,"Error"], mode="lines", name="25 2RC kPa")
# p5 = scatter(x = x130[1:end-1,"SOC"], y = x130[1:end-1,"Error"], mode="lines", name="130 kPa")
# p6 = scatter(x = x130_2RC[1:end-1,"SOC"], y = x130_2RC[1:end-1,"Error"], mode="lines", name="130 2RC kPa")
# plot([p1,p2,p3,p4,p5,p6])

# p7 = scatter(x = x0[:,"SOC"], y = x0[:,"Error"], mode="lines", name="0 kPa")
# p8 = scatter(x = x0_2RC[:,"SOC"], y = x0_2RC[:,"Error"], mode="lines", name="0 2RC kPa")
# p9 = scatter(x = x50[:,"SOC"], y = x50[:,"Error"], mode="lines", name="50 kPa")
# p10 = scatter(x = x50_2RC[:,"SOC"], y = x50_2RC[:,"Error"], mode="lines", name="50 2RC kPa")
# p11 = scatter(x = x100[:,"SOC"], y = x100[:,"Error"], mode="lines", name="100 kPa")
# p12 = scatter(x = x100_2RC[:,"SOC"], y = x100_2RC[:,"Error"], mode="lines", name="100 2RC kPa")
# plot([p7,p8,p9,p10,p11,p12])