using PIECM, Plots, Optim, Statistics, PGFPlotsX, LaTeXStrings

plotly()
Ϟ = distinguishable_colors(10)
# gr() 

# Data 

function ocv_fun(ocv_file, char, dis, ocv_points)
    ocvd = data_import_csv(ocv_file)
    return pocv_calc(ocvd, char, dis, ocv_points)
end

# mbpf200kpa = data_import_csv("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.csv")
mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv")
mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv")
ocv = ocv_fun("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)


soc = 1

x130 = [5.227648703
1.570167521
-6.794674029
1.956464291
54.31892721
811149.0637
0.008436201]


# mbpf200kpa_1 = hppc_fun(mbpf200kpa, soc*100, 5, 1, 17, 19, 1)
# mbpf100kpa_1 = hppc_fun(mbpf100kpa, soc*100, 5, 1, 17, 19, 1)
# mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)


data = mbpf40kpa_1
uᵢ = data."Current(A)"
Δ = data."Test_Time(s)"
η = 0.999
Q = 3.7

costfunction_closed1 = κ->costfunction(κ, 1, uᵢ, Δ, η, Q, ocv, soc, data) 
costfunction_closed2 = κ->costfunction(κ, 2, uᵢ, Δ, η, Q, ocv, soc, data) 
costfunction_closed3 = κ->costfunction(κ, 3, uᵢ, Δ, η, Q, ocv, soc, data) 

#-----------------------Forward Model Testing--------------------------
x2 = [0.010, 0.008, 3000, 3500, 0.008]
x3 = [0.010, 0.010, 0.010, 3000, 3000, 3000, 0.008]
x1 = [0.008, 3000, 0.012]

# ---------------------------Optimising-----------------------------

res = optimize(costfunction_closed3, x3, iterations = 10000)
x = Optim.minimizer(res)
v = ecm_discrete(x, 3, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc);
v130 = ecm_discrete(x130, 3, data."Current(A)", data."Test_Time(s)", 0.9997, 3.7, ocv, soc)


# P_plot = @pgf GroupPlot(
    
#     {
#         group_style =
#         {
#             # group_size="2 by 1",
#             xticklabels_at="edge bottom",
#             # yticklabels_at="edge left",
#             # legend_pos= "north west"
#         },
#         height = "10cm", width = "15cm",
#         # legend_pos= "north east"

#     },

#     {
#         xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = 0, 
#         xmax = 100,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "south east"
#     },

#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = data."Test_Time(s)", y = data."Voltage(V)")),
#     LegendEntry("Experimental"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = data[1:end-1,"Test_Time(s)"], y = v)),
#     LegendEntry("Simulated"),

# # 5 = 40 kpa, 6 = 25 kpa, 7 = 130 kpa
# )
# # pgfsave("/Users/KatieLukow/Documents/OBMS23/Figures/ecm_25.pdf",P_plot)

# soc₁ = collect(100:-10:10)
# r_25 = [0.008747162,0.008824082,0.008772141,0.008849441,0.009078588,0.009115602,0.009404107,0.009810718,0.010193342,0.010105265]
# r_40 = [0.0109925,0.010806971,0.010393452,0.010102686,0.010031472,0.010100643,0.010449433,0.010814379,0.011115474,0.011080945]
# r_130 = [0.008436201,0.008435919,0.008574452,0.008506581,0.00874585,0.008885916,0.009236296,0.009658026,0.01001661,0.009850461]

# r0plot = @pgf GroupPlot(
    
#     {
#         group_style =
#         {
#             # group_size="2 by 1",
#             xticklabels_at="edge bottom",
#             # yticklabels_at="edge left",
#             # legend_pos= "north west"
#         },
#         height = "10cm", width = "15cm",
#         # legend_pos= "north east"

#     },

#     {
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="R0",
#         xmin = 10, 
#         xmax = 100,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "south west"
#     },

#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = soc₁, y = r_40)),
#     LegendEntry("47.0 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = soc₁, y = r_25)),
#     LegendEntry("139.0 kPa"),
#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = soc₁, y = r_130)),
#     LegendEntry("211.0 kPa"),

# # 5 = 40 kpa, 6 = 25 kpa, 7 = 130 kpa
# )

# pgfsave("/Users/KatieLukow/Documents/OBMS23/Figures/R0.pdf",r0plot)

PIE_plot = @pgf GroupPlot(
    
    {
        group_style =
        {
            # group_size="2 by 1",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "north west"
        },
        height = "10cm", width = "15cm",
        # legend_pos= "north east"

    },

    {
        xlabel="Time [s]",
        ylabel="Voltage [V]",
        xmin = 0, 
        xmax = 100,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = data."Test_Time(s)", y = data."Voltage(V)")),
    LegendEntry("Experimental"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = data[1:end-1,"Test_Time(s)"], y = v)),
    LegendEntry("Pressure-Fitted ECM"),
    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = data[1:end-1,"Test_Time(s)"], y = v130)),
    LegendEntry("Pressure-Agnostic ECM"),

# 5 = 40 kpa, 6 = 25 kpa, 7 = 130 kpa
)
pgfsave("/Users/KatieLukow/Documents/OBMS23/Figures/pie_comp.pdf",PIE_plot)

dc = filter(row -> row."Step_Index" == 13, mbpf40kpa)
dc[:,"Test_Time(s)"] .-= dc[1,"Test_Time(s)"]
vdc = ecm_discrete(x, 3, dc."Current(A)", dc."Test_Time(s)", 0.9997, 3.7, ocv, 1)
vdc130 = ecm_discrete(x130, 3, dc."Current(A)", dc."Test_Time(s)", 0.9997, 3.7, ocv, 1)
# plot(vdc)
# plot!(dc[:,"Voltage(V)"])

PIEdc_plot = @pgf GroupPlot(
    
    {
        group_style =
        {
            # group_size="2 by 1",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "north west"
        },
        height = "10cm", width = "15cm",
        # legend_pos= "north east"

    },

    {
        xlabel="Time [s]",
        ylabel="Voltage [V]",
        xmin = 0, 
        xmax = 55,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = dc."Test_Time(s)", y = dc."Voltage(V)")),
    LegendEntry("Experimental"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = dc[1:end-1,"Test_Time(s)"], y = vdc)),
    LegendEntry("Pressure-Fitted ECM"),
    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = dc[1:end-1,"Test_Time(s)"], y = vdc130)),
    LegendEntry("Pressure-Agnostic ECM"),

# 5 = 40 kpa, 6 = 25 kpa, 7 = 130 kpa
)

pgfsave("/Users/KatieLukow/Documents/OBMS23/Figures/piedc_comp.pdf",PIEdc_plot)