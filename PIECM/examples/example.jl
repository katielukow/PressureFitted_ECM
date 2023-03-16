using PIECM, Plots, Optim

plotly()

# Data Import
A_cell₁ = .128 * .036 # m2
cd₁ = data_import("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv")
hppc_55 = hppc_pulse(cd₁, 55, 5, 1, 15, 17)
hppc_55."Test_Time(s)" .-= hppc_55."Test_Time(s)"[1]

pd₁ = pressure_dateformat_fix("data/HPPC/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_pres.csv")
p₁ = pressurematch(cd₁, pd₁, A_cell₁)

ocvd₁ = data_import("data/OCV/220310_BTC_POCV_GITT_Mel_SLPB7336128HV_1_25C_Channel_5_Wb_1.csv")
ocv₁ = pocv_calc(ocvd₁, 5, 8, 100)

uₜ = [ones(100).*-27.49736; ones(400).*0; ones(100).*5.998779 ;ones(400).*0]

x1 = [0.008, 3000, 0.008]
x2 = [0.008, 3000, 0.012]

# Static Time
# vₛ1 = ecm_discrete(x1, 1, uₜ, 0.1, 0.999, 3.7, ocv₁, 55)
# vₛ2 = ecm_discrete(x2, 1, uₜ, 0.1, 0.999, 3.7, ocv₁, 55)

# Current from data (variable time step)
v1 = ecm_discrete(x1, 2, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 55)
# v2 = ecm_discrete(x2, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 55)

err = costfunction(hppc_55, x1, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.999, 3.7, ocv₁, 55)

# Plots
# plot(collect(0.1:0.1:100),vt, label = "x1")
# plot!(collect(0.1:0.1:100),vt2, label = "x2")
# plot(hppc_55."Test_Time(s)",v1, label = "x1")
# plot!(hppc_55."Test_Time(s)",v2, label = "x2")
# plot!(hppc_55."Test_Time(s)", hppc_55."Voltage(V)", label = "Experimental")

res = optimize(costfunction_closed, x1)
xₙ = Optim.minimizer(res)
vₙ = ecm_discrete(xₙ, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.9997, 3.7, ocv₁, 55)

res_PSO = optimize(costfunction_closed, x1, ParticleSwarm())
xₚ = Optim.minimizer(res)
vₚ = ecm_discrete(xₚ, 1, hppc_55."Current(A)", hppc_55."Test_Time(s)", 0.9997, 3.7, ocv₁, 55)

plot(hppc_55."Test_Time(s)", vₙ, label = "Nedler Mead")
plot(hppc_55."Test_Time(s)", vₚ, label = "PSO")
# plot!(hppc_55."Test_Time(s)",v1, label = "ECM Katie")
plot!(hppc_55."Test_Time(s)", hppc_55."Voltage(V)", label = "Experimental")


# Run 1
# * Candidate solution
# Final objective value:     2.358317e+00
# julia> xₙ
# 3-element Vector{Float64}:
#     0.039259411401955165
#  2446.0228489920073
#     0.012052944342782566