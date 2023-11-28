using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PlotlyJS

function ecm_err_range_2RC(data, Q, ocv, soc, soc_increment, dstep, C1_range, R1_range)

    df = hppc_fun(data, soc*100, soc_increment, 1, dstep, dstep+2, 1)
    r0_init = hppc_calc(df, round(((100 - soc*100) / soc_increment)), df[:,"Voltage(V)"][1])

	xrng = R1_range[1]:R1_range[2]:R1_range[3]
    yrng = C1_range[1]:C1_range[2]:C1_range[3]
	zrng = r0_init-0.005:0.001:r0_init+0.002
    x2rng = R1_range[1]:R1_range[2]:R1_range[3]
    y2rng = C1_range[1]:C1_range[2]:C1_range[3]

    errors = OrderedDict()

    current = df."Current(A)"
    test_time = df."Test_Time(s)"
    voltage_end = df."Voltage(V)"[1:end-1]
    
    err_matrix = zeros(length(xrng) + 1, length(yrng) + 1)
    err_matrix[1, 2:end] .= yrng
    err_matrix[2:end, 1] .= xrng

    
    
    # print(r0, "\n")
    # for k in r0 * 0.5:0.0005:r0*1.5
    for (k,r0) in enumerate(zrng)
        print(k, "\n")
        df = DataFrame([[],[],[],[],[]], [:R1, :R2, :C1, :C2, :Err])
        for (r1) in R1_range
            for (c1) in C1_range
                for (r2) in R1_range
                    for (c2) in C1_range
                        v_model = ecm_discrete([r1,r2, c1,c2, r0], 2, current, test_time, 0.999, Q, ocv, soc)
                        err = sqL2dist(v_model, voltage_end)
                        # err_matrix[i+1, j+1] = err
                        push!(df, [r1, r2, c1, c2, err])
                    end
                end
            end
        end

        errors[round(r0, digits = 6)] = df
        # errors[round(r0, digits = 6)] = copy(err_matrix)
    end

    return errors, df
end

mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.CSV", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.CSV", "old")
ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.CSV", 5, 8, 1000)

err40, df40 = ecm_err_range_2RC(mbpf40kpa, 3.7, ocv1, 1, 10, 20, LinRange(10000,30000,101), LinRange(0.00001, .010001, 11))

mins40 = DataFrame([[],[],[],[],[],[]], [:Err, :R0, :R1, :R2, :C1, :C2])

for i in eachindex(err40)
    mini = argmin(err40[i][:, :Err])
    temp = err40[i][mini, :]
    # print(temp[:R1], "\n")
    push!(mins40, [temp[:Err], i, temp[:R1], temp[:R2], temp[:C1], temp[:C2]])
end
