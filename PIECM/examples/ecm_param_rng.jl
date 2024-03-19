using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PlotlyJS

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

P0kpa.Date_Time .= replace.(P0kpa.Date_Time, "\t" => "")
mbpf50kpa.Date_Time .= replace.(mbpf50kpa.Date_Time, "\t" => "")
mbpf100kpa.Date_Time .= replace.(mbpf100kpa.Date_Time, "\t" => "")

print("Data import complete")

err25, Z25 = soc_range(mbpf25kpa, Q25, ocv1, 10, 17, [500, 100, 8000], [0.001, .001, 0.020], [0.1, .1, 0.9]);
err40, Z40  = soc_range(mbpf40kpa, Q40, ocv1, 10, 20, [500, 100, 8000], [0.001, .001, 0.020], [0.1, .1, 0.9]);
err130, Z130 = soc_range(mbpf130kpa, Q130, ocv1, 10, 20, [500, 100, 10000], [0.001, .001, 0.020], [0.1, .1, 0.9]);

err0, Z0 = soc_range(P0kpa, Q0, ocv2, 5, 19, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 0.9]);
err50, Z50 = soc_range(mbpf50kpa, Q50, ocv2, 5, 19, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 0.9]);
err100, Z100 = soc_range(mbpf100kpa, Q100, ocv2, 5, 19, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 0.9]);

min40 = rmins(Z40[0.9])
min25 = rmins(Z25[0.9])
min130 = rmins(Z130[0.9])

for i in Z40.keys
    title = "Cell Model (2), 40 kPa, " * string(i*100) * "% SOC"
    p = pres_contour(Z40[i], rmins(z40[i]), title)
end
p40 = pres_contour(Z40[0.9], min40, "40 kPa")
relayout!(p40, titlefont_size=20, font_size=18, width=200, height=1000, margin_l=100, margin_r=100, margin_t=100, margin_b=100, showlegend=false)
p25 = pres_contour(Z25[0.9], min25, "135 kPa")
p130 = pres_contour(Z130[0.9],min130,"210 kPa")
p = [p40 p25 p130]

min0 = rmins(Z0[0.9])
min50 = rmins(Z50[0.9])
min100 = rmins(Z100[0.9])

p0 = pres_contour(Z0[0.9], min0, "0 kPa")
p50 = pres_contour(Z50[0.9], min50, "50 kPa")
p100 = pres_contour(Z100[0.9],min100,"100 kPa")
p = [p0 p50 p100]

p130_1 = pres_contour(Z130[0.9],min130,"R0 = 0.0087, Err = 0.040 V")
p130_2 = pres_contour(Z130[0.9],min130[2:end,:],"R0 = 0.0077, Err = 0.154 V")
p130_3 = pres_contour(Z130[0.9],min130[3:end,:],"R0 = 0.0097, Err = 0.200 V")

p = [p130_1 p130_2 p130_3]
relayout!(p, titlefont_size=20, font_size=18, width=1000, height=1000, margin_l=100, margin_r=100, margin_t=100, margin_b=100, showlegend=false)

# savefig(p, "contour_plots_20.pdf")



# Single RC vs 2 RC comparison

# contour plot at 90% SOC for three r0 values of the lowest error for model (1), single pressure

# contour plot at 20% SOC for three r0 values of the lowest error for model (1), single pressure

# need to put into for loop with save fig, adjust contour start and end to be relevant to the data







