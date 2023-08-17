using PIECM, Plots, Statistics, PGFPlotsX, LaTeXStrings, DataStructures

plotly()
pgfplotsx()

Ϟ = distinguishable_colors(10)
cell_dim = [0.0418, .1255]

mbpf_0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", "new")
mbpf_50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
mbpf_100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.csv", "new")

mbpf_50kpa.Date_Time .= replace.(mbpf_50kpa.Date_Time, "\t" => "")
mbpf_100kpa.Date_Time .= replace.(mbpf_100kpa.Date_Time, "\t" => "")



A_cell = cell_dim[1] * cell_dim[2]
Pres50 = pressure_dateformat_fix("data/PressureData/230606_MBPF_KL_50kpa.csv")
P50kpa = pressurematch(mbpf_50kpa, Pres50, A_cell)




Pres100 = pressure_dateformat_fix("data/PressureData/230606_MBPF_KL_100kpa.csv")
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

    p_temp = filter(row -> row.Cycle_Index == j, P100kpa)

    for i in 0:19
        
        p = filter(row -> row.Step_Index == 60 || row.Step_Index == 25 && row.TC_Counter1 == i , p_temp)
        p100_plot[k,1] = mean(skipmissing(p[:,"Pressure"]))/1000
        p100_plot[k,2] = 100 - (i+1) * 5
        k += 1
    end
    
    p100_all[string(j)] = p100_plot
end

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

Pcomp_plot = @pgf Axis(

    {
        height = "7cm", width = "15cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Stack Pressure [kPa]",
        xmin = 0, 
        xmax = 101,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["21"][:,2], y = p50_all["21"][:,1])),
    LegendEntry("50 kPa"),
    Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = p100_all["21"][:,2], y = p100_all["21"][:,1])),
    LegendEntry("100 kPa"),

)

Pcomphppc_plot = @pgf Axis(

    {
        height = "7cm", width = "15cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Stack Pressure [kPa]",
        xmin = 0, 
        xmax = 101,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_all["1"][:,2], y = p50_all["1"][:,1])),
    LegendEntry("HPPC"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = 100 .- p50_discharge[:, "Discharge_Capacity(Ah)"]/5.5 * 100, y = p50_discharge[:, "Pressure"] / 1000)),
    LegendEntry("Discharge C/2"),
    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = 100 .- p50_discharge_all["1"][:, "Discharge_Capacity(Ah)"]/5.5 * 100, y = p50_discharge_all["1"][:, "Pressure"] / 1000)),
    LegendEntry("Discharge 10C"),

)

pgfsave("figures/P50_plot.pdf",
        P50_plot)

pgfsave("figures/Pcomp_plot.pdf",
Pcomp_plot)

dis_step_init = 5
char_step_init = 9
dis_step = 34
char_step = 36

p50_discharge = sort!(filter(row -> row.Step_Index == dis_step_init, P50kpa), [:Date_Time])
p50_charge = sort!(filter(row -> row.Step_Index == char_step_init, P50kpa), [:Date_Time])

p50_discharge_all = OrderedDict()
for i in 1:101
    p50_discharge_all[string(i)] = filter(row -> row.Step_Index == dis_step && row.Cycle_Index == i, P50kpa)
end

plot(p50_discharge[:,"Discharge_Capacity(Ah)"], p50_discharge[:,"Pressure"], label = "C/2", xlabel = "Time [s]", ylabel = "Voltage [V]")
plot!(p50_discharge_all["1"][:,"Discharge_Capacity(Ah)"], p50_discharge_all["1"][:,"Pressure"], label = "1", xlabel = "Time [s]", ylabel = "Voltage [V]")

plot!(p50_discharge_all["100"][:,"Discharge_Capacity(Ah)"], p50_discharge_all["100"][:,"Pressure"], label = "101", xlabel = "Time [s]", ylabel = "Voltage [V]")


plot(p50_discharge[:,"Step Time (s)"], p50_discharge[:,"Voltage(V)"], label = "Discharge", xlabel = "Time [s]", ylabel = "Voltage [V]")
plot!(p50_charge[:,"Step Time (s)"], p50_charge[:,"Voltage(V)"], label = "charge", xlabel = "Time [s]", ylabel = "Voltage [V]")
plot!(twinx(), p50_discharge[:,"Step Time (s)"], p50_discharge[:,"Pressure"], label = "Discharge", ylabel = "Pressure")
plot!(twinx(), p50_charge[:,"Step Time (s)"], p50_charge[:,"Pressure"], label = "Discharge", ylabel = "Pressure")

Pcomp_plot = @pgf Axis(

    {
        height = "7cm", width = "15cm",    
        xlabel="State of Charge ["*L"\%"*"]",
        ylabel="Stack Pressure [kPa]",
        xmin = 0, 
        xmax = 101,
        # ymax = 15,
        # ymin = 10,
        xtick = 0:10:100,
        legend_pos= "south east"
    },

    Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_charge[:,"Step Time (s)"], y = p50_charge[:,"Voltage(V)"])),
    LegendEntry("50 kPa"),
    # Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = p50_charge[:,"Step Time (s)"], y = p50_charge[:,"Pressure"])),
    # LegendEntry("100 kPa"),

)

