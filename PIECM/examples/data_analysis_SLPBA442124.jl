using PIECM, Statistics, PGFPlotsX, LaTeXStrings, DataStructures, CSV, DataFrames, Colors

# plotly()
# pgfplotsx()

Ϟ = distinguishable_colors(20)
cell_dim = [0.0418, .1255]

P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", "new")
mbpf_50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
mbpf_100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.csv", "new")

mbpf140kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
mbpf200kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")


P0kpa.Date_Time .= replace.(P0kpa.Date_Time, "\t" => "")
mbpf_50kpa.Date_Time .= replace.(mbpf_50kpa.Date_Time, "\t" => "")
mbpf_100kpa.Date_Time .= replace.(mbpf_100kpa.Date_Time, "\t" => "")

# ----------pressure data----------------

A_cell = cell_dim[1] * cell_dim[2]
Pres50 = pressure_dateformat_fix("data/PressureData/230606_MBPF_KL_50kpa.csv")
P50kpa = pressurematch(mbpf_50kpa, Pres50, A_cell)

Pres100 = pressure_dateformat_fix("data/PressureData/230606_MBPF_KL_100kpa.csv")
P100kpa = pressurematch(mbpf_100kpa, Pres100, A_cell)

Pres40 = pressure_dateformat_fix("data/PressureData/230606_MBPF_KL_100kpa.csv")
P100kpa = pressurematch(mbpf_100kpa, Pres100, A_cell)

p50_all = OrderedDict()
for j in 1:20:101
    k = 1
    p50_plot = Array{Float64}(undef, 20, 2)

    if j == 1
        p_temp = filter(row -> row.Cycle_Index == j, P50kpa)
        for i in 0:19
            p = filter(row -> row.Step_Index == 25 && row.TC_Counter1 == i , p_temp)
            p50_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
            p50_plot[k,2] = 100 - (i+1) * 5
            k += 1
        end
    else
        p_temp = filter(row -> row.Cycle_Index == j, P50kpa)

        for i in 0:19
            p = filter(row -> row.Step_Index == 60 && row.TC_Counter1 == i , p_temp)
            p50_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
            p50_plot[k,2] = 100 - (i+1) * 5
            k += 1
        end
    end

    p50_all[string(j)] = p50_plot
end

p100_all = OrderedDict()

for j in 1:20:101
    k = 1
    p100_plot = Array{Float64}(undef, 20, 2)

    if j == 1
        p_temp = filter(row -> row.Cycle_Index == j, P100kpa)
        for i in 0:19
            p = filter(row -> row.Step_Index == 25 && row.TC_Counter1 == i , p_temp)
            p100_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
            p100_plot[k,2] = 100 - (i+1) * 5
            k += 1
        end
    else
        p_temp = filter(row -> row.Cycle_Index == j, P100kpa)

        for i in 0:19
            p = filter(row -> row.Step_Index == 60 && row.TC_Counter1 == i , p_temp)
            p100_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
            p100_plot[k,2] = 100 - (i+1) * 5
            k += 1
        end
    end

    p100_all[string(j)] = p100_plot
end

# p100_all = OrderedDict()
# for j in 1:20:101
#     k = 1
#     p100_plot = Array{Float64}(undef, 20, 2)

#     p_temp = filter(row -> row.Cycle_Index == j, P100kpa)

#     for i in 0:19
        
#         p = filter(row -> row.Step_Index == 60 || row.Step_Index == 25 && row.TC_Counter1 == i , p_temp)
#         p100_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
#         p100_plot[k,2] = 100 - (i+1) * 5
#         k += 1
#     end
    
#     p100_all[string(j)] = p100_plot
# end


# -------------hppc data-----------------
# R0 = OrderedDict()
# for j in 1:20:101
#     if j == 1
#         R0[string(j)] = HPPC(P0kpa, 5, j, 19, 21, 24, 5, 15)
#     else
#         R0[string(j)] = HPPC(P0kpa,  5, j, 54, 56, 59, 50, 13)
#     end
# end

# R50 = OrderedDict()
# R50["1"] = HPPC(mbpf_50kpa, 5, 1, 19, 21, 24, 5, 15)
# R50["21"] = HPPC(mbpf_50kpa, 5, 21, 54, 56, 59, 50, 13)
# R50["41"] = HPPC(mbpf_50kpa, 5, 41, 54, 56, 59, 50, 13)
# R50["61"] = HPPC(mbpf_50kpa, 5, 61, 54, 56, 59, 50, 13)
# R50["81"] = HPPC(mbpf_50kpa, 5, 81, 54, 56, 59, 50, 13)
# R50["101"] = HPPC(mbpf_50kpa, 5, 101, 54, 56, 59, 50, 13)

# R100 = OrderedDict()
# for j in 1:20:101
#     if j == 1
#         R100[string(j)] = HPPC(P100kpa,5, j, 19, 21, 24, 5, 15)
#     else
#         R100[string(j)] = HPPC(P100kpa,5, j, 54, 56, 59, 50, 13)
#     end
# end


pulse0_20SOC = hppc_fun(P0kpa, 10, 5, 20, 1)
pulse50_20SOC = hppc_fun(P50kpa, 10, 5, 19, 1)
pulse100_20SOC = hppc_fun(P100kpa, 10, 5, 19, 1)

pulse0_90SOC = hppc_fun(P0kpa, 90, 5, 20, 1)
pulse50_90SOC = hppc_fun(P50kpa, 90, 5, 19, 1)
pulse100_90SOC = hppc_fun(P100kpa, 90, 5, 19, 1)


pulse40_20SOC = hppc_fun(mbpf40kpa, 10, 10, 21, 1)
pulse140_20SOC = hppc_fun(mbpf140kpa, 10, 10, 18, 1)
pulse200_20SOC = hppc_fun(mbpf200kpa, 10, 10, 21, 1)

pulse40_90SOC = hppc_fun(mbpf40kpa, 90, 10, 21, 1)
pulse140_90SOC = hppc_fun(mbpf140kpa, 90, 10, 18, 1)
pulse200_90SOC = hppc_fun(mbpf200kpa, 90, 10, 21, 1)



# -------------capacity and energy data-----------------
rptdis = 40
rptchar = 44
rpt0dis = 5
rpt0char = 9
rptdc = 46
rpt0dc = 12
dis_step = 34
char_step = 36

dcir_step = 32
Ω0 = filter(row -> row."Step_Index" == dcir_step || row."Step_Index" == 15 || row."Step_Index" == 50, P0kpa)
Ω50 = filter(row -> row."Step_Index" == dcir_step || row."Step_Index" == 15 || row."Step_Index" == 50, P50kpa)
Ω100 = filter(row -> row."Step_Index" == dcir_step || row."Step_Index" == 15 || row."Step_Index" == 50, P100kpa)


# SOH_0 = Capacity_Fade(P0kpa, rpt0dis, rptdis)
SOH_50 = Capacity_Fade(P50kpa, rpt0dis, rptdis)
SOH_100 = Capacity_Fade(P100kpa, rpt0dis, rptdis)

# p50_discharge = sort!(filter(row -> row.Step_Index == dis_step_init, P50kpa), [:Date_Time])
# p50_charge = sort!(filter(row -> row.Step_Index == char_step_init, P50kpa), [:Date_Time])

p0_discharge_all = OrderedDict()
p0_dis_init = filter(row -> row.Step_Index == rpt0dis, P0kpa)
pushfirst!(p0_dis_init, filter(row -> row.Step_Index == rpt0dis-1, P0kpa)[end,:])
for i in 5:5:100
    ptemp = filter(row -> row.Step_Index == dis_step && row.Cycle_Index == i, P0kpa)
    pushfirst!(ptemp, filter(row -> row.Step_Index == dis_step-1 && row.Cycle_Index == i-1, P0kpa)[end,:])
    p0_discharge_all[string(i)] = ptemp
end

p50_discharge_all = OrderedDict()
p50_dis_init = sort!(filter(row -> row.Step_Index == rpt0dis, P50kpa), [:Date_Time])
pushfirst!(p50_dis_init, filter(row -> row.Step_Index == rpt0dis-1, P50kpa)[end,:])
for i in 5:5:100
    ptemp = sort!(filter(row -> row.Step_Index == dis_step && row.Cycle_Index == i, P50kpa), [:Date_Time])
    pushfirst!(ptemp, filter(row -> row.Step_Index == dis_step-1 && row.Cycle_Index == i-1, P50kpa)[end,:])
    p50_discharge_all[string(i)] = ptemp
end
p50_discharge = sort!(filter(row -> row.Step_Index == dis_step && row.Cycle_Index == 1, P50kpa), [:Date_Time])

p100_discharge_all = OrderedDict()
p100_dis_init = sort!(filter(row -> row.Step_Index == rpt0dis, P100kpa), [:Date_Time])
pushfirst!(p100_dis_init, filter(row -> row.Step_Index == rpt0dis-1, P100kpa)[end,:])
for i in 5:5:100
    ptemp = sort!(filter(row -> row.Step_Index == dis_step && row.Cycle_Index == i, P100kpa), [:Date_Time])
    pushfirst!(ptemp, filter(row -> row.Step_Index == dis_step-1 && row.Cycle_Index == i-1, P100kpa)[end,:])
    p100_discharge_all[string(i)] = ptemp
end
p100_discharge = sort!(filter(row -> row.Step_Index == dis_step && row.Cycle_Index == 1, P50kpa), [:Date_Time])


p50csv = dropmissing(p50_dis_init, :Pressure)
p100csv = dropmissing(p100_dis_init, :Pressure)

p50csv.Pressure ./= 1000
p100csv.Pressure ./= 1000

CSV.write("p50_discharge.csv", p50csv)
CSV.write("p100_discharge.csv", p100csv)
CSV.write("p0_discharge.csv", p0_dis_init)

# -------------plots-----------------

P50_plot = @pgf Axis(

    {
        height = "7cm", width = "15cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Stack Pressure [kPa]",
        xmin = 0, 
        xmax = 101,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "north west"
    },

    Plot({color = Ϟ[4], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["1"][:,2], y = p50_all["1"][:,1])),
    LegendEntry("Cycle 1"),
    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["21"][:,2], y = p50_all["21"][:,1])),
    LegendEntry("Cycle 21"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["41"][:,2], y = p50_all["41"][:,1])),
    LegendEntry("Cycle 41"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["61"][:,2], y = p50_all["61"][:,1])),
    LegendEntry("Cycle 61"),
    Plot({color = Ϟ[8], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["81"][:,2], y = p50_all["81"][:,1])),
    LegendEntry("Cycle 81"),
    Plot({color = Ϟ[10], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["101"][:,2], y = p50_all["101"][:,1])),
    LegendEntry("Cycle 101"),

)

P100_plot = @pgf Axis(

    {
        height = "7cm", width = "15cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Stack Pressure [kPa]",
        xmin = 0, 
        xmax = 101,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "north west"
    },

    Plot({color = Ϟ[4], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["1"][:,2], y = p100_all["1"][:,1])),
    LegendEntry("Cycle 1"),
    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["21"][:,2], y = p100_all["21"][:,1])),
    LegendEntry("Cycle 21"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["41"][:,2], y = p100_all["41"][:,1])),
    LegendEntry("Cycle 41"),
    Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["61"][:,2], y = p100_all["61"][:,1])),
    LegendEntry("Cycle 61"),
    Plot({color = Ϟ[8], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["81"][:,2], y = p100_all["81"][:,1])),
    LegendEntry("Cycle 81"),
    Plot({color = Ϟ[10], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["101"][:,2], y = p100_all["101"][:,1])),
    LegendEntry("Cycle 101"),

)

# Pcomp_plot = @pgf Axis(
#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Stack Pressure [kPa]",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "south east"
#     },

#     Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["1"][:,2], y = p50_all["1"][:,1])),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["1"][:,2], y = p100_all["1"][:,1])),
#     LegendEntry("100 kPa"),
#     Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["1"][:,2], y = p100_all["1"][:,1])),
#     LegendEntry("100 kPa"),
# )

# Pcomphppc_plot = @pgf Axis(

#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Stack Pressure [kPa]",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "south east"
#     },

#     Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["1"][:,2], y = p50_all["1"][:,1])),
#     LegendEntry("HPPC"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = 100 .- p50_discharge[:, "Discharge_Capacity(Ah)"]/5.5 * 100, y = p50_discharge[:, "Pressure"] / 1000)),
#     LegendEntry("Discharge C/2"),
#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = 100 .- p50_discharge_all["1"][:, "Discharge_Capacity(Ah)"]/5.5 * 100, y = p50_discharge_all["1"][:, "Pressure"] / 1000)),
#     LegendEntry("Discharge 10C"),

# )

# Rcomp_plot = @pgf Axis(

#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Resistance [mΩ]",
#         xmin = 0, 
#         xmax = 101,
#         ymax = 9.5,
#         ymin = 4.5,
#         xtick = 0:10:100,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = round.(R0["1"]["Discharge"][:,"SOC"],digits=0), y = R0["1"]["Discharge"][:,"Resistance"].*1000)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = round.(R50["1"]["Discharge"][:,"SOC"], digits=0), y = R50["1"]["Discharge"][:,"Resistance"].*1000)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = round.(R100["1"]["Discharge"][:,"SOC"], digits=0), y = R100["1"]["Discharge"][:,"Resistance"].*1000)),
#     LegendEntry("100 kPa"),

# )

# R50_plot = @pgf Axis(

#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Resistance [mΩ]",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[3], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["1"]["Discharge"][:,:SOC], y = R50["1"]["Discharge"][:,:Resistance].*1000)),
#     LegendEntry("Cycle 1"),
#     Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["21"]["Discharge"][:,:SOC], y = R50["21"]["Discharge"][:,:Resistance].*1000)),
#     LegendEntry("Cycle 21"),
#     Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["41"]["Discharge"][:,:SOC], y = R50["41"]["Discharge"][:,:Resistance].*1000)),
#     LegendEntry("Cycle 41"),
#     Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["61"]["Discharge"][:,:SOC], y = R50["61"]["Discharge"][:,:Resistance].*1000)),
#     LegendEntry("Cycle 61"),
#     Plot({color = Ϟ[8], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["81"]["Discharge"][:,:SOC], y = R50["81"]["Discharge"][:,:Resistance].*1000)),
#     LegendEntry("Cycle 81"),
#     Plot({color = Ϟ[10], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["101"]["Discharge"][:,:SOC], y = R50["101"]["Discharge"][:,:Resistance].*1000)),
#     LegendEntry("Cycle 101"),

# )


Pulse15_plot = @pgf GroupPlot(


    {
        group_style =
        {
            # group_size="2 by 2",
            # xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "north west"
        },
        height = "8cm", width = "10cm",    

    },
    # {
    #     xlabel="Time [s]",
    #     ylabel="Voltage [V]",
    #     xmin = -0.1, 
    #     xmax = 101,
    #     ymin = 3.35,
    #     ymax = 3.8,
    #     xtick = 0:20:100,
    #     legend_pos= "south east"
    # },

    # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = pulse0_20SOC[:,"Test_Time(s)"], y = pulse0_20SOC[:,"Voltage(V)"])),
    # LegendEntry("0 kPa"),
    # Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = pulse50_20SOC[:,"Test_Time(s)"], y = pulse50_20SOC[:,"Voltage(V)"])),
    # LegendEntry("50 kPa"),
    # Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = pulse100_20SOC[:,"Test_Time(s)"], y = pulse100_20SOC[:,"Voltage(V)"])),
    # LegendEntry("100 kPa"),
    # {
    #     xlabel="Time [s]",
    #     ylabel="Voltage [V]",
    #     xmin = -0.1, 
    #     xmax = 101,
    #     ymin = 3.75,
    #     ymax = 4.2,
    #     xtick = 0:20:100,
    #     legend_pos= "south east"
    # },

    # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = pulse0_90SOC[:,"Test_Time(s)"], y = pulse0_90SOC[:,"Voltage(V)"])),
    # LegendEntry("0 kPa"),
    # Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = pulse50_90SOC[:,"Test_Time(s)"], y = pulse50_90SOC[:,"Voltage(V)"])),
    # LegendEntry("50 kPa"),
    # Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = pulse100_90SOC[:,"Test_Time(s)"], y = pulse100_90SOC[:,"Voltage(V)"])),
    # LegendEntry("100 kPa"),

    # {
    #     xlabel="Time [s]",
    #     ylabel="Voltage [V]",
    #     xmin = -0.1, 
    #     xmax = 101,
    #     # ymin = 3.35,
    #     # ymax = 3.8,
    #     xtick = 0:20:100,
    #     legend_pos= "south east"
    # },

    # Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = pulse40_20SOC[:,"Test_Time(s)"], y = pulse40_20SOC[:,"Voltage(V)"])),
    # LegendEntry("47 kPa"),
    # Plot({color = Ϟ[10], "thick"}, Table({x = "x", y = "y"}, x = pulse140_20SOC[:,"Test_Time(s)"], y = pulse140_20SOC[:,"Voltage(V)"])),
    # LegendEntry("140 kPa"),
    # Plot({color = Ϟ[14], "thick"}, Table({x = "x", y = "y"}, x = pulse200_20SOC[:,"Test_Time(s)"], y = pulse200_20SOC[:,"Voltage(V)"])),
    # LegendEntry("210 kPa"),

    {
        xlabel="Time [s]",
        ylabel="Voltage [V]",
        xmin = -0.1, 
        xmax = 101,
        # ymin = 3.75,
        # ymax = 4.2,
        xtick = 0:20:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = pulse40_90SOC[:,"Test_Time(s)"], y = pulse40_90SOC[:,"Voltage(V)"])),
    LegendEntry("40 kPa"),
    Plot({color = Ϟ[10], "thick"}, Table({x = "x", y = "y"}, x = pulse140_90SOC[:,"Test_Time(s)"], y = pulse140_90SOC[:,"Voltage(V)"])),
    LegendEntry("140 kPa"),
    Plot({color = Ϟ[14], "thick"}, Table({x = "x", y = "y"}, x = pulse200_90SOC[:,"Test_Time(s)"], y = pulse200_90SOC[:,"Voltage(V)"])),
    LegendEntry("210 kPa"),

)

PresDis2_plot = @pgf GroupPlot(
    {
        group_style =
        {
            group_size="3 by 2",
            xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "north west"
            horizontal_sep = "2cm",
            vertical_sep = "2cm"
        },
        height = "8cm", width = "10cm",    

    },

    {
        ylabel="Voltage [V]",
        legend_pos= "south west",
    },
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p40_discharge[:,"Step_Time(s)"]./3600, y = p40_discharge[:,"Voltage(V)"])),
    LegendEntry("Cell Model (1) - 47 kPa"),

    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p50csv[:,"Step_Time(s)"]./3600, y = p50csv[:,"Voltage(V)"])),
    LegendEntry("Cel Model (2) - 50 kPa"),

    {
        ylabel="Pressure [kPa]",
    },

    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p50csv[:,"Step_Time(s)"]./3600, y = p50csv[:,"Pressure"])),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p40_discharge[:,"Step_Time(s)"]./3600, y = p40_discharge[:,"Pressure"]./1000)),


    {
        ylabel="Temperature [C]",
    },

    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p50csv[:,"Step_Time(s)"]./3600, y = p50csv[:,"Aux_Temperature_1(C)"])),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p40_discharge[:,"Step_Time(s)"]./3600, y = p40_discharge[:,"Aux_Temperature_1(C)"])),



    {
        xlabel="Time [hours]",
        ylabel="Voltage [V]",
        legend_pos= "south west",
    },
    Plot({color = Ϟ[14], "thick"}, Table({x = "x", y = "y"}, x = p140_discharge[:,"Step_Time(s)"]./3600, y = p140_discharge[:,"Voltage(V)"])),
    LegendEntry("Cell Model (1) - 140 kPa"),
    Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = p200_discharge[:,"Step_Time(s)"]./3600, y = p200_discharge[:,"Voltage(V)"])),
    LegendEntry("Cell Model (1) - 210 kPa"),
    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p100csv[:,"Step_Time(s)"]./3600, y = p100csv[:,"Voltage(V)"])),
    LegendEntry("Cell Model (2) - 100 kPa"),

    {
        xlabel="Time [hours]",
        ylabel="Pressure [kPa]",
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p100csv[:,"Step_Time(s)"]./3600, y = p100csv[:,"Pressure"])),
    Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = p200_discharge[:,"Step_Time(s)"]./3600, y = p200_discharge[:,"Pressure"]./1000)),
    Plot({color = Ϟ[14], "thick"}, Table({x = "x", y = "y"}, x = p140_discharge[:,"Step_Time(s)"]./3600, y = p140_discharge[:,"Pressure"]./1000)),

    {
        xlabel="Time [hours]",
        ylabel="Temperature [C]",
    },

    Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = p200_discharge[:,"Step_Time(s)"]./3600, y = p200_discharge[:,"Aux_Temperature_1(C)"])),
    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p100csv[:,"Step_Time(s)"]./3600, y = p100csv[:,"Aux_Temperature_1(C)"])),
    Plot({color = Ϟ[14], "thick"}, Table({x = "x", y = "y"}, x = p140_discharge[:,"Step_Time(s)"]./3600, y = p140_discharge[:,"Aux_Temperature_1(C)"])),
)

# PresTemp_plot = @pgf GroupPlot(

#     {
#         group_style =
#         {
#             group_size="2 by 2",
#             xticklabels_at="edge bottom",
#             # yticklabels_at="edge left",
#             # legend_pos= "north west"
#             horizontal_sep = "2cm"
#         },
#         height = "8cm", width = "10cm",    

#     },
#     {
#         # xlabel="Time [s]",
#         ylabel="Temperature [C]",
#         # xmin = -0.1, 
#         # xmax = 101,
#         # ymin = 3.75,
#         # ymax = 4.2,
#         # xtick = 0:20:100,
#         legend_pos= "south east"
#     },
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p40_discharge[:,"Step_Time(s)"]./3600, y = p40_discharge[:,"Aux_Temperature_1(C)"])),
#     LegendEntry("Cell 1 - 47 kPa"),
#     # Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = p200_discharge[:,"Step_Time(s)"], y = p200_discharge[:,"Voltage(V)"])),
#     # LegendEntry("Cell 1 - 210 kPa"),
#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p50csv[:,"Step_Time(s)"]./3600, y = p50csv[:,"Aux_Temperature_1(C)"])),
#     LegendEntry("Cell 2 - 50 kPa"),
#     # Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p100csv[:,"Step_Time(s)"], y = p100csv[:,"Voltage(V)"])),
#     # LegendEntry("Cell 2 - 100 kPa"),

#     {
#         # xlabel="Time [s]",
#         ylabel="Pressure [kPa]",
#         # xmin = -0.1, 
#         # xmax = 101,
#         # ymin = 3.35,
#         # ymax = 3.8,
#         # xtick = 0:20:100,
#         # legend_pos= "south east"
#     },

#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p50csv[:,"Step_Time(s)"]./3600, y = p50csv[:,"Pressure"])),
#     # LegendEntry("0 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p40_discharge[:,"Step_Time(s)"]./3600, y = p40_discharge[:,"Pressure"]./1000)),


#     {
#         xlabel="Time [hours]",
#         ylabel="Temperature [C]",
#         # xmin = -0.1, 
#         # xmax = 101,
#         # ymin = 3.75,
#         # ymax = 4.2,
#         # xtick = 0:20:100,
#         legend_pos= "south east"
#     },
#     # Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p40_discharge[:,"Step_Time(s)"], y = p40_discharge[:,"Voltage(V)"])),
#     # LegendEntry("Model 1 - 40 kPa"),
#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = p200_discharge[:,"Step_Time(s)"]./3600, y = p200_discharge[:,"Aux_Temperature_1(C)"])),
#     LegendEntry("Cell 1 - 210 kPa"),
#     # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p50csv[:,"Step_Time(s)"], y = p50csv[:,"Voltage(V)"])),
#     # LegendEntry("Model 2 - 50 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p100csv[:,"Step_Time(s)"]./3600, y = p100csv[:,"Aux_Temperature_1(C)"])),
#     LegendEntry("Cell 2 - 100 kPa"),

#     {
#         xlabel="Time [hours]",
#         ylabel="Pressure [kPa]",
#         # xmin = -0.1, 
#         # xmax = 101,
#         # ymin = 3.35,
#         # ymax = 3.8,
#         # xtick = 0:20:100,
#         # legend_pos= "south east"
#     },

#     # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p50csv[:,"Step_Time(s)"], y = p50csv[:,"Pressure"])),
#     # LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p100csv[:,"Step_Time(s)"]./3600, y = p100csv[:,"Pressure"])),
#     # LegendEntry("50 kPa"),
#     # Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p40_discharge[:,"Step_Time(s)"], y = p40_discharge[:,"Pressure"]./1000)),
#     Plot({color = Ϟ[8], "thick"}, Table({x = "x", y = "y"}, x = p200_discharge[:,"Step_Time(s)"]./3600, y = p200_discharge[:,"Pressure"]./1000)),
#     # LegendEntry("50 kPa"),


# )




# Pulsezoom_plot = @pgf GroupPlot(


#     {
#         group_style =
#         {
#             group_size="2 by 1",
#             xticklabels_at="edge bottom",
#             # yticklabels_at="edge left",
#             # legend_pos= "north west"
#         },
#         height = "8cm", width = "10cm",    

#     },
#     {
#         xlabel="Time [s]",
#         ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 14,
#         ymin = 3.35,
#         ymax = 3.8,
#         xtick = 0:2:100,
#         # legend_pos= "south east"
#     },

#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = pulse0_20SOC[:,"Test_Time(s)"], y = pulse0_20SOC[:,"Voltage(V)"])),
#     # LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = pulse50_20SOC[:,"Test_Time(s)"], y = pulse50_20SOC[:,"Voltage(V)"])),
#     # LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = pulse100_20SOC[:,"Test_Time(s)"], y = pulse100_20SOC[:,"Voltage(V)"])),
#     # LegendEntry("100 kPa"),
#     {
#         xlabel="Time [s]",
#         # ylabel="Voltage [V]",
#         xmin = -0.1, 
#         xmax = 14,
#         ymin = 3.75,
#         ymax = 4.2,
#         xtick = 0:2:100,
#         legend_pos= "south east"
#     },

#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = pulse0_90SOC[:,"Test_Time(s)"], y = pulse0_90SOC[:,"Voltage(V)"])),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = pulse50_90SOC[:,"Test_Time(s)"], y = pulse50_90SOC[:,"Voltage(V)"])),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = pulse100_90SOC[:,"Test_Time(s)"], y = pulse100_90SOC[:,"Voltage(V)"])),
#     LegendEntry("100 kPa"),

# )

SOH_plot = @pgf GroupPlot(


    {
        group_style =
        {
            # group_size="2 by 1",
            xticklabels_at="edge bottom",
            horizontal_sep = "2cm"
            # yticklabels_at="edge left",
            # legend_pos= "north west"
        },
        height = "8cm", width = "10cm",    

    },

    # {
    #     height = "8cm", width = "15cm",
    #     xlabel="Cycle",
    #     ylabel="State-of-Health ["*L"\%"*"]",
    #     xmin = -0.1, 
    #     xmax = 101,
    #     # ymin = 0.975,
    #     # ymax = 1.005,
    #     # ytick = 0.98:0.01:1.00,
    #     xtick = 0:10:100,
    #     legend_pos= "north east"
    # },

    # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = SOH_0[:,1], y = SOH_0[:,2])),
    # LegendEntry("0 kPa"),
    # Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = SOH_50[:,1], y = SOH_50[:,2])),
    # LegendEntry("50 kPa"),
    # Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = SOH_100[:,1], y = SOH_100[:,2])),
    # LegendEntry("100 kPa"),

    {
        height = "8cm", width = "15cm",
        xlabel="Cycle",
        ylabel="Pressure [kPa]",
        xmin = -0.1, 
        xmax = 101,
        # ymin = 0.975,
        # ymax = 1.005,
        # ytick = 0.98:0.01:1.00,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    # Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = SOH_0[:,1], y = SOH_0[:,2])),
    # LegendEntry("0 kPa"),
    Plot({color = Ϟ[5], "thick", style={"dashed"}}, Table({x = "x", y = "y"}, x = SOH_50[:,1], y = SOH_50[:,4]./1000)),
    LegendEntry("50 kPa"),
    Plot({color = Ϟ[6], "thick", style={"dashed"}}, Table({x = "x", y = "y"}, x = SOH_100[:,1], y = SOH_100[:,4]./1000)),
    LegendEntry("100 kPa"),


)

# dis_plot = @pgf GroupPlot(


#     {
#         group_style =
#         {
#             group_size="2 by 2",
#             xticklabels_at="edge bottom",
#             # yticklabels_at="edge left",
#             # legend_pos= "north west"
#             horizontal_sep = "2cm"
#         },
#         height = "7cm", width = "14cm",    

#     },
#     {
#         # height = "8cm", width = "15cm",
#         # xlabel="Cycle",
#         xlabel="Discharge Capacity [Ah]",
#         ylabel="Voltage [V]",
#         # xmin = 5.4, 
#         # xmax = 5.7,
#         # ymin = 2.98,
#         # ymax = 3.6,
#         # ytick = 0.98:0.01:1.00,
#         # xtick = 0:0.1:5.8,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p0_dis_init[:,"Discharge_Capacity(Ah)"], y = p0_dis_init[:,"Voltage(V)"])),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p50_dis_init[:,"Discharge_Capacity(Ah)"], y = p50_dis_init[:,"Voltage(V)"])),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p100_dis_init[:,"Discharge_Capacity(Ah)"], y = p100_dis_init[:,"Voltage(V)"])),
#     LegendEntry("100 kPa"),

#     {
#         # height = "8cm", width = "15cm",
#         # xlabel="Cycle",
#         xlabel="Discharge Capacity [Ah]",
#         ylabel="Voltage [V]",
#         xmin = 5.4, 
#         xmax = 5.7,
#         ymin = 2.98,
#         ymax = 3.6,
#         # ytick = 0.98:0.01:1.00,
#         xtick = 0:0.1:5.8,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p0_dis_init[:,"Discharge_Capacity(Ah)"], y = p0_dis_init[:,"Voltage(V)"])),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p50_dis_init[:,"Discharge_Capacity(Ah)"], y = p50_dis_init[:,"Voltage(V)"])),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p100_dis_init[:,"Discharge_Capacity(Ah)"], y = p100_dis_init[:,"Voltage(V)"])),
#     LegendEntry("100 kPa"),
    
#     {
#         # height = "8cm", width = "15cm",
#         xlabel="Discharge Capacity [Ah]",
#         # ylabel="Voltage [V]",
#         # xmin = 5.3, 
#         # xmax = 5.6,
#         # ymin = 2.98,
#         # ymax = 3.6,
#         # # ytick = 0.98:0.01:1.00,
#         # xtick = 0:0.1:5.8,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p0_discharge_all["5"][:,"Discharge_Capacity(Ah)"], y = p0_discharge_all["5"][:,"Voltage(V)"])),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p50_discharge_all["5"][:,"Discharge_Capacity(Ah)"], y = p50_discharge_all["5"][:,"Voltage(V)"])),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p100_discharge_all["5"][:,"Discharge_Capacity(Ah)"], y = p100_discharge_all["5"][:,"Voltage(V)"])),
#     LegendEntry("100 kPa"),
#     {
#         # height = "8cm", width = "15cm",
#         xlabel="Discharge Capacity [Ah]",
#         # ylabel="Voltage [V]",
#         xmin = 5.3, 
#         xmax = 5.6,
#         ymin = 2.98,
#         ymax = 3.6,
#         # # ytick = 0.98:0.01:1.00,
#         xtick = 0:0.1:5.8,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p0_discharge_all["5"][:,"Discharge_Capacity(Ah)"], y = p0_discharge_all["5"][:,"Voltage(V)"])),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p50_discharge_all["5"][:,"Discharge_Capacity(Ah)"], y = p50_discharge_all["5"][:,"Voltage(V)"])),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p100_discharge_all["5"][:,"Discharge_Capacity(Ah)"], y = p100_discharge_all["5"][:,"Voltage(V)"])),
#     LegendEntry("100 kPa"),


# )

dis_plot = @pgf GroupPlot(


    {
        group_style =
        {
            group_size="2 by 1",
            # xticklabels_at="edge bottom",
            # yticklabels_at="edge left",
            # legend_pos= "north west"
            horizontal_sep = "2cm"
        },
        height = "7cm", width = "10cm",    

    },

    {
        # height = "8cm", width = "15cm",
        # xlabel="Cycle",
        xlabel="State-of-Charge ["*L"\%"*"]",
        ylabel="Voltage [V]",
        xmin = 0.875, 
        xmax = 1.075,
        ymin = 2.98,
        ymax = 3.6,
        # ytick = 0.98:0.01:1.00,
        xtick = 0:0.05:1.1,
        legend_pos= "north east"
    },

    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p0_dis_init[:,"Discharge_Capacity(Ah)"]./p0_dis_init[end,"Discharge_Capacity(Ah)"], y = p0_dis_init[:,"Voltage(V)"])),
    LegendEntry("0 kPa"),
    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p50_dis_init[:,"Discharge_Capacity(Ah)"]./p50_dis_init[end,"Discharge_Capacity(Ah)"], y = p50_dis_init[:,"Voltage(V)"])),
    LegendEntry("50 kPa"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p100_dis_init[:,"Discharge_Capacity(Ah)"]./p100_dis_init[end,"Discharge_Capacity(Ah)"], y = p100_dis_init[:,"Voltage(V)"])),
    LegendEntry("100 kPa"),

    {
        # height = "8cm", width = "15cm",
        xlabel="State-of-Charge ["*L"\%"*"]",
        # ylabel="Voltage [V]",
        xmin = 0.875, 
        xmax = 1.075,
        ymin = 2.98,
        ymax = 3.6,
        # # ytick = 0.98:0.01:1.00,
        xtick = 0:0.05:1.1,
        legend_pos= "north east"
    },

    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = p0_discharge_all["5"][:,"Discharge_Capacity(Ah)"]./p0_dis_init[end,"Discharge_Capacity(Ah)"], y = p0_discharge_all["5"][:,"Voltage(V)"])),
    LegendEntry("0 kPa"),
    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = p50_discharge_all["5"][:,"Discharge_Capacity(Ah)"]./p50_dis_init[end,"Discharge_Capacity(Ah)"], y = p50_discharge_all["5"][:,"Voltage(V)"])),
    LegendEntry("50 kPa"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = p100_discharge_all["5"][:,"Discharge_Capacity(Ah)"]./p100_dis_init[end,"Discharge_Capacity(Ah)"], y = p100_discharge_all["5"][:,"Voltage(V)"])),
    LegendEntry("100 kPa"),


)
pgfsave("figures/dis_plot.pdf", dis_plot, include_preamble = false)

#  Ω_plot = @pgf Axis(

#     {
#         height = "8cm", width = "15cm",
#         xlabel="Cycle",
#         ylabel="Resistance [mΩ]",
#         xmin = -0.1, 
#         xmax = 101,
#         # ymin = 0.975,
#         # ymax = 1.005,
#         # ytick = 0.98:0.01:1.00,
#         xtick = 0:10:100,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = Ω0[:,"Cycle_Index"], y = Ω0[:,"Internal_Resistance(Ohm)"].*1000)),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"},  x = Ω50[:,"Cycle_Index"], y = Ω50[:,"Internal_Resistance(Ohm)"].*1000)),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"},  x = Ω100[:,"Cycle_Index"], y = Ω100[:,"Internal_Resistance(Ohm)"].*1000)),
#     LegendEntry("100 kPa"),


# )

# Pow50_plot = @pgf Axis(

#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Max Power [W]",
#         xmin = 40, 
#         xmax = 50,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "north east"
#     },

#     Plot({color = Ϟ[3], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["1"]["Discharge"][:,:SOC], y = R50["1"]["Discharge"][:,"Max Power (W)"])),
#     LegendEntry("Cycle 1"),
#     Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["21"]["Discharge"][:,:SOC], y = R50["21"]["Discharge"][:,"Max Power (W)"])),
#     LegendEntry("Cycle 21"),
#     Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["41"]["Discharge"][:,:SOC], y = R50["41"]["Discharge"][:,"Max Power (W)"])),
#     LegendEntry("Cycle 41"),
#     Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["61"]["Discharge"][:,:SOC], y = R50["61"]["Discharge"][:,"Max Power (W)"])),
#     LegendEntry("Cycle 61"),
#     Plot({color = Ϟ[8], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["81"]["Discharge"][:,:SOC], y = R50["81"]["Discharge"][:,"Max Power (W)"])),
#     LegendEntry("Cycle 81"),
#     Plot({color = Ϟ[10], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["101"]["Discharge"][:,:SOC], y = R50["101"]["Discharge"][:,"Max Power (W)"])),
#     LegendEntry("Cycle 101"),

# )

# Pow_plot = @pgf Axis(

#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Max Power [W]",
#         xmin = 0, 
#         xmax = 100,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "south east"
#     },

#     Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = R0["1"]["Discharge"][:,:SOC], y = abs.(R0["1"]["Discharge"][:,"Max Power (W)"]))),
#     LegendEntry("0 kPa"),
#     Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["1"]["Discharge"][:,:SOC], y = abs.(R50["1"]["Discharge"][:,"Max Power (W)"]))),
#     LegendEntry("50 kPa"),
#     Plot({color = Ϟ[8], "thick", only_marks}, Table({x = "x", y = "y"}, x = R100["1"]["Discharge"][:,:SOC], y = abs.(R100["1"]["Discharge"][:,"Max Power (W)"]))),
#     LegendEntry("100 kPa"),
#     # Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["21"]["Discharge"][:,:SOC], y = R50["21"]["Discharge"][:,"Max Power (W)"])),
#     # LegendEntry("Cycle 21"),
#     # Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["41"]["Discharge"][:,:SOC], y = R50["41"]["Discharge"][:,"Max Power (W)"])),
#     # LegendEntry("Cycle 41"),
#     # Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["61"]["Discharge"][:,:SOC], y = R50["61"]["Discharge"][:,"Max Power (W)"])),
#     # LegendEntry("Cycle 61"),
#     # Plot({color = Ϟ[8], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["81"]["Discharge"][:,:SOC], y = R50["81"]["Discharge"][:,"Max Power (W)"])),
#     # LegendEntry("Cycle 81"),
#     # Plot({color = Ϟ[10], "thick", only_marks}, Table({x = "x", y = "y"}, x = R50["101"]["Discharge"][:,:SOC], y = R50["101"]["Discharge"][:,"Max Power (W)"])),
#     # LegendEntry("Cycle 101"),

# )

# pgfsave("figures/P50_plot.pdf",
#         P50_plot)
pgfsave("figures/P100_plot.pdf",
        P100_plot)

# pgfsave("figures/Pcomp_plot.pdf",
# Pcomp_plot)
# pgfsave("figures/Rcomp_plot.pdf",
# Rcomp_plot)
# pgfsave("figures/Pulse15_plot.pdf",
# Pulse15_plot)
pgfsave("figures/SOH_plot.pdf",
SOH_plot)
# pgfsave("figures/dis_plot.pdf",
# dis_plot)
# pgfsave("figures/R50_plot.pdf",
# R50_plot)
# pgfsave("figures/Rdeg_plot.pdf",
# Ω_plot)
# pgfsave("figures/Pow_plot.pdf",
# Pow_plot)
pgfsave("figures/pressure_dis_comparison.pdf",
PresDis2_plot)



# plot(p50_discharge[:,"Discharge_Capacity(Ah)"], p50_discharge[:,"Pressure"], label = "C/2", xlabel = "Time [s]", ylabel = "Voltage [V]")
# plot!(p50_discharge_all["1"][:,"Discharge_Capacity(Ah)"], p50_discharge_all["1"][:,"Pressure"], label = "1", xlabel = "Time [s]", ylabel = "Voltage [V]")

# plot!(p50_discharge_all["100"][:,"Discharge_Capacity(Ah)"], p50_discharge_all["100"][:,"Pressure"], label = "101", xlabel = "Time [s]", ylabel = "Voltage [V]")


# plot(p50_discharge[:,"Step Time (s)"], p50_discharge[:,"Voltage(V)"], label = "Discharge", xlabel = "Time [s]", ylabel = "Voltage [V]")
# plot!(p50_charge[:,"Step Time (s)"], p50_charge[:,"Voltage(V)"], label = "charge", xlabel = "Time [s]", ylabel = "Voltage [V]")
# plot!(twinx(), p50_discharge[:,"Step Time (s)"], p50_discharge[:,"Pressure"], label = "Discharge", ylabel = "Pressure")
# plot!(twinx(), p50_charge[:,"Step Time (s)"], p50_charge[:,"Pressure"], label = "Discharge", ylabel = "Pressure")

# Pcomp_plot = @pgf Axis(

#     {
#         height = "7cm", width = "15cm",    
#         xlabel="State of Charge ["*L"\%"*"]",
#         ylabel="Stack Pressure [kPa]",
#         xmin = 0, 
#         xmax = 101,
#         # ymax = 15,
#         # ymin = 10,
#         xtick = 0:10:100,
#         legend_pos= "south east"
#     },

#     Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_charge[:,"Step Time (s)"], y = p50_charge[:,"Voltage(V)"])),
#     LegendEntry("50 kPa"),
#     # Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_charge[:,"Step Time (s)"], y = p50_charge[:,"Pressure"])),
#     # LegendEntry("100 kPa"),

# )

