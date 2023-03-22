using PIECM, Plots, Statistics

plotly()
Ϟ = distinguishable_colors(10)

# --------------- Data Import ------------------------------
function data_imp(hppc_file, pres_file, Acell)
    
    cd = data_import_csv(hppc_file)
    A_cell = Acell[1] * Acell[2]
    pd = pressure_dateformat_fix(pres_file)
    return pressurematch(cd, pd, A_cell)

end

function pres_avg(pres_file, data, Area)
    p = pressure_dateformat_fix(pres_file)
    return round(mean(filter(!ismissing, pressurematch(data, p, Area[1] * Area[2])[:,"Pressure"]))/1000, digits=2)
end

# hppc_55_cpf90kpa, ocv₁ = data_imp("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv", "data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 55, 5, 2, 15, 17,1)
# mbpf200kpa = data_imp("data/HPPC/230309_MBPF_Investigation_200kpa_11_0042_Channel_6_Wb_1.csv", "data/PressureData/200kpa_100kpa_Pressure_data.csv", [0.128, 0.036])
# mbpf100kpa = data_imp("data/HPPC/230315_MBPF_Investigation_100kpa_11_0041_Channel_6_Wb_1.csv", "data/PressureData/200kpa_100kpa_Pressure_data.csv", [0.128, 0.036])
# mbpf25kpa_P = data_imp("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv","data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv", [0.128, 0.036])
# mbpf40kpa_P = data_imp("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv","data/PressureData/230321_PressureTest_11_0048.csv", [0.128, 0.036])
# mbpf130kpa_P = data_imp("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv","data/PressureData/230321_PressureTest_11_0044.csv", [0.128, 0.036])

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

soc = 0.5
celldim = [0.128, 0.036]

# mbpf200kpa_1 = hppc_fun(mbpf200kpa, soc*100, 5, 1, 17, 19, 1)
# mbpf100kpa_1 = hppc_fun(mbpf100kpa, soc*100, 5, 1, 17, 19, 1)
mbpf25kpa_1 = hppc_fun(mbpf25kpa, soc*100, 10, 1, 17, 19, 1)
mbpf40kpa_1 = hppc_fun(mbpf40kpa, soc*100, 10, 1, 20, 22, 1)
mbpf130kpa_1 = hppc_fun(mbpf130kpa, soc*100, 10, 1, 20, 22, 1)

P_25kpa = pres_avg("data/PressureData/230320_MBPF_Investigation_11_0043_25kpa.csv",mbpf25kpa_1,celldim)
P_40kpa = pres_avg("data/PressureData/230321_PressureTest_11_0048.csv",mbpf40kpa_1,celldim)
P_130kpa = pres_avg("data/PressureData/230321_PressureTest_11_0044.csv",mbpf130kpa_1,celldim)


# ----------------- Converting voltage to Float64 ----------------------------
# Only needed if XLSX is imported

# mbpf200kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf200kpa_1."Voltage(V)")
# mbpf200kpa_21."Voltage(V)" = convert(Array{Float64}, mbpf200kpa_21."Voltage(V)")
# mbpf100kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf100kpa_1."Voltage(V)")
# mbpf100kpa_21."Voltage(V)" = convert(Array{Float64}, mbpf100kpa_21."Voltage(V)")
# mbpf25kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf25kpa_1."Voltage(V)")
# mbpf40kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf40kpa_1."Voltage(V)")
# mbpf130kpa_1."Voltage(V)" = convert(Array{Float64}, mbpf130kpa_1."Voltage(V)")

soc90 = @pgf GroupPlot(
    {
        # group_style = {       

        #     group_size="2 by 1"

        # },

        height = "10cm", width = "15cm",
        legend_pos= "south east",
        # legend_style =
        # {
        #     at = Coordinate(1.1, 0.5),
        #     anchor = "east",
        #     legend_columns = 1
        # },

    },

    {
        ylabel="Voltage [V]",
        xlabel="State-of-Charge ["*L"\%"*"]",
        xmin = 0, 
        xmax = 100,
        xtick = 0:10:100,
    #     scaled_y_ticks = false, 
    #     yticklabel_style={
    #         precision=5
    # },
    },

    Plot({color = Ϟ[5], "thick"}, Table({x = "x", y = "y"}, x = mbpf40kpa_1[:,"Test_Time(s)"], y = mbpf40kpa_1[:,"Voltage(V)"])),
    LegendEntry("P_40kpa"),
    Plot({color = Ϟ[6], "thick"}, Table({x = "x", y = "y"}, x = mbpf25kpa_1[:,"Test_Time(s)"], y = mbpf25kpa_1[:,"Voltage(V)"])),
    LegendEntry("P_25kpa"),
    Plot({color = Ϟ[7], "thick"}, Table({x = "x", y = "y"}, x = mbpf130kpa_1[:,"Test_Time(s)"], y = mbpf130kpa_1[:,"Voltage(V)"])),
    LegendEntry("P_130kpa"),


    # {
    #     # ylabel="Power [W]",
    #     xlabel="State-of-Charge ["*L"\%"*"]",
    #     xmin = 0, 
    #     xmax = 100,
    #     xtick = 0:10:100,
    # #     scaled_y_ticks = false, 
    # #     yticklabel_style={
    # #         precision=5
    # # },
    # },

    # Plot({color = Ϟ[5], "thick", only_marks}, Table({x = "x", y = "y"}, x = h4["5C"][x][z][:,"SOC"], y = h4["5C"][x][z][:,"Average Power (W)"])),
    # LegendEntry("5°C"),
    # Plot({color = Ϟ[6], "thick", only_marks}, Table({x = "x", y = "y"}, x = h4["15C"][x][z][:,"SOC"], y = h4["15C"][x][z][:,"Average Power (W)"])),
    # LegendEntry("15°C"),
    # Plot({color = Ϟ[7], "thick", only_marks}, Table({x = "x", y = "y"}, x = h4["25C"][x][z][:,"SOC"], y = h4["25C"][x][z][:,"Average Power (W)"])),
    # LegendEntry("25°C"),
    # Plot({color = Ϟ[8], "thick", only_marks}, Table({x = "x", y = "y"}, x = h4["35C"][x][z][:,"SOC"], y = h4["35C"][x][z][:,"Average Power (W)"])),
    # LegendEntry("35°C"),
    # Plot({color = Ϟ[10], "thick", only_marks}, Table({x = "x", y = "y"}, x = h4["45C"][x][z][:,"SOC"], y = h4["45C"][x][z][:,"Average Power (W)"])),
    # LegendEntry("45°C"),
 
 
 
)