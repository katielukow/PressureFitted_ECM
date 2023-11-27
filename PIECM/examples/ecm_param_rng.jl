using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PlotlyJS

# Data Import
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

print("Data import complete")

err25, Z25 = soc_range(mbpf25kpa, 3.7, ocv1, 10, 17, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 1]);
err40, Z40  = soc_range(mbpf40kpa, 3.7, ocv1, 10, 20, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 1]);
err130, Z130 = soc_range(mbpf130kpa, 3.7, ocv1, 10, 20, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 1]);

err0, Z0 = soc_range(P0kpa, 5.5, ocv2, 5, 19, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 1]);
err50, Z50 = soc_range(mbpf50kpa, 5.5, ocv2, 5, 19, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 1]);
err100, Z100 = soc_range(mbpf100kpa, 5.5, ocv2, 5, 19, [1000, 50, 12000], [0.001, .0005, 0.010], [0.1, .1, 1]);

soc_v = 0.5
d25 = hppc_fun(mbpf25kpa, soc_v*100, 10, 1, 17, 19, 1);
v25_2 = ecm_discrete([err25[5, :R1], err25[5, :C1], err25[5, :R0]], 1, d25."Current(A)", d25."Test_Time(s)", 0.999, 3.7, ocv1, soc_v)

d40 = hppc_fun(mbpf40kpa, soc_v*100, 10, 1, 20, 22, 1);
v40 = ecm_discrete([err40[5, :R1], err40[5, :C1], err40[5, :R0]], 1, d40."Current(A)", d40."Test_Time(s)", 0.999, 3.7, ocv1, soc_v)

d130 = hppc_fun(mbpf130kpa, soc_v*100, 10, 1, 20, 22, 1);
v130 = ecm_discrete([err130[5, :R1], err130[5, :C1], err130[5, :R0]], 1, d130."Current(A)", d130."Test_Time(s)", 0.999, 3.7, ocv1, soc_v)

t1 = scatter(x = d0."Test_Time(s)", y = d0."Voltage(V)", mode="lines")
t2 = scatter(x = d0[1:end-1,"Test_Time(s)"], y = v0, mode="lines")
plot([t1,t2])

d0 = hppc_fun(mbpf0kpa, soc_v*100, 5, 1, 19, 21, 1);
v0 = ecm_discrete([err0[5, :R1], err0[5, :C1], err0[5, :R0]], 1, d0."Current(A)", d0."Test_Time(s)", 0.999, 5.5, ocv2, soc_v)



# p25 = pres_contour(z25, min25, "25 kPa")
# p40 = pres_contour(z40, min40, "40 kPa")
# p130 = pres_contour(z130,min130,"130 kPa")
# p = [p25 p40 p130]

# p130_1 = pres_contour(z130,min130,"R0 = 0.0096, Err = 0.109 V")
# p130_2 = pres_contour(z130,min130[2:end,:],"R0 = 0.0106, Err = 0.110 V")
# p130_3 = pres_contour(z130,min130[4:end,:],"R0 = 0.0116, Err = 0.456 V")

# p = [p130_1 p130_2 p130_3]
# relayout!(p, titlefont_size=20, font_size=18, width=1000, height=1000, margin_l=100, margin_r=100, margin_t=100, margin_b=100, showlegend=false)

# savefig(p, "contour_plots_20.pdf")



# Set up other SOC points - maybe 10 50 90
# add +/- on R0 or fit R0 too

# Single RC vs 2 RC comparison

# contour plot at 90% SOC for three r0 values of the lowest error for model (1), single pressure

# contour plot at 20% SOC for three r0 values of the lowest error for model (1), single pressure

# scatter plot of error vs r0 for model (1) at 20% SOC and 90% SOC for all pressures, both models (1) and (2)