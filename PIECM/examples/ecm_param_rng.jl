using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PlotlyJS

# Data Import
# mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.csv", "old")
# mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.csv", "old")
# mbpf130kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_130kpa_11_0044_Channel_5_Wb_1.csv", "old")

# P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", "new")
# mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
# mbpf100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.csv", "new")

# ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv", 5, 8, 1000)
# ocv2 = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", 11, 13, 1000)

P0kpa.Date_Time .= replace.(P0kpa.Date_Time, "\t" => "")
mbpf50kpa.Date_Time .= replace.(mbpf50kpa.Date_Time, "\t" => "")
mbpf100kpa.Date_Time .= replace.(mbpf100kpa.Date_Time, "\t" => "")

function ecm_err_range(data, Q, ocv, soc, soc_increment)
    xrng = 0.001:0.0001:0.010
    yrng = 100:50:4000
    z = zeros(length(xrng) + 1, length(yrng) + 1)
    df = hppc_fun(data, soc*100, 5, 1, 19, 21, 1)

    r0 = hppc_calc(df, round(((100 - soc) / soc_increment)), df[:,"Voltage(V)"][1])
    # print(r0, "\n")

    for i in 1:length(xrng)
        for j in 1:length(yrng)
            r1 = xrng[i]
            c1 = yrng[j]
            v = ecm_discrete([r1, c1, r0], 1, df."Current(A)", df."Test_Time(s)", 0.999, Q, ocv, soc)
            err = sqL2dist(v, df[:,"Voltage(V)"][1:end-1])
            z[i+1, j+1] = err
            z[1, j+1] = yrng[j]
        end
        z[i+1, 1] = xrng[i]

    end

    return z
end
soc = 0.9

z0 = ecm_err_range(P0kpa, 5.5, ocv2, soc, 5)
z50 = ecm_err_range(mbpf50kpa, 5.5, ocv2, soc, 5)
z100 = ecm_err_range(mbpf100kpa, 5.5, ocv2, soc, 5)

min0 = argmin(z0[2:end, 2:end])
min50 = argmin(z50[2:end, 2:end])
min100 = argmin(z100[2:end, 2:end])

trace1 = contour(z=z50[2:end, 2:end].-z100[2:end, 2:end], x=z100[2:end, 1], y=z100[1, 2:end])
trace2 = scatter(x=[z100[min0[1]+1,1], z50[min50[1]+1,1], z0[min0[1]+1,1]], y=[z100[1,min0[2]+1], z50[1,min50[2]+1], z0[1,min0[2]+1]], mode="markers")
layout = Layout(
    title="Error Surface",
    scene=attr(xaxis=attr(title="R1"), yaxis=attr(title="C1"), zaxis=attr(title="Error")),
    annotations=[
        attr(
            x=z100[min100[1]+1,1],
            y=z100[1,min100[2]+1],
            showarrow=false,
            text="100 kPa",
            font=attr(

                color="black",

                size=12

            ),
            # xref="paper",
            # yref="paper"
        ), 
        attr(
            x=z50[min50[1]+1,1],
            y=z50[1,min50[2]+1],
            showarrow=false,
            text="50 kPa",
            font=attr(

                color="white",

                size=12

            ),
            # xref="paper",
            # yref="paper"
        ),
        attr(
            x=z0[min0[1]+1,1],
            y=z0[1,min0[2]+1],
            showarrow=false,
            text="0 kPa",
            font=attr(

                color="white",

                size=12

            ),
            # xref="paper",
            # yref="paper"
        )
    ]
)

# plot([trace1,trace2], layout)

plot(contour(z=z0[2:end, 2:end], x=z0[2:end, 1], y=z0[1, 2:end], contours_start = 0, contours_end=.8))

plot(contour(z=z50[2:end, 2:end], x=z50[2:end, 1], y=z50[1, 2:end], contours_start = 0, contours_end=.8))

plot(contour(z=z100[2:end, 2:end], x=z100[2:end, 1], y=z100[1, 2:end], contours_start = 0, contours_end=.8))

# plot(contour(z=z50[2:end, 2:end].-z100[2:end, 2:end], x=z100[2:end, 1], y=z100[1, 2:end]))
# plot(contour(z=z50[2:end, 2:end].-z0[2:end, 2:end], x=z0[2:end, 1], y=z0[1, 2:end]))

# Change minimisation function to sum least squares? or something more representative
# Set up other SOC points - maybe 10 50 90
# add +/- on R0 and get actual measured R0

# Single RC comparison

# 2RC comparison

