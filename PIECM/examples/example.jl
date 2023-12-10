using PIECM, Optim, Statistics, PGFPlotsX, LaTeXStrings, StatsBase, BenchmarkTools, DataStructures, DataFrames, Infiltrator, Colors

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 60
# plotly()
Ϟ = distinguishable_colors(20)
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

soc = 0.5
mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 17, 1);
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 20, 1);
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 20, 1);

mbpf0kpa_1 = hppc_fun(P0kpa, soc*100, 5, 19, 1);
mbpf50kpa_1 = hppc_fun(mbpf50kpa, soc*100, 5, 19, 1);
mbpf100kpa_1 = hppc_fun(mbpf100kpa, 1*100, 5, 19, 1);


# # Dictionary of data
# mod1_dic = Dict(    
#     "mbpf25kpa" => mbpf25kpa,
#     "mbpf40kpa" => mbpf40kpa,
#     "mbpf130kpa" => mbpf130kpa,
# );

# mod2_dic = Dict(
#     "mbpf0kpa" => P0kpa,
#     "mbpf50kpa" => mbpf50kpa,
#     "mbpf100kpa" => mbpf100kpa,
# );
# err25 = jldopen("err25.jld2")["data"]
# err40 = jldopen("err40.jld2")["data"]
# err130 = jldopen("err130.jld2")["data"]

# err0 = jldopen("err0.jld2")["data"]
# err50 = jldopen("err50.jld2")["data"]
# err100 = jldopen("err100.jld2")["data"]


v25 = ecm_discrete([err25[Int(soc*10), :R1], err25[Int(soc*10), :C1], err25[Int(soc*10), :R0]], 1, mbpf25kpa_1[2:end, "Current(A)"], mbpf25kpa_1[2:end,"Test_Time(s)"], 
0.999, 3.7, ocv1, soc)
v40 = ecm_discrete([err40[Int(soc*10), :R1], err40[Int(soc*10), :C1], err40[Int(soc*10), :R0]], 1, mbpf40kpa_1[2:end, "Current(A)"], mbpf40kpa_1[2:end,"Test_Time(s)"], 0.999, 3.7, ocv1, soc)
v130 = ecm_discrete([err130[Int(soc*10), :R1], err130[Int(soc*10), :C1], err130[Int(soc*10), :R0]], 1, mbpf130kpa_1[2:end, "Current(A)"], mbpf130kpa_1[2:end,"Test_Time(s)"], 0.999, 3.7, ocv1, soc)
v130_2 = ecm_discrete([err130[Int(soc*10), :R1], err130[Int(soc*10), :C1]-2000, err130[Int(soc*10), :R0]], 1, mbpf130kpa_1[2:end, "Current(A)"], mbpf130kpa_1[2:end,"Test_Time(s)"], 0.999, 3.7, ocv1, soc)

v0 = ecm_discrete([err0[Int(soc*10), :R1], err0[Int(soc*10), :C1], err0[Int(soc*10), :R0]], 1, mbpf0kpa_1[2:end, "Current(A)"], mbpf0kpa_1[2:end,"Test_Time(s)"], 0.999, 5.5, ocv2, soc)
v50 = ecm_discrete([err50[Int(soc*10), :R1], err50[Int(soc*10), :C1], err50[Int(soc*10), :R0]], 1, mbpf50kpa_1[2:end, "Current(A)"], mbpf50kpa_1[2:end,"Test_Time(s)"], 0.999, 5.5, ocv2, soc)
v100 = ecm_discrete([err100[Int(soc*10), :R1], err100[Int(soc*10), :C1], err100[Int(soc*10), :R0]], 1, mbpf100kpa_1[2:end, "Current(A)"], mbpf100kpa_1[2:end,"Test_Time(s)"], 0.999, 5.5, ocv2, soc)




# fit_plot = @pgf GroupPlot(

#     {
#         group_style =
#         {
#             group_size = "3 by 2",
#             xticklabels_at="edge bottom",
#             yticklabels_at="edge left",
#             horizontal_sep = "0.5cm",
#             vertical_sep = "0.5cm"
#         },
#         height = "6cm", width = "10cm",
#         legend_pos= "south east"


#     },

#     {
#         # xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = mbpf40kpa_1[:,"Test_Time(s)"][1:end-1], y = v1["mbpf40kpa"][0.5])),
#     LegendEntry("40 kPa ECM"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf40kpa_1[:,"Test_Time(s)"], y = mbpf40kpa_1[:,"Voltage(V)"])),
#     LegendEntry("40 kPa Experimental"),

#     {
#         # xlabel="Time [s]",
#         # ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = mbpf25kpa_1[:,"Test_Time(s)"][1:end-1], y = v1["mbpf25kpa"][0.5])),
#     LegendEntry("130 kPa ECM"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf25kpa_1[:,"Test_Time(s)"], y = mbpf25kpa_1[:,"Voltage(V)"])),
#     LegendEntry("130 kPa Experimental"),
#     {
#         # xlabel="Time [s]",
#         # ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[:,"Test_Time(s)"][1:end-1], y = v1["mbpf130kpa"][0.5])),
#     LegendEntry("200 kPa ECM"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[:,"Test_Time(s)"], y = mbpf130kpa_1[:,"Voltage(V)"])),
#     LegendEntry("200 kPa Experimental"),

#     {
#         xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[7], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = mbpf0kpa_1[:,"Test_Time(s)"][1:end-1], y = v2["mbpf0kpa"][0.5])),
#     LegendEntry("0 kPa ECM"),
#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = mbpf0kpa_1[:,"Test_Time(s)"], y = mbpf0kpa_1[:,"Voltage(V)"])),
#     LegendEntry("0 kPa Experimental"),
#     {
#         xlabel="Time [s]",
#         # ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[7], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = mbpf50kpa_1[:,"Test_Time(s)"][1:end-1], y = v2["mbpf50kpa"][0.5])),
#     LegendEntry("50 kPa ECM"),
#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = mbpf50kpa_1[:,"Test_Time(s)"], y = mbpf50kpa_1[:,"Voltage(V)"])),
#     LegendEntry("50 kPa Experimental"),
#     {
#         xlabel="Time [s]",
#         # ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # xtick = 0:10:100,
#     },

#     Plot({color = Ϟ[7], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = mbpf100kpa_1[:,"Test_Time(s)"][1:end-1], y = v2["mbpf100kpa"][0.5])),
#     LegendEntry("100 kPa ECM"),
#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = mbpf100kpa_1[:,"Test_Time(s)"], y = mbpf100kpa_1[:,"Voltage(V)"])),
#     LegendEntry("100 kPa Experimental"),
# )

# err_plot = @pgf GroupPlot(

#     {
#         group_style =
#         {
#             group_size = "2 by 1",
#             xticklabels_at="edge bottom",
#             yticklabels_at="edge left",
#             horizontal_sep = "0.5cm",
#             vertical_sep = "0.5cm"
#         },
#         height = "6cm", width = "10cm",
#         legend_pos= "south east"
#     } ,
    
#     {
#         xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # ytick = 0.005:0.002:0.016,
#         # xtick = 0:10:100,
#     },
#     Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = v25[soc][2], y = v25[soc][1])),
#     LegendEntry("25 kPa ECM"),
#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = mbpf25kpa_1[:,"Test_Time(s)"], y = mbpf25kpa_1[:,"Voltage(V)"])),
#     LegendEntry("25 kPa Experimental"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf40kpa_1[:,"Test_Time(s)"], y = mbpf40kpa_1[:,"Voltage(V)"])),
#     LegendEntry("40 kPa Experimental"),
#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[:,"Test_Time(s)"], y = mbpf130kpa_1[:,"Voltage(V)"])),
#     LegendEntry("130 kPa Experimental"),

#     {
#         xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 65,
#         # ymax = 15,
#         # ymin = 0,
#         # ytick = 0.005:0.002:0.016,
#         # xtick = 0:10:100,
#     },
#     Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = v0[soc][2], y = v0[soc][1])),
#     LegendEntry("0 kPa ECM"),
#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = mbpf0kpa_1[:,"Test_Time(s)"], y = mbpf0kpa_1[:,"Voltage(V)"])),
#     LegendEntry("0 kPa Experimental"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf50kpa_1[:,"Test_Time(s)"], y = mbpf50kpa_1[:,"Voltage(V)"])),
#     LegendEntry("50 kPa Experimental"),
#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = mbpf100kpa_1[:,"Test_Time(s)"], y = mbpf100kpa_1[:,"Voltage(V)"])),
#     LegendEntry("100 kPa Experimental"),


# )
# pgfsave("figures/errpot.pdf", err_plot, include_preamble = false)

RCR0_2_plot = @pgf GroupPlot(

    {
        group_style =
        {
            group_size = "5 by 2",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            horizontal_sep = "2cm",
            vertical_sep = "1cm"
        },
        height = "5cm", width = "7cm",
        legend_pos= "outer north east"


    },

    {
        # xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R0",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        ytick = 0.005:0.002:0.016,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x40_2RC[:,"SOC"].*100, y = x40_2RC[:,"R0"])),

    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25_2RC[:,"SOC"].*100, y = x25_2RC[:,"R0"])),

    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x130_2RC[:,"SOC"].*100, y = x130_2RC[:,"R0"])),

    {
        # xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R1",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x40_2RC[:,"SOC"].*100, y = x40_2RC[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25_2RC[:,"SOC"].*100, y = x25_2RC[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x130_2RC[:,"SOC"].*100, y = x130_2RC[:,"R1"])),

    {
        # xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter C1",

        # ytick = 0:1000:6000
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x40_2RC[:,"SOC"].*100, y = x40_2RC[:,"C1"])),
    # LegendEntry("40 kPa"),
    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25_2RC[:,"SOC"].*100, y = x25_2RC[:,"C1"])),
    # LegendEntry("130 kPa"),
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x130_2RC[:,"SOC"].*100, y = x130_2RC[:,"C1"])),
    # LegendEntry("200 kPa"),
    {
        # xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R2",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x40_2RC[:,"SOC"].*100, y = x40_2RC[:,"R2"])),
    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25_2RC[:,"SOC"].*100, y = x25_2RC[:,"R2"])),
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x130_2RC[:,"SOC"].*100, y = x130_2RC[:,"R2"])),

    {
        # xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter C2",

        # ytick = 0:1000:6000
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x40_2RC[:,"SOC"].*100, y = x40_2RC[:,"C2"])),
    LegendEntry("40 kPa"),
    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25_2RC[:,"SOC"].*100, y = x25_2RC[:,"C2"])),
    LegendEntry("130 kPa"),
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x130_2RC[:,"SOC"].*100, y = x130_2RC[:,"C2"])),
    LegendEntry("210 kPa"),

    {
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R0",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        ytick = 0.00:0.001:0.016,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x0_2RC[:,"SOC"].*100, y = x0_2RC[:,"R0"])),

    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50_2RC[:,"SOC"].*100, y = x50_2RC[:,"R0"])),

    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x100_2RC[:,"SOC"].*100, y = x100_2RC[:,"R0"])),

    {
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R1",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x0_2RC[:,"SOC"].*100, y = x0_2RC[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50_2RC[:,"SOC"].*100, y = x50_2RC[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x100_2RC[:,"SOC"].*100, y = x100_2RC[:,"R1"])),

    {
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter C1",

        # ytick = 0:2000:50000
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x0_2RC[:,"SOC"].*100, y = x0_2RC[:,"C1"])),
    # LegendEntry("0 kPa"),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50_2RC[:,"SOC"].*100, y = x50_2RC[:,"C1"])),
    # LegendEntry("50 kPa"),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x100_2RC[:,"SOC"].*100, y = x100_2RC[:,"C1"])),
    # LegendEntry("100 kPa"),
    {
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R2",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x0_2RC[:,"SOC"].*100, y = x0_2RC[:,"R2"])),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50_2RC[:,"SOC"].*100, y = x50_2RC[:,"R2"])),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x100_2RC[:,"SOC"].*100, y = x100_2RC[:,"R2"])),

    {
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter C2",

        # ytick = 0:2000:50000
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dash dot"}}, Table({x = "x", y = "y"}, x = x0_2RC[:,"SOC"].*100, y = x0_2RC[:,"C2"])),
    LegendEntry("0 kPa"),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50_2RC[:,"SOC"].*100, y = x50_2RC[:,"C2"])),
    LegendEntry("50 kPa"),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dotted"}}, Table({x = "x", y = "y"}, x = x100_2RC[:,"SOC"].*100, y = x100_2RC[:,"C2"])),
    LegendEntry("100 kPa"),
    
    
)

# pgfsave("figures/fit_plot.pdf", fit_plot, include_preamble = false)
pgfsave("figures/RCR0_2_plot.pdf", RCR0_2_plot, include_preamble = false)


P_plot = @pgf GroupPlot(

    {
        group_style =
        {
            group_size = "2 by 1",
            xticklabels_at="edge bottom",
        },
        height = "8cm", width = "10cm",
        legend_pos= "south east"


    },

    {
        xlabel="Time [s]",
        ylabel="Voltage [V]",
        xmin = 58, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style = {"dotted"}}, Table({x = "x", y = "y"}, x = v130_exp20[:,"Test_Time(s)"], y = v130_exp20[:,"Voltage(V)"])),
    LegendEntry("210 kPa Experimental"),
    PGFPlotsX.Plot({color = Ϟ[8]}, Table({x = "x", y = "y"}, x = v130[0.2][2], y = v130[0.2][1])),
    LegendEntry("210 kPa Pressure Fitted ECM"),
    PGFPlotsX.Plot({color = Ϟ[6]}, Table({x = "x", y = "y"}, x = v25[0.2][2], y = v25[0.2][1])),
    LegendEntry("40 kPa Pressure Fitted ECM"),

    {
        xlabel="Time [s]",
        # ylabel="Voltage [V]",
        xmin = 58, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[7], "thick", style = {"dotted"}}, Table({x = "x", y = "y"}, x = v130_exp70[:,"Test_Time(s)"], y = v130_exp70[:,"Voltage(V)"])),
    LegendEntry("210 kPa Experimental"),
    PGFPlotsX.Plot({color = Ϟ[8]}, Table({x = "x", y = "y"}, x = v130[0.7][2], y = v130[0.7][1])),
    LegendEntry("210 kPa Pressure Fitted ECM"),
    PGFPlotsX.Plot({color = Ϟ[6]}, Table({x = "x", y = "y"}, x = v25[0.7][2], y = v25[0.7][1])),
    LegendEntry("40 kPa Pressure Fitted ECM"),


)

pgfsave("figures/Pmod1_plot.pdf", P_plot, include_preamble = false)

pgfsave("figures/Errmod1_plot.pdf", Error_plot, include_preamble = false)

Error_plot = @pgf GroupPlot(

    {
        # group_style =
        # {
        #     group_size = "2 by 1",
        #     xticklabels_at="edge bottom",
        # },
        height = "8cm", width = "10cm",
        


    },

    {
        xlabel="SOC",
        ylabel="Error [V]",
        legend_pos= "outer north east",
        # xmin = 58, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # ytick = 0:0.01:0.2,
        # xtick = 0:10:100,
    },
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style = {"dotted"}}, Table({x = "x", y = "y"}, x = x0[:,"SOC"], y = x0[:,"Error"])),
    LegendEntry("0 kPa 1RC"),
    PGFPlotsX.Plot({color = Ϟ[7]}, Table({x = "x", y = "y"}, x = x0_2RC[:,"SOC"], y = x0_2RC[:,"Error"])),
    LegendEntry("0kPa 2RC"),

    PGFPlotsX.Plot({color = Ϟ[6], "thick", style = {"dotted"}}, Table({x = "x", y = "y"}, x = x50[:,"SOC"], y = x50[:,"Error"])),
    LegendEntry("50kPa 1RC"),
    PGFPlotsX.Plot({color = Ϟ[6]}, Table({x = "x", y = "y"}, x = x50_2RC[:,"SOC"], y = x50_2RC[:,"Error"])),
    LegendEntry("50kPa 2RC"),

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style = {"dotted"}}, Table({x = "x", y = "y"}, x = x100[:,"SOC"], y = x100[:,"Error"])),
    LegendEntry("210kPa 1RC"),
    PGFPlotsX.Plot({color = Ϟ[8]}, Table({x = "x", y = "y"}, x = x100_2RC[:,"SOC"], y = x100_2RC[:,"Error"])),
    LegendEntry("100kPa 2RC"),

)