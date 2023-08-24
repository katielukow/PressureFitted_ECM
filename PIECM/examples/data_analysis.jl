using PIECM, Plots, Statistics, PGFPlotsX, LaTeXStrings

plotly()
Ϟ = distinguishable_colors(10)

# --------------- Data Import ------------------------------
function data_imp(hppc_file, pres_file, Acell)
    
    cd = data_import_csv(hppc_file, "old")
    A_cell = Acell[1] * Acell[2]
    pd = pressure_dateformat_fix(pres_file)
    data = pressurematch(cd, pd, A_cell)
    
    return sort!(data,["Date_Time"])

end

function pres_avg(pres_file, data, Area, digits)
    p = pressure_dateformat_fix(pres_file)
    return round(mean(filter(!ismissing, pressurematch(data, p, Area[1] * Area[2])[:,"Pressure"]))/1000, digits=digits)
end

mbpf140kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
mbpf200kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")

celldim = [0.128, 0.036]
A_cell = celldim[1] * celldim[2]
Pres40 = pressure_dateformat_fix("data/PressureData/230321_PressureTest_11_0048.csv")
P40kpa = pressurematch(mbpf40kpa, Pres40, A_cell)
p40_discharge = sort!(filter(row -> row.Step_Index == 6, P40kpa), [:Date_Time])

Pres200 = pressure_dateformat_fix("data/PressureData/230321_PressureTest_11_0044.csv")
P200kpa = pressurematch(mbpf200kpa, Pres200, A_cell)
p200_discharge = sort!(filter(row -> row.Step_Index == 6, P200kpa), [:Date_Time])

Pres40 = pressure_dateformat_fix("data/PressureData/230321_PressureTest_11_0048.csv")
P40kpa = pressurematch(mbpf40kpa, Pres40, A_cell)
p40_discharge = sort!(filter(row -> row.Step_Index == 6, P40kpa), [:Date_Time])

plot(p40_discharge[:,"Date_Time"], p40_discharge[:,"Pressure"])
plot(p200_discharge[:,"Date_Time"], p200_discharge[:,"Pressure"])

k=1
p40_plot = Array{Float64}(undef, 10, 2)
p_temp = filter(row -> row.Cycle_Index == 1, P40kpa)
for i in 0:9
    p = filter(row -> row.Step_Index == 25 && row.TC_Counter1 == i, p_temp)
    p40_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
    p40_plot[k,2] = 100 - (i+1) * 5
    k += 1
end

k=1
p200_plot = Array{Float64}(undef, 10, 2)
p_temp = filter(row -> row.Cycle_Index == 1, P200kpa)
for i in 0:9
    p = filter(row -> row.Step_Index == 25 && row.TC_Counter1 == i, p_temp)
    p200_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
    p200_plot[k,2] = 100 - (i+1) * 5
    k += 1
end


dig=0
P_25kpa = pres_avg("data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv",mbpf25kpa_1,celldim,dig)
P_40kpa = pres_avg("data/PressureData/230321_PressureTest_11_0048.csv",mbpf40kpa_1,celldim,dig)
P_130kpa = pres_avg("data/PressureData/230321_PressureTest_11_0044.csv",mbpf130kpa_1,celldim,dig)


# ---------------- DCIR and Power Calculations -------------------------
# Outputs dictionary of calculated values for DC internal resistance and power values at each SOC point
# Two dictionary keys, Discharge and Charge
dcir_25kpa_1 = HPPC(mbpf25kpa, 10, 1, 17, 19, 22, 6, 13)
dcir_40kpa_1 = HPPC(mbpf40kpa, 10, 1, 20, 22, 25, 6, 13)
dcir_130kpa_1 = HPPC(mbpf130kpa, 10, 1, 20, 22, 25, 6, 13)

# ------------------- HPPC Pulse Functions ---------------------------------
# Filters HPPC data based on a specific SOC point, currently must be a multiple of the SOC soc_increment
soc = 1


mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf40kpa_2 = hppc_fun(mbpf40kpa, [20,10], 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)

ocv = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)



# ---------------- Pressure Plotting --------------------------------------
P25kpa = data_imp("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv","data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv", celldim)
P40kpa = data_imp("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "data/PressureData/230321_PressureTest_11_0048.csv", celldim)
P130kpa = data_imp("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv","data/PressureData/230321_PressureTest_11_0044.csv",celldim)

p_plot = Array{Float64}(undef, 10)
k = 1
for i in 10:10:100
    println(i)
    p = hppc_fun(P130kpa, i, 10, 1, 17, 19, 1)
    p_plot[k] = mean(skipmissing(p[:,"Pressure"]))
    k += 1
end

plot(p_plot)

# P25kpa = pressure_dateformat_fix("data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv")
# P40kpa = pressure_dateformat_fix("data/PressureData/230321_PressureTest_11_0048.csv")
# P130kpa = pressure_dateformat_fix("data/PressureData/230321_PressureTest_11_0044.csv")

char_step = 10
dis_step = 6

P25kpa_charge = sort!(filter(row -> row.Step_Index == dis_step, P25kpa)) 
P40kpa_charge = sort!(filter(row -> row.Step_Index == dis_step, P40kpa)) 
P130kpa_charge = sort!(filter(row -> row.Step_Index == dis_step, P130kpa)) 

P25kpa_norm = P25kpa_charge[:,"Pressure"] ./ P25kpa_charge[1,"Pressure"]
P40kpa_norm = P40kpa_charge[:,"Pressure"] ./ P40kpa_charge[3,"Pressure"]
P130kpa_norm = P130kpa_charge[:,"Pressure"] ./ P130kpa_charge[1,"Pressure"]

P25kpa_norm2 = P25kpa_charge[:,"Pressure"] .- P25kpa_charge[1,"Pressure"]
P40kpa_norm2 = P40kpa_charge[:,"Pressure"] .- P40kpa_charge[3,"Pressure"]
P130kpa_norm2 = P130kpa_charge[:,"Pressure"] .- P130kpa_charge[1,"Pressure"]


# ------------------Plots------------------------
scatter(P40kpa_charge[:,:Pressure], label = string(P_25kpa))
scatter!(P25kpa_charge[:,:Pressure], label = string(P_40kpa))
scatter!(P130kpa_charge[:,:Pressure], label = string(P_130kpa))

scatter!(twinx(), P130kpa_charge[:,"Voltage(V)"])


Ω_plot = @pgf Axis(

    # {
    #     height = "10cm", width = "15cm",
    #     legend_pos= "south east",
    # },

    {
        height = "7cm", width = "15cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Resistance [mΩ]",
        xmin = 0, 
        xmax = 100,
        ymax = 15,
        ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south west"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_40kpa_1["Discharge"][:,"SOC"], y = dcir_40kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry("50 kPa"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_25kpa_1["Discharge"][:,"SOC"], y = dcir_25kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry("140 kPa"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_130kpa_1["Discharge"][:,"SOC"], y = dcir_130kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry("200 kPa")

)

pgfsave("figures/Rold_plot.pdf", Ω_plot, include_preamble = false)
Pwr_plot = @pgf GroupPlot(

    {
        group_style =
        {
            # group_size="2 by 1",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "north west"
        },
        height = "10cm", width = "15cm",
        legend_pos= "south east",
        # legend_style =
        # {
        #     at = Coordinate(1.1, 0.5),
        #     anchor = "east",
        #     legend_columns = 1
        # },
        legend_pos= "north east"

    },

    {
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Max Power [W]",
        xmin = 10, 
        xmax = 100,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = dcir_40kpa_1["Discharge"][:,"SOC"], y = -dcir_40kpa_1["Discharge"][:,"Max Power (W)"])),
    LegendEntry("47 kPa"),
    Plot({color = Ϟ[6], "thick", mark = "*"}, Table({x = "x", y = "y"}, x = dcir_25kpa_1["Discharge"][:,"SOC"], y = -dcir_25kpa_1["Discharge"][:,"Max Power (W)"])),
    LegendEntry("139 kPa"),
    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = dcir_130kpa_1["Discharge"][:,"SOC"], y = -dcir_130kpa_1["Discharge"][:,"Max Power (W)"])),
    LegendEntry("211 kPa"),

)

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
        legend_pos= "south east",
        # legend_style =
        # {
        #     at = Coordinate(1.1, 0.5),
        #     anchor = "east",
        #     legend_columns = 1
        # },
        # legend_pos= "north east"

    },

    {
        xlabel="Time [s]",
        ylabel="Pressure [kPa]",
        xmin = 0, 
        # xmax = 100,
        # ymax = 15,
        ymin = 0,
        # xtick = 0:10:100,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
        # legend_pos= "east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = P40kpa_charge[:,"Step_Time(s)"], y = P40kpa_charge[:,:Pressure]/1000)),
    LegendEntry("47 kPa"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = P25kpa_charge[:,"Step_Time(s)"], y = P25kpa_charge[:,:Pressure]/1000)),
    LegendEntry("139 kPa"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = P130kpa_charge[:,"Step_Time(s)"], y = P130kpa_charge[:,:Pressure]/1000)),
    LegendEntry("211 kPa"),

)

PT_plot = @pgf GroupPlot(

    {
        group_style =
        {
            group_size="3 by 1",
            xticklabels_at="edge bottom",
            horizontal_sep="2cm"
            # yticklabels_at="edge left",
            # legend_pos= "north west"
        },
        height = "10cm", width = "15cm",
        legend_pos= "south east",
        # legend_style =
        # {
        #     at = Coordinate(1.1, 0.5),
        #     anchor = "east",
        #     legend_columns = 1
        # },
        legend_pos= "north east"

    },

    {
        xlabel="Time [s]",
        ylabel="Current [A]",
        xmin = 0, 
        # xmax = 100,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = P25kpa_charge[:,"Step_Time(s)"], y = P25kpa_charge[:,"Current(A)"])),
    LegendEntry("Current"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = P25kpa_charge[:,"Step_Time(s)"], y = P25kpa_charge[:,"Voltage(V)"])),
    LegendEntry("Voltage"),

    {
        xlabel="Time [s]",
        ylabel="Pressure [kPa]",
        xmin = 0, 
        # xmax = 100,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = P25kpa_charge[:,"Step_Time(s)"], y = P25kpa_charge[:,:Pressure]/1000)),
    # LegendEntry("139 kPa"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = P130kpa_charge[:,"Step_Time(s)"], y = P130kpa_charge[:,:Pressure]/1000)),
    # LegendEntry("211 kPa"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = P40kpa_charge[:,"Step_Time(s)"], y = P40kpa_charge[:,:Pressure]/1000)),
    # LegendEntry("211 kPa"),


    {
        xlabel="Time [s]",
        ylabel="Temperature [Celsius]",
        xmin = 0, 
        # xmax = 100,
        # ymax = 15,
        # ymin = 0,
        # xtick = 0:10:100,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = P25kpa_charge[:,"Step_Time(s)"], y = P25kpa_charge[:,"Aux_Temperature_1(C)"])),
    LegendEntry("139 kPa"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = P130kpa_charge[:,"Step_Time(s)"], y = P130kpa_charge[:,"Aux_Temperature_1(C)"])),
    LegendEntry("211 kPa"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = P40kpa_charge[:,"Step_Time(s)"], y = P40kpa_charge[:,"Aux_Temperature_1(C)"])),
    LegendEntry("47 kPa"),
    # Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = P130kpa_charge[:,"Step_Time(s)"], y = P130kpa_charge[:,:Pressure]/1000)),
    # LegendEntry("211 kPa"),

)

hppc_voltage_plot = @pgf GroupPlot(
    {
        group_style = {       

            group_size="1 by 2",
            xticklabels_at="edge bottom",
            vertical_sep="0.5cm"

        },

        height = "6cm", width = "16cm",
        # legend_pos= "south east"
        # legend_style =
        # {
        #     at = Coordinate(1.1, 0.5),
        #     anchor = "east",
        #     legend_columns = 1
        # },

    },

    {
        ylabel=" Voltage [V]",
        # xlabel="Time [s]",
        xmin = -0.1, 
        xmax = 100,
        ymax = 4.0,
        ymin = 2.8,
        # xtick = 0:10:100,
        ytick = 2.8:0.2:4.0,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = mbpf40kpa_1[:, "Test_Time(s)"], y = mbpf40kpa_1[:, "Voltage(V)"])),

    {
        ylabel=" Current [A]",
        xlabel="Time [s]",
        xmin = -0.1, 
        xmax = 100,
        ymax = 15,
        ymin = -60,
        # xtick = 0:10:100,
        # ytick = 0:0.002:0.016,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
    },

    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf40kpa_1[:, "Test_Time(s)"], y = mbpf40kpa_1[:, "Current(A)"])),


 
 
)

ocv_plot = @pgf GroupPlot(

    {
        # group_style =
        # {
        #     group_size="1 by 1",
        #     xticklabels_at="edge bottom",
        #     horizontal_sep="2cm"
        #     # yticklabels_at="edge left",
        #     # legend_pos= "north west"
        # },
        height = "6cm", width = "16cm",
        # legend_pos= "south east",
        # legend_style =
        # {
        #     at = Coordinate(1.1, 0.5),
        #     anchor = "east",
        #     legend_columns = 1
        # },
        # legend_pos= "north east"

    },

    {
        xlabel="State of Charge",
        ylabel="Voltage [V]",
        xmin = 0, 
        xmax = 100,
        ymax = 4.4,
        ymin = 3,
        xtick = 0:10:100,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
        # legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = ocv[:,"State_of_Charge"].*100, y = ocv[:,"DischargeVoltage"])),




)

