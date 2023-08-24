using PIECM, Plots, Optim, Statistics, PGFPlotsX, LaTeXStrings

plotly()
Ϟ = distinguishable_colors(10)
# gr() 

# Fitting Data 
mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")
ocv = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)

soc = 0.8
mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)

mbpf40kpa_d = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 20, 1)

# Optimisation Parameters
data = mbpf130kpa_1
uᵢ = data."Current(A)"
Δ = data."Test_Time(s)"
η = 0.999
Q = 3.7

costfunction_closed1 = κ->costfunction(κ, 1, uᵢ, Δ, η, Q, ocv, soc, data) 
costfunction_closed2 = κ->costfunction(κ, 2, uᵢ, Δ, η, Q, ocv, soc, data) 
costfunction_closed3 = κ->costfunction(κ, 3, uᵢ, Δ, η, Q, ocv, soc, data) 

#-----------------------Initial Conditions--------------------------
x1 = [0.010, 3000, 0.010, 0]
x2 = [0.010, 0.010, 3000, 3000, 0.010, 0, 0]
x3 = [0.010, 0.010, 0.010, 3000, 3000, 3000, 0.010, 0]

# ---------------------------Optimisation-----------------------------

# res1 = optimize(costfunction_closed1, x1, iterations=10000)
# x1 = Optim.minimizer(res1)
# v1 = ecm_discrete(x1, 1, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc);

# res2 = optimize(costfunction_closed2, x2, iterations = 10000)
# x2 = Optim.minimizer(res2)
# v2 = ecm_discrete(x2, 2, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc);

# res3 = optimize(costfunction_closed3, x3, iterations = 10000)
# x3 = Optim.minimizer(res3)
# v3 = ecm_discrete(x3, 3, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc);

# println(minimum(res1))
# println(minimum(res2))
# println(minimum(res3))

# P_plot = @pgf GroupPlot(

#     {
#         group_style =
#         {
#             xticklabels_at="edge bottom",
#         },
#         height = "8cm", width = "12cm",
#         legend_pos= "south east"

#     },

#     {
#         xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 70,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[:,"Test_Time(s)"], y = mbpf130kpa_1[:,"Voltage(V)"])),
#     LegendEntry("47 kPa Experimental"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[1:end-1,"Test_Time(s)"], y = v2)),
#     LegendEntry("ECM"),
#     # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[1:end-1,"Test_Time(s)"], y = v3)),
#     # LegendEntry("ESC"),


# )