module PIECM

using CSV, DataFrames, Dates, Infiltrator, BenchmarkTools, Plots

plotly()


sqrzeros(A) = zeros(A,A)



function data_import(cell_file, pres_file)
    
    cell_data = CSV.read(cell_file, DataFrame)
    pressure_data = CSV.read(pres_file, DataFrame)
    pressure_data.Time = Dates.format.(pressure_data.Time, "HH:MM:SS")
    pressure_data.Date = Date.(pressure_data.Date, "dd/mm/yyyy")
    pressure_data.Date = Dates.format.(pressure_data.Date, "yyyy/mm/dd")
    pressure_data.Date_Time = pressure_data.Date .* " " .* pressure_data.Time

    return cell_data, pressure_data
end


# Data Import
function pressurematch(cell_data, pressure_data) # function will be much faster - local not global
    # look at dynamic time warping?

    # ϕ = Array{Float64}(undef,length(cell_data.Date_Time),1)
    # ϕ = Array{Float64}(undef,100,1)
    ϕ2 = Array{Float64}(undef,length(cell_data.Date_Time),1)
    # @views for i in 1:100
    #     @views for j in 1:length(pressure_data.Date_Time)
    #         if pressure_data[j,:Date_Time] == cell_data[i,:Date_Time]
    #             ϕ[i] .= pressure_data[j,:Force]
    #         end
    #     end
    # end

    for k in 1:100
        x = filter(row -> row.Date_Time == cell_data[k,:Date_Time], pressure_data)

        if size(x)[1] == 0 
            ϕ2[k] = 0
        else
            ϕ2[k] = x[1, :Force]
        end

    end

    return ϕ2

end

cd₁, pd₁ = data_import("data/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_Channel_7_Wb_1.csv", "data/220729_CPF_HPPC_Melasta_SLPB7336128HV_11_0041_90kPa_25C_pres.csv")

@benchmark p₁ = pressurematch(cd₁, pd₁)


# ----------------------------------

n_RC = 1  
OCV = 0
Q = 0
η = 0
Δ = 0.1 # time step Δt

x = [0,0] # R1 C1

# RC Params
A_RC = sqrzeros(n_RC)
B_RC = zeros(n_RC)

# p = [R1 C1 R0]
# u[1] = z ? am I doing this right?!
# u[2] = iᵣ ? am I doing this right?!

function ecmfit(p, n_RC)

    OCV = data
    du[1] = dz = -i / Q
    du[2] = diᵣ = - 1 / (p[1] * p[2]) * u[2] + 1 / (p[1] * p[2]) * i
    v = OCV(u[1], T) + p[1] * u[2] + p[3] * i

end





for α in 1:n_RC
    F = exp(-Δ/(x[1]*x[2]))
    A_RC[α,α] = F
    B_RC[α] = (1-F)
end


z[k+1] = z[k] + (-η * Δ / Q) * i[k]
iᵣ[k+1] = A_RC * iᵣ[k] + B_RC * i[k]
v[k] = OCV(z[k], T[k]) + x[1] * iᵣ[k] - R₀ * i[k]



end
