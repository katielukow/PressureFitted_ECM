using PIECM, Plots, Statistics, PGFPlotsX, LaTeXStrings

plotly()
Ϟ = distinguishable_colors(10)

# --------------- Data Import ------------------------------
function data_imp(hppc_file, pres_file, Acell)
    
    cd = data_import_csv(hppc_file)
    A_cell = Acell[1] * Acell[2]
    pd = pressure_dateformat_fix(pres_file)
    return pressurematch(cd, pd, A_cell)

end

function pres_avg(pres_file, data, Area, digits)
    p = pressure_dateformat_fix(pres_file)
    return round(mean(filter(!ismissing, pressurematch(data, p, Area[1] * Area[2])[:,"Pressure"]))/1000, digits=digits)
end

mbpf200kpa = data_import_csv("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.csv")
mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv")
mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv")

# ---------------- DCIR and Power Calculations -------------------------
# Outputs dictionary of calculated values for DC internal resistance and power values at each SOC point
# Two dictionary keys, Discharge and Charge
dcir_200kpa_1 = HPPC(mbpf200kpa, 5, 1, 17, 19, 22, 6, 13)
dcir_25kpa_1 = HPPC(mbpf25kpa, 10, 1, 17, 19, 22, 6, 13)
dcir_40kpa_1 = HPPC(mbpf40kpa, 10, 1, 20, 22, 25, 6, 13)
dcir_130kpa_1 = HPPC(mbpf130kpa, 10, 1, 20, 22, 25, 6, 13)

# scatter(dcir_200kpa_1["Discharge"][:, "SOC"], dcir_200kpa_1["Discharge"][:, "Resistance"], label = "200kpa")


# ------------------- HPPC Pulse Functions ---------------------------------
# Filters HPPC data based on a specific SOC point, currently must be a multiple of the SOC soc_increment

soc = 1
celldim = [0.128, 0.036]

# mbpf200kpa_1 = hppc_fun(mbpf200kpa, soc*100, 5, 1, 17, 19, 1)
# mbpf100kpa_1 = hppc_fun(mbpf100kpa, soc*100, 5, 1, 17, 19, 1)
mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)

dig=0
P_25kpa = pres_avg("data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv",mbpf25kpa_1,celldim,dig)
P_40kpa = pres_avg("data/PressureData/230321_PressureTest_11_0048.csv",mbpf40kpa_1,celldim,dig)
P_130kpa = pres_avg("data/PressureData/230321_PressureTest_11_0044.csv",mbpf130kpa_1,celldim,dig)


soc_plot = @pgf GroupPlot(
    
    {
        group_style =
        {
            # group_size="2 by 1",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "south west"
        },
        height = "10cm", width = "15cm",
        # legend_pos= "south west"

    },

    {
        xlabel="Time [s]",
        ylabel="Voltage [V]",
        xmin = -0.01, 
        xmax = 100,
        # ymax = 4.4,
        # ymin = 2.8,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = mbpf40kpa_1[:,"Test_Time(s)"], y = mbpf40kpa_1[:,"Voltage(V)"])),
    LegendEntry(string(P_40kpa)*" kPa"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf25kpa_1[:,"Test_Time(s)"], y = mbpf25kpa_1[:,"Voltage(V)"])),
    LegendEntry(string(P_25kpa)*" kPa"),
    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[:,"Test_Time(s)"], y = mbpf130kpa_1[:,"Voltage(V)"])),
    LegendEntry(string(P_130kpa)*" kPa")
)

# pgfsave("/Users/KatieLukow/Documents/OBMS23/Figures/soc20.pdf",soc_plot)

Ω_plot = @pgf GroupPlot(
    
    {
        group_style =
        {
            # group_size="2 by 1",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "north west"
        },
        height = "10cm", width = "15cm",
        legend_pos= "north east"

    },

    {
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Resistance [mΩ]",
        xmin = 0, 
        xmax = 100,
        ymax = 15,
        ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_40kpa_1["Discharge"][:,"SOC"], y = dcir_40kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry(string(P_40kpa)*" kPa"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_25kpa_1["Discharge"][:,"SOC"], y = dcir_25kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry(string(P_25kpa)*" kPa"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_130kpa_1["Discharge"][:,"SOC"], y = dcir_130kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry(string(P_130kpa)*" kPa"),

)

# pgfsave("/Users/KatieLukow/Documents/OBMS23/Figures/dcir.pdf",Ω_plot)

P_plot = @pgf GroupPlot(
    
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
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Maximum Power [W]",
        xmin = 10, 
        xmax = 100,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = dcir_40kpa_1["Discharge"][:,"SOC"], y = abs.(dcir_40kpa_1["Discharge"][:,"Max Power (W)"]))),
    LegendEntry(string(P_40kpa)*" kPa"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = dcir_25kpa_1["Discharge"][:,"SOC"], y = abs.(dcir_25kpa_1["Discharge"][:,"Max Power (W)"]))),
    LegendEntry(string(P_25kpa)*" kPa"),
    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = dcir_130kpa_1["Discharge"][:,"SOC"], y = abs.(dcir_130kpa_1["Discharge"][:,"Max Power (W)"]))),
    LegendEntry(string(P_130kpa)*" kPa"),

)

# pgfsave("/Users/KatieLukow/Documents/OBMS23/Figures/maxpower.pdf",P_plot)