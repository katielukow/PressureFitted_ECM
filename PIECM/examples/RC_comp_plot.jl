using PIECM, PGFPlotsX
Ϟ = distinguishable_colors(20)

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


# # ECM param fitting
v40, x40, error_40 =  soc_loop(mbpf40kpa, 1.0, 0.1, Q40, ocv1, 20, 22, 10);
v25, x25, error_25 = soc_loop(mbpf25kpa, 1, 0.1, Q25, ocv1,  17, 19, 10);
v130, x130, error_130 = soc_loop(mbpf130kpa, 1, 0.1, Q130, ocv1, 20, 22, 10);

v0, x0, error_0 = soc_loop(P0kpa, 1, 0.1, Q0, ocv2, 19, 21, 5);
v50, x50, error_50 = soc_loop(mbpf50kpa, 1, 0.1, Q50, ocv2, 19, 21, 5);
v100, x100, error_100 = soc_loop(mbpf100kpa, 1, 0.1, Q100, ocv2, 19, 21, 5);

# # # ECM param fitting 2RC
v40_2RC, x40_2RC, error_40_2RC = soc_loop_2RC(mbpf40kpa, 1, 0.1, Q40, ocv1, 20, 22, 10);
v25_2RC, x25_2RC, error_25_2RC = soc_loop_2RC(mbpf25kpa, 1, 0.1, Q25, ocv1, 17, 19, 10);
v130_2RC, x130_2RC, error_130_2RC = soc_loop_2RC(mbpf130kpa, 1, 0.1, Q130, ocv1, 20, 22, 10);

v0_2RC, x0_2RC, error_0_2RC = soc_loop_2RC(P0kpa, 1, 0.1, Q0, ocv2, 19, 21, 5);
v50_2RC, x50_2RC, error_50_2RC = soc_loop_2RC(mbpf50kpa, 1, 0.1, Q50, ocv2, 19, 21, 5);
v100_2RC, x100_2RC, error_100_2RC = soc_loop_2RC(mbpf100kpa, 1.0, 0.1, Q100, ocv2, 19, 21, 5);

j = 0.2
hppc_40kpa_90 = hppc_fun(mbpf40kpa, j*100,10,20,1)
hppc_25kpa_90 = hppc_fun(mbpf25kpa, j*100,10,17, 1)
hppc_130kpa_90 = hppc_fun(mbpf130kpa, j*100,10,20, 1)

hppc_0kpa_90 = hppc_fun(P0kpa, j*100,5,19, 1)
hppc_50kpa_90 = hppc_fun(mbpf50kpa, j*100,5,19, 1)
hppc_100kpa_90 = hppc_fun(mbpf100kpa, j*100,5,19, 1)

mod1_plot = @pgf Axis(

    {
        height = "7cm", width = "10cm",    
        xlabel="Time [s]",
        ylabel="Voltage [V]",
        # xmin = 0, 
        # xmax = 100,
        # ymax = 15,
        # ymin = 10,
        # xtick = 0:10:100,
        legend_pos= "south east"
    },

    PGFPlotsX.Plot({color = "black", "thick", dashed}, Table({x = "x", y = "y"}, x = hppc_40kpa_90[2:end,"Test_Time(s)"], y = hppc_40kpa_90[2:end,"Voltage(V)"])),
    LegendEntry("47 kPa Experimental"),
    # PGFPlotsX.Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = hppc_130kpa_90[2:end,"Test_Time(s)"], y = hppc_130kpa_90[2:end,"Voltage(V)"])),
    # LegendEntry("210 kPa Experimental"),
    PGFPlotsX.Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = v40[j][2][2:end], y = v40[j][1][2:end])),
    LegendEntry("47 kPa Pressure Fitted ECM"),
    PGFPlotsX.Plot({color = Ϟ[14], "thick"}, Table({x = "x", y = "y"}, x = v130[j][2][2:end], y = v130[j][1][2:end])),
    LegendEntry("210 kPa Pressure Fitted ECM"),

)
pgfsave("mod1_20soc_plot.pdf", mod1_plot)

err1_plot = @pgf Axis(

    {
        height = "10cm", width = "12cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Error [V"*L"$^2$"*"]",
        # xmin = 0, 
        # xmax = 100,
        # ymax = 15,
        # ymin = 10,
        # xtick = 0:10:100,
        legend_pos= "outer north east"
    },

    PGFPlotsX.Plot({color = Ϟ[8], "thick", dashed}, Table({x = "x", y = "y"}, x = x40.SOC[1:end-1], y = x40.Error[1:end-1])),
    LegendEntry("47 kPa 1RC"),
    # PGFPlotsX.Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = x0_2RC.SOC[1:end-1], y = x0_2RC.Error[1:end-1])),
    # LegendEntry("0 kPa 2RC"),
    PGFPlotsX.Plot({color = Ϟ[10], "thick", dashed}, Table({x = "x", y = "y"}, x = x25.SOC[1:end-1], y = x25.Error[1:end-1])),
    LegendEntry("140 kPa 1RC"),
    # PGFPlotsX.Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = x50_2RC.SOC[1:end-1], y = x50_2RC.Error[1:end-1])),
    # LegendEntry("50 kPa 2RC"),
    PGFPlotsX.Plot({color = Ϟ[14], "thick", dashed}, Table({x = "x", y = "y"}, x = x130.SOC[1:end-1], y = x130.Error[1:end-1])),
    LegendEntry("210 kPa 1RC"),
    # PGFPlotsX.Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = x100_2RC.SOC[1:end-1], y = x100_2RC.Error[1:end-1])),
    # LegendEntry("100 kPa 2RC"),


)
pgfsave("Errmod1_plot1RC.pdf", err1_plot)

# R0_1_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R0",
#         xmin = 0, 
#         xmax = 101,
#         xtick = 0:10:100,
#         legend_pos= "south west",
#         font = raw"\Large",
#     },
 
#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0.SOC .* 100, y = x0.R0)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50.SOC .* 100, y = x50.R0)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100.SOC .* 100, y = x100.R0)),
#     LegendEntry("100 kPa"),

# )

# R1_1_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west",
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0.SOC .* 100, y = x0.R1)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50.SOC .* 100, y = x50.R1)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100.SOC .* 100, y = x100.R1)),
#     LegendEntry("100 kPa"),

# )

# C1_1_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter C1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0.SOC .* 100, y = x0.C1)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50.SOC .* 100, y = x50.C1)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100.SOC .* 100, y = x100.C1)),
#     LegendEntry("100 kPa"),

# )

# pgfsave("R0_1_plot.pdf", R0_1_plot)
# pgfsave("R1_1_plot.pdf", R1_1_plot)
# pgfsave("C1_1_plot.pdf", C1_1_plot)

# R0_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R0",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40.SOC .* 100, y = x40.R0)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25.SOC .* 100, y = x25.R0)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130.SOC .* 100, y = x130.R0)),
#     LegendEntry("210 kPa"),

# )

# R1_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40.SOC .* 100, y = x40.R1)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25.SOC .* 100, y = x25.R1)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130.SOC .* 100, y = x130.R1)),
#     LegendEntry("210 kPa"),

# )

# C1_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter C1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40.SOC .* 100, y = x40.C1)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25.SOC .* 100, y = x25.C1)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130.SOC .* 100, y = x130.C1)),
#     LegendEntry("210 kPa"),

# )

# pgfsave("R0_2_plot.pdf", R0_2_plot)
# pgfsave("R1_2_plot.pdf", R1_2_plot)
# pgfsave("C1_2_plot.pdf", C1_2_plot)


# R0_2_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R0",
#         xmin = 0, 
#         xmax = 101,
#         ymax = .013,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40_2RC.SOC .* 100, y = x40_2RC.R0)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25_2RC.SOC .* 100, y = x25_2RC.R0)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130_2RC.SOC .* 100, y = x130_2RC.R0)),
#     LegendEntry("210 kPa"),

# )

# R1_2_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40_2RC.SOC .* 100, y = x40_2RC.R1)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25_2RC.SOC .* 100, y = x25_2RC.R1)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130_2RC.SOC .* 100, y = x130_2RC.R1)),
#     LegendEntry("210 kPa"),

# )

# C1_2_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter C1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40_2RC.SOC .* 100, y = x40_2RC.C1)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25_2RC.SOC .* 100, y = x25_2RC.C1)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130_2RC.SOC .* 100, y = x130_2RC.C1)),
#     LegendEntry("210 kPa"),

# )

# R2_2_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R2",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40_2RC.SOC .* 100, y = x40_2RC.R2)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25_2RC.SOC .* 100, y = x25_2RC.R2)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130_2RC.SOC .* 100, y = x130_2RC.R2)),
#     LegendEntry("210 kPa"),

# )

# C2_2_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter C2",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[8], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x40_2RC.SOC .* 100, y = x40_2RC.C2)),
#     LegendEntry("47 kPa"),
#     Plot({color = Ϟ[10], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x25_2RC.SOC .* 100, y = x25_2RC.C2)),
#     LegendEntry("140 kPa"),
#     Plot({color = Ϟ[14], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x130_2RC.SOC .* 100, y = x130_2RC.C2)),
#     LegendEntry("210 kPa"),

# )

# pgfsave("R0_2_2_plot.pdf", R0_2_2_plot)
# pgfsave("R1_2_2_plot.pdf", R1_2_2_plot)
# pgfsave("C1_2_2_plot.pdf", C1_2_2_plot)
# pgfsave("R2_2_2.pdf", R2_2_2_plot)
# pgfsave("C2_2_2.pdf", C2_2_2_plot)


# R0_1_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R0",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = .013,
#         xtick = 0:10:100,
#         legend_pos= "south west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0_2RC.SOC .* 100, y = x0_2RC.R0)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50_2RC.SOC .* 100, y = x50_2RC.R0)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100_2RC.SOC .* 100, y = x100_2RC.R0)),
#     LegendEntry("100 kPa"),

# )

# R1_1_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0_2RC.SOC .* 100, y = x0_2RC.R1)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50_2RC.SOC .* 100, y = x50_2RC.R1)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100_2RC.SOC .* 100, y = x100_2RC.R1)),
#     LegendEntry("100 kPa"),

# )

# C1_1_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter C1",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0_2RC.SOC .* 100, y = x0_2RC.C1)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50_2RC.SOC .* 100, y = x50_2RC.C1)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100_2RC.SOC .* 100, y = x100_2RC.C1)),
#     LegendEntry("100 kPa"),

# )

# R2_1_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter R2",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0_2RC.SOC .* 100, y = x0_2RC.R2)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50_2RC.SOC .* 100, y = x50_2RC.R2)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100_2RC.SOC .* 100, y = x100_2RC.R2)),
#     LegendEntry("100 kPa"),

# )

# C2_1_2_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Parameter C2",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north west", 
#         font = raw"\Large",
#     },

#     Plot({color = Ϟ[7], "thick", mark="square*"}, Table({x = "x", y = "y"}, x = x0_2RC.SOC .* 100, y = x0_2RC.C2)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", mark="*"}, Table({x = "x", y = "y"}, x = x50_2RC.SOC .* 100, y = x50_2RC.C2)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", mark="triangle*"}, Table({x = "x", y = "y"}, x = x100_2RC.SOC .* 100, y = x100_2RC.C2)),
#     LegendEntry("100 kPa"),

# )

# pgfsave("R0_1_2_plot.pdf", R0_1_2_plot)
# pgfsave("R1_1_2_plot.pdf", R1_1_2_plot)
# pgfsave("C1_1_2_plot.pdf", C1_1_2_plot)
# pgfsave("R2_1_2.pdf", R2_1_2_plot)
# pgfsave("C2_1_2.pdf", C2_1_2_plot)