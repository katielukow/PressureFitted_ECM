using PIECM, Statistics, StatsBase, DataStructures, DataFrames, PlotlyJS, JLD2
using Base.Threads

function ecm_err_range_2RC(data, Q, ocv, soc, soc_increment, dstep, C_range, R_range)

    df = hppc_fun(data, soc*100, soc_increment, 1, dstep, dstep+2, 1)
    r0_init = hppc_calc(df, round(((100 - soc*100) / soc_increment)), df[:,"Voltage(V)"][1])
	zrng = r0_init-0.005:0.001:r0_init+0.002
    zrng_array = collect(enumerate(zrng))  # Convert to array for threading

    # errors = OrderedDict()

    current = df."Current(A)"
    test_time = df."Test_Time(s)"
    voltage_end = df."Voltage(V)"[1:end-1]

    results = DataFrame(R0 = Float64[], R1 = Float64[], R2 = Float64[], C1 = Float64[], C2 = Float64[], Err = Float64[])
    resize!(results, length(R_range) * length(C_range) * length(R_range) * length(C_range) * length(zrng_array))

    
    # print(r0, "\n")
    # for k in r0 * 0.5:0.0005:r0*1.5
    i = 1
    for (k,r0) in zrng_array
        print(k, "\n")
        # local_results = DataFrame(R0 = Float64[], R1 = Float64[], R2 = Float64[], C1 = Float64[], C2 = Float64[], Err = Float64[])
        for (r1) in R_range
            for (c1) in C_range
                for (r2) in R_range
                    for (c2) in C_range
                        v_model = ecm_discrete([r1,r2, c1,c2, r0], 2, current, test_time, 0.999, Q, ocv, soc)
                        err = sqL2dist(v_model, voltage_end)
                        # push!(results, [r0, r1, r2, c1, c2, err])
                        results[i, :] = [r0, r1, r2, c1, c2, err]
                        i+=1
                    end
                end
            end
        end
        # append!(results, local_results)
        # errors[round(r0, digits = 6)] = df
        # errors[round(r0, digits = 6)] = copy(err_matrix)
    end

    return results
end

mbpf25kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_25kpa_11_0043_Channel_6_Wb_1.CSV", "old")
mbpf40kpa = data_import_csv("data/HPPC/230320_MBPF_Investigation_40kpa_11_0048_Channel_6_Wb_1.CSV", "old")
ocv1 = pocv("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.CSV", 5, 8, 1000)

P0kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", "new")
mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.CSV", "new")
mbpf100kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_100kpa_25C_Channel_7_Wb_1.CSV", "new")
ocv2 = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.CSV", 11, 13, 1000)

df40 = ecm_err_range_2RC(mbpf40kpa, 3.7, ocv1, 1, 10, 20, LinRange(10000,30000,81), LinRange(0.00001, .010001, 11))
min40 = sort!(df40, :Err)
println(min40[1:10, :])

# min_err40 = argmin(df40[:, :Err])
# mins40 = df40[min_err40, :]
# mins40 = DataFrame([[],[],[],[],[],[]], [:Err, :R0, :R1, :R2, :C1, :C2])

df50 = ecm_err_range_2RC(mbpf50kpa, 5.5, ocv2, 1, 5, 19, LinRange(10000,30000,81), LinRange(0.00001, .010001, 11))
min50 = sort!(df50, :Err)
println(min50[1:10,:]
# mins50 = DataFrame([[],[],[],[],[],[]], [:Err, :R0, :R1, :R2, :C1, :C2])

# for i in eachindex(err40)
#     mini = argmin(err40[i][:, :Err])
#     temp = err40[i][mini, :]
#     # print(temp[:R1], "\n")
#     push!(mins40, [temp[:Err], i, temp[:R1], temp[:R2], temp[:C1], temp[:C2]])
# end

# for i in eachindex(err50)
#     mini = argmin(err50[i][:, :Err])
#     temp = err50[i][mini, :]
#     # print(temp[:R1], "\n")
#     push!(mins50, [temp[:Err], i, temp[:R1], temp[:R2], temp[:C1], temp[:C2]])
# end

jldsave("err40_2RC.jld2", data=df40)
jldsave("err50_2RC.jld2", data=df50)
