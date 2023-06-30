using PIECM, Plots, Statistics, PGFPlotsX, LaTeXStrings

plotly()
Ϟ = distinguishable_colors(10)

# --------------- Data Import ------------------------------
function data_imp(hppc_file, pres_file, Acell)
    
    cd = data_import_csv(hppc_file)
    A_cell = Acell[1] * Acell[2]
    pd = pressure_dateformat_fix(pres_file)
    data = pressurematch(cd, pd, A_cell)
    
    return sort!(data,["Date_Time"])

end

function pres_avg(pres_file, data, Area, digits)
    p = pressure_dateformat_fix(pres_file)
    return round(mean(filter(!ismissing, pressurematch(data, p, Area[1] * Area[2])[:,"Pressure"]))/1000, digits=digits)
end

mbpf200kpa = data_import_csv("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.csv", "old")
mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")

mbpf_0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", "new")
mbpf_50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
mbpf_100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.csv", "new")

# ---------------- DCIR and Power Calculations -------------------------
# Outputs dictionary of calculated values for DC internal resistance and power values at each SOC point
# Two dictionary keys, Discharge and Charge
dcir_25kpa_1 = HPPC(mbpf25kpa, 10, 1, 17, 19, 22, 6, 13)
dcir_40kpa_1 = HPPC(mbpf40kpa, 10, 1, 20, 22, 25, 6, 13)
dcir_130kpa_1 = HPPC(mbpf130kpa, 10, 1, 20, 22, 25, 6, 13)

dcir_0kpa_1 = HPPC(mbpf_0kpa, 5, 1, 19, 21, 24, 5, 15)
dcir_50kpa_1 = HPPC(mbpf_50kpa, 5, 1, 19, 21, 24, 5, 15)
dcir_100kpa_1 = HPPC(mbpf_100kpa, 5, 1, 19, 21, 24, 5, 15)

dcir_0kpa_21 = HPPC(mbpf_0kpa, 5, 21, 54, 56, 59, 50, 13)
dcir_50kpa_21 = HPPC(mbpf_50kpa, 5, 21, 54, 56, 59, 50, 13)
dcir_100kpa_21 = HPPC(mbpf_100kpa, 5, 21, 54, 56, 59, 50, 13)

dcir_0kpa_41 = HPPC(mbpf_0kpa, 5, 41, 54, 56, 59, 50, 13)
dcir_50kpa_41 = HPPC(mbpf_50kpa, 5, 41, 54, 56, 59, 50, 13)
dcir_100kpa_41 = HPPC(mbpf_100kpa, 5, 41, 54, 56, 59, 50, 13)

dcir_0kpa_61 = HPPC(mbpf_0kpa, 5, 61, 54, 56, 59, 50, 13)
dcir_50kpa_61 = HPPC(mbpf_50kpa, 5, 61, 54, 56, 59, 50, 13)
dcir_100kpa_61 = HPPC(mbpf_100kpa, 5, 61, 54, 56, 59, 50, 13)

# ------------------- HPPC Pulse Functions ---------------------------------
# Filters HPPC data based on a specific SOC point, currently must be a multiple of the SOC soc_increment
soc = .1
celldim = [0.128, 0.036]

mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf40kpa_2 = hppc_fun(mbpf40kpa, [20,10], 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)

ocv = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)

dig=0
P_25kpa = pres_avg("data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv",mbpf25kpa_1,celldim,dig)
P_40kpa = pres_avg("data/PressureData/230321_PressureTest_11_0048.csv",mbpf40kpa_1,celldim,dig)
P_130kpa = pres_avg("data/PressureData/230321_PressureTest_11_0044.csv",mbpf130kpa_1,celldim,dig)


# ---------------- Pressure Plotting --------------------------------------
P25kpa = data_imp("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv","data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv", celldim)
P40kpa = data_imp("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "data/PressureData/230321_PressureTest_11_0048.csv", celldim)
P130kpa = data_imp("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv","data/PressureData/230321_PressureTest_11_0044.csv",celldim)

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

dcir_step = 32
R_0kpa = filter(row -> row."Step Index" == dcir_step, mbpf_0kpa)
R_50kpa = filter(row -> row."Step Index" == dcir_step, mbpf_50kpa)
R_100kpa = filter(row -> row."Step Index" == dcir_step, mbpf_100kpa)


scatter(R_0kpa[:,"Cycle Index"], R_0kpa[:,"Internal Resistance (Ohm)"])
scatter!(R_50kpa[:,"Cycle Index"], R_50kpa[:,"Internal Resistance (Ohm)"])
scatter!(R_100kpa[:,"Cycle Index"], R_100kpa[:,"Internal Resistance (Ohm)"])


scatter(dcir_0kpa_1["Discharge"][:,"SOC"], dcir_0kpa_1["Discharge"][:,"Resistance"].*1000, label="0kpa Cycle 1", legend=false)
scatter!(dcir_50kpa_1["Discharge"][:,"SOC"], dcir_50kpa_1["Discharge"][:,"Resistance"].*1000, label="50kpa Cycle 1")
scatter!(dcir_100kpa_1["Discharge"][:,"SOC"], dcir_100kpa_1["Discharge"][:,"Resistance"].*1000, label="100kpa Cycle 1")

scatter!(dcir_0kpa_21["Discharge"][:,"SOC"], dcir_0kpa_21["Discharge"][:,"Resistance"].*1000, label="0kpa Cycle 21")
scatter!(dcir_50kpa_21["Discharge"][:,"SOC"], dcir_50kpa_21["Discharge"][:,"Resistance"].*1000, label="50kpa Cycle 21")
scatter!(dcir_100kpa_21["Discharge"][:,"SOC"], dcir_100kpa_21["Discharge"][:,"Resistance"].*1000, label="100kpa Cycle 21")

scatter!(dcir_0kpa_41["Discharge"][:,"SOC"], dcir_0kpa_41["Discharge"][:,"Resistance"].*1000, label="0kpa Cycle 41")
scatter!(dcir_50kpa_41["Discharge"][:,"SOC"], dcir_50kpa_41["Discharge"][:,"Resistance"].*1000, label="50kpa Cycle 41")
scatter!(dcir_100kpa_41["Discharge"][:,"SOC"], dcir_100kpa_41["Discharge"][:,"Resistance"].*1000, label="100kpa Cycle 41")

scatter!(dcir_0kpa_61["Discharge"][:,"SOC"], dcir_0kpa_61["Discharge"][:,"Resistance"].*1000, label="0kpa Cycle 61")
scatter!(dcir_50kpa_61["Discharge"][:,"SOC"], dcir_50kpa_61["Discharge"][:,"Resistance"].*1000, label="50kpa Cycle 61")
scatter!(dcir_100kpa_61["Discharge"][:,"SOC"], dcir_100kpa_61["Discharge"][:,"Resistance"].*1000, label="100kpa Cycle 61")



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
        height = "10cm", width = "15cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Resistance [mΩ]",
        xmin = 0, 
        xmax = 100,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "north east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_0kpa_1["Discharge"][:,"SOC"], y = dcir_0kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry("0 kPa"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_50kpa_1["Discharge"][:,"SOC"], y = dcir_50kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry("50 kPa"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = dcir_100kpa_1["Discharge"][:,"SOC"], y = dcir_100kpa_1["Discharge"][:,"Resistance"].*1000)),
    LegendEntry("100 kPa")

)

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
        legend_pos= "north east"

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
        legend_pos= "east"
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

