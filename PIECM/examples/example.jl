using PIECM, Plots, Optim, Statistics, PGFPlotsX, LaTeXStrings, StatsBase, BenchmarkTools

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 60
# plotly()
Ϟ = distinguishable_colors(10)
# gr() 

# Fitting Data 
mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")

P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", "new")
mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
mbpf100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.csv", "new")

ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)
ocv2 = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", 11, 13, 1000)

P0kpa.Date_Time .= replace.(P0kpa.Date_Time, "\t" => "")
mbpf50kpa.Date_Time .= replace.(mbpf50kpa.Date_Time, "\t" => "")
mbpf100kpa.Date_Time .= replace.(mbpf100kpa.Date_Time, "\t" => "")

soc = 0.1
mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)

mbpf0kpa_1 = hppc_fun(P0kpa, soc*100, 5, 1, 54, 56, 21)
mbpf50kpa_1 = hppc_fun(mbpf50kpa, soc*100, 5, 1, 19, 21, 1)
mbpf100kpa_1 = hppc_fun(mbpf100kpa, soc*100, 5, 1, 19, 21, 1)

# Optimisation Parameters
data = mbpf50kpa_1
# dc_data = filter(row -> row."Step_Index" == 12, mbpf_50kpa)
uᵢ = data."Current(A)"
Δ = data."Test_Time(s)"
η = 0.999
Q = 5.5
ocv = ocv2
x1 = [0.01, 2000, 0.005]
x2 = [0.01, 0.01, 2000, 2000, 0.005]

costfunction_closed = κ->costfunction(κ, 1, uᵢ, Δ, η, Q, ocv, soc, data)
res = optimize(costfunction_closed, [0.01, 2000, 0.005], iterations = 10000)
x = Optim.minimizer(res)
v = ecm_discrete(x, 1, data."Current(A)", data."Test_Time(s)", η, Q, ocv, soc)
t = @benchmark optimize(costfunction_closed, x1)

costfunction_closed2 = κ->costfunction(κ, 2, uᵢ, Δ, η, Q, ocv, soc, data)
res2 = optimize(costfunction_closed2, x2, iterations = 10000)
x2 = Optim.minimizer(res2)
v2 = ecm_discrete(x2, 2, data."Current(A)", data."Test_Time(s)", η, Q, ocv, soc)
t2 = @benchmark optimize(costfunction_closed2, x2)

print("1RC: ", median(t), "   ", rmsd(v, data."Voltage(V)"[1:end-1]), "\n")
print("2RC: ", median(t2), "   ", rmsd(v2, data."Voltage(V)"[1:end-1]), "\n")







# P_plot = @pgf GroupPlot(

#     {
#         group_style =
#         {
#             xticklabels_at="edge bottom",
#         },
#         height = "8cm", width = "10cm",
#         legend_pos= "south east"


#     },

#     {
#         xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = data[:,"Test_Time(s)"], y = data[:,"Voltage(V)"])),
#     LegendEntry("47 kPa Experimental"),
#     Plot({color = Ϟ[7], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = data130[:,"Test_Time(s)"], y = data130[:,"Voltage(V)"])),
#     LegendEntry("210 kPa Experimental"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = data[1:end-1,"Test_Time(s)"], y = v2)),
#     LegendEntry("Pressure Fitted ECM"),

# )
