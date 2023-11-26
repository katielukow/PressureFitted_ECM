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


soc = 0.9


# z0= ecm_err_range(P0kpa, 5.5, ocv2, soc, 5, 19, [7000, 50, 12000], [0.001, .0005, 0.010]);
# z50= ecm_err_range(mbpf50kpa, 5.5, ocv2, soc, 5, 19, [7000, 50, 12000], [0.001, .0005, 0.010]);
# z100= ecm_err_range(mbpf100kpa, 5.5, ocv2, soc, 5, 19, [7000, 50, 12000], [0.001, .0005, 0.010]);

# min0 = rmins(z0)
# min50 = rmins(z50)
# min100 = rmins(z100)

# p0 = pres_contour(z0, min0, "0 kPa")
# p50 = pres_contour(z50, min50, "50 kPa")
# p100 = pres_contour(z100, min100, "100 kPa")
# p = [p0 p50 p100]

z25 = ecm_err_range(mbpf25kpa, 3.7, ocv1, soc, 10, 17, [1000, 50, 12000], [0.001, .0005, 0.010]);
z40 = ecm_err_range(mbpf40kpa, 3.7, ocv1, soc, 10, 20, [1000, 50, 12000], [0.001, .0005, 0.010]);
z130 = ecm_err_range(mbpf130kpa, 3.7, ocv1, soc, 10, 20, [1000, 50, 8000], [0.001, .0005, 0.010]);

min25 = rmins(z25)
min40 = rmins(z40)
min130 = rmins(z130)

p25 = pres_contour(z25, min25, "25 kPa")
p40 = pres_contour(z40, min40, "40 kPa")
p130 = pres_contour(z130,min130,"130 kPa")
p = [p25 p40 p130]

p130_1 = pres_contour(z130,min130,"R0 = 0.0096, Err = 0.109 V")
p130_2 = pres_contour(z130,min130[2:end,:],"R0 = 0.0106, Err = 0.110 V")
p130_3 = pres_contour(z130,min130[4:end,:],"R0 = 0.0116, Err = 0.456 V")

p = [p130_1 p130_2 p130_3]
# relayout!(p, titlefont_size=20, font_size=18, width=1000, height=1000, margin_l=100, margin_r=100, margin_t=100, margin_b=100, showlegend=false)

# savefig(p, "contour_plots_20.pdf")



# Set up other SOC points - maybe 10 50 90
# add +/- on R0 or fit R0 too

# Single RC vs 2 RC comparison

# contour plot at 90% SOC for three r0 values of the lowest error for model (1), single pressure

# contour plot at 20% SOC for three r0 values of the lowest error for model (1), single pressure

# scatter plot of error vs r0 for model (1) at 20% SOC and 90% SOC for all pressures, both models (1) and (2)