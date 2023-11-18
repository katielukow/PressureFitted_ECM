using PIECM, Plots, Optim, Statistics, PGFPlotsX, LaTeXStrings, StatsBase, BenchmarkTools, DataStructures, DataFrames


BenchmarkTools.DEFAULT_PARAMETERS.seconds = 60
# plotly()
Ϟ = distinguishable_colors(20)

mbpf50kpa = data_import_csv("data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new")
ocv = pocv("data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", 11, 13, 1000)
mbpf50kpa.Date_Time .= replace.(mbpf50kpa.Date_Time, "\t" => "")

Q = 5.5
soc = 0.7
mbpf50kpa_1 = hppc_fun(mbpf50kpa, soc*100, 5, 1, 19, 21, 1)

function ecm_fit(data, Q, ocv, soc, x0)
    uᵢ = data."Current(A)"
    Δ = data."Test_Time(s)"
    η = 0.999
    costfunction_closed = κ->costfunction(κ, 1, uᵢ, Δ, η, Q, ocv, soc, data)
    res = optimize(costfunction_closed, x0, iterations= 10000)
    x = Optim.minimizer(res)
    v = ecm_discrete(x, 1, data."Current(A)", data."Test_Time(s)", η, Q, ocv, soc)
    
    lb = [0, 1000, 0]
    ub = [0.1, 2000, 0.1]

    # result = optimize(costfunction_closed, lb, ub, x0, ParticleSwarm())

    result = optimize(costfunction_closed, x0, LBFGS())

    println("Minima: $(result.minimizer)")
    println("Minimum value: $(result.minimum)")

    return v, x, res, result
end


# result = optimize(rosenbrock, lb, ub, ParticleSwarm(), maxiters=1000)


v, x, res, result = ecm_fit(mbpf50kpa_1, 1, ocv, soc, [0.01, 3000, 0.01])