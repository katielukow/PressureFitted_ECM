using PIECM, BenchmarkTools, Colors


BenchmarkTools.DEFAULT_PARAMETERS.seconds = 60
# plotly()
Ϟ = distinguishable_colors(20)

mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
ocv = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", 11, 13, 1000)
mbpf50kpa.Date_Time .= replace.(mbpf50kpa.Date_Time, "\t" => "")

Q = 5.5
soc = 0.7
# hppc_fun(P50kpa, 90, 5, 19, 1)
mbpf50kpa_1 = hppc_fun(mbpf50kpa, soc*100, 5, 19, 1)

#  
# result = optimize(rosenbrock, lb, ub, ParticleSwarm(), maxiters=1000)


v, x, res, result = ecm_fit(mbpf50kpa_1, Q, ocv, soc*100, [0.2, .1, 1],1)