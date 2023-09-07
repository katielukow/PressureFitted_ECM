using PIECM, Plots, Optim, Statistics, PGFPlotsX, LaTeXStrings, StatsBase

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

# Model 2
cell_dim2 = [0.0418, .1255]

P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", "new")
mbpf_50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
mbpf_100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.csv", "new")

mbpf0kpa_1 = hppc_fun(P0kpa, soc*100, 20, 1, 20, 22, 1)
mbpf0kpa_101 = hppc_fun(P0kpa, soc*100, 20, 1, 54, 56, 101)


P0kpa.Date_Time .= replace.(P0kpa.Date_Time, "\t" => "")
mbpf_50kpa.Date_Time .= replace.(mbpf_50kpa.Date_Time, "\t" => "")
mbpf_100kpa.Date_Time .= replace.(mbpf_100kpa.Date_Time, "\t" => "")


# Optimisation Parameters
# data = mbpf40kpa_1
# dc_data = filter(row -> row."Step_Index" == 12, mbpf_50kpa)
# uᵢ = data."Current(A)"
# Δ = data."Test_Time(s)"
η = 0.999
Q = 3.7

# costfunction_closed1 = κ->costfunction(κ, 1, uᵢ, Δ, η, Q, ocv, soc, data) 
# costfunction_closed3 = κ->costfunction(κ, 3, uᵢ, Δ, η, Q, ocv, soc, data) 

#-----------------------Initial Conditions--------------------------
x2 = [0.01, 0.01, 2000, 2000, 0.008]

# ---------------------------Optimisation-----------------------------

# res1 = optimize(costfunction_closed1, x1, LBFGS())
# x1 = Optim.minimizer(res1)
# v1 = ecm_discrete(x1, 1, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc);




function ecmrmse(data_in, soc, xi, ocv)
    data = hppc_fun(data_in, soc*100, 10, 1, 20, 22, 1)
    uᵢ = data."Current(A)"
    Δ = data."Test_Time(s)"

    costfunction_closed2 = κ->costfunction(κ, 2, uᵢ, Δ, η, Q, ocv, soc, data) 


    res = optimize(costfunction_closed2, xi, iterations = 10000)
    x = Optim.minimizer(res)
    v2 = ecm_discrete(x, 2, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc)

    return rmsd(v2, data."Voltage(V)"[1:end-1])

end

rmses = Array{Float64}(undef, 10)
for i in .1:0.1:1
    ξ = ecmrmse(mbpf130kpa, i, x2, ocv)
    println(ξ)
    rmses[Int(i*10)] = ξ
end

# println(rmses)
println(mean(rmses, weights(ones(10))))

# println(rmsd(v2, data."Voltage(V)"[1:end-1]))

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

#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = data[:,"Test_Time(s)"], y = data[:,"Voltage(V)"])),
#     LegendEntry("0 kPa Experimental"),
#     # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = mbpf0kpa_101[5:end,"Test_Time(s)"].-mbpf0kpa_101[5,"Test_Time(s)"], y = mbpf0kpa_101[5:end,"Voltage(V)"])),
#     LegendEntry("0 kPa cycle 101 Experimental"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = data[1:end-1,"Test_Time(s)"], y = v2)),
#     LegendEntry("ECM"),

# )
