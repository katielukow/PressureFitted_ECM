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

soc = 0.9
mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1);
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1);
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1);

mbpf0kpa_1 = hppc_fun(P0kpa, soc*100, 5, 1, 19, 21, 1);
mbpf50kpa_1 = hppc_fun(mbpf50kpa, soc*100, 5, 1, 19, 21, 1);
mbpf100kpa_1 = hppc_fun(mbpf100kpa, soc*100, 5, 1, 19, 21, 1);

# Dictionary of data
mod1_dic = Dict(    
    "mbpf25kpa" => mbpf25kpa,
    "mbpf40kpa" => mbpf40kpa,
    "mbpf130kpa" => mbpf130kpa,
);

mod2_dic = Dict(
    "mbpf0kpa" => P0kpa,
    "mbpf50kpa" => mbpf50kpa,
    "mbpf100kpa" => mbpf100kpa,
);



v25,x25, err25 = soc_loop(mbpf25kpa, 0.5, 0.5, 3.7, ocv1, 17, 19, 10);
v40,x40, err40 = soc_loop(mbpf40kpa, 1.0, 0.1, 3.7, ocv1, 20, 22, 10);
# v130,x130, err130 = soc_loop(mbpf130kpa, 1.0, 0.1, 3.7, ocv1, 20, 22, 10);
# v0,x0, err0 = soc_loop(P0kpa, 1.0, 0.1, 5.5, ocv2, 19, 21, 5);
# v50,x50, err50 = soc_loop(mbpf50kpa, 1.0, 0.1, 5.5, ocv2, 19, 21, 5);
# v100,x100, err100 = soc_loop(mbpf100kpa, 1.0, 0.1, 5.5, ocv2, 19, 21, 5);


# err25_40 = incorrect_pres(v25, mbpf40kpa, 20, 22, 10)
# err25_130 = incorrect_pres(v25, mbpf130kpa, 20, 22, 10)
# err0_50 = incorrect_pres(v0, mbpf50kpa, 19, 21, 5)
# err0_100 = incorrect_pres(v0, mbpf100kpa, 19, 21, 5)





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

RCR0_plot = @pgf GroupPlot(

    {
        group_style =
        {
            group_size = "3 by 2",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            horizontal_sep = "2cm",
            vertical_sep = "1cm"
        },
        height = "10cm", width = "15cm",
        legend_pos= "north east"


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

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x40[:,"SOC"].*100, y = x40[:,"R0"])),
    LegendEntry("40 kPa"),
    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25[:,"SOC"].*100, y = x25[:,"R0"])),
    LegendEntry("130 kPa"),
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x130[:,"SOC"].*100, y = x130[:,"R0"])),
    LegendEntry("200 kPa"),
    {
        # xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R1",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x40[:,"SOC"].*100, y = x40[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25[:,"SOC"].*100, y = x25[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x130[:,"SOC"].*100, y = x130[:,"R1"])),

    {
        # xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter C1",

        ytick = 0:1000:6000
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[5], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x40[:,"SOC"].*100, y = x40[:,"C1"])),
    PGFPlotsX.Plot({color = Ϟ[6], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x25[:,"SOC"].*100, y = x25[:,"C1"])),
    PGFPlotsX.Plot({color = Ϟ[7], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x130[:,"SOC"].*100, y = x130[:,"C1"])),

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

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x0[:,"SOC"].*100, y = x0[:,"R0"])),
    LegendEntry("0 kPa"),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50[:,"SOC"].*100, y = x50[:,"R0"])),
    LegendEntry("50 kPa"),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x100[:,"SOC"].*100, y = x100[:,"R0"])),
    LegendEntry("100 kPa"),
    {
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter R1",
        # xmin = -0.1, 
        # xmax = 65,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x0[:,"SOC"].*100, y = x0[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50[:,"SOC"].*100, y = x50[:,"R1"])),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x100[:,"SOC"].*100, y = x100[:,"R1"])),

    {
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Parameter C1",

        ytick = 0:2000:50000
        # xtick = 0:10:100,
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x0[:,"SOC"].*100, y = x0[:,"C1"])),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x50[:,"SOC"].*100, y = x50[:,"C1"])),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", style ={"dashed"}}, Table({x = "x", y = "y"}, x = x100[:,"SOC"].*100, y = x100[:,"C1"])),
)

# pgfsave("figures/fit_plot.pdf", fit_plot, include_preamble = false)
# pgfsave("figures/RCR0_plot.pdf", RCR0_plot, include_preamble = false)



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
