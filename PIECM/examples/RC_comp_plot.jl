using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PGFPlotsX, JLD2

err25 = jldopen("JLD2_ECMParam/err25.jld2")["data"]
err40 = jldopen("JLD2_ECMParam/err40.jld2")["data"]
err130 = jldopen("JLD2_ECMParam/err130.jld2")["data"]

err0 = jldopen("JLD2_ECMParam/err0.jld2")["data"]
err50 = jldopen("JLD2_ECMParam/err50.jld2")["data"]
err100 = jldopen("JLD2_ECMParam/err100.jld2")["data"]

err25_2RC = jldopen("JLD2_ECMParam/err25_2RC.jld2")["data"]
err40_2RC = jldopen("JLD2_ECMParam/err40_2RC.jld2")["data"]
err130_2RC = jldopen("JLD2_ECMParam/err130_2RC.jld2")["data"]

err0_2RC = jldopen("JLD2_ECMParam/err0_2RC.jld2")["data"]
err50_2RC = jldopen("JLD2_ECMParam/err50_2RC.jld2")["data"]
err100_2RC = jldopen("JLD2_ECMParam/err100_2RC.jld2")["data"]


p1 = scatter(x = err50[:,"SOC"], y = err50[:,"err"], mode = "lines", legendentry = "1RC")
p2 = scatter(x = err50_2RC[:,"SOC"], y = err50_2RC[:,"err"], mode = "lines", legendentry = "2RC")

plot([p1,p2])

soc = 0.5
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
hppc_40 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1);

v40_2rc = ecm_discrete([err40_2RC[end, :R1], err40_2RC[end, :R2], err40_2RC[end, :C1], err40_2RC[end, :C2], err40_2RC[end, :R0]], 2, hppc_40."Current(A)", hppc_40."Test_Time(s)", 0.999, 3.7, ocv1, soc)
v40_1rc = ecm_discrete([err40[end, :R1], err40[end, :C1], err40[end, :R0]], 1, hppc_40."Current(A)", hppc_40."Test_Time(s)", 0.999, 3.7, ocv1, soc)

p1 = scatter(x = hppc_40."Test_Time(s)", y = hppc_40."Voltage(V)", mode = "lines", legendentry = "Raw Data")
p2 = scatter(x = hppc_40[1:end-1,"Test_Time(s)"], y = v40_1rc, mode = "lines", legendentry = "1RC")
p3 = scatter(x = hppc_40[1:end-1,"Test_Time(s)"], y = v40_2rc, mode = "lines", legendentry = "2RC")
p4 = scatter(x = hppc_40[1:end-1,"Test_Time(s)"], y = v40[0.5][1], mode = "lines", legendentry = "2RC")

plot([p1,p2,p3,p4])