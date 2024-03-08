using PIECM, Statistics, PlotlyJS, JLD2

# Data Import
data25 = jldopen("JLD2_ECMParam/err25.jld2")["data"]

data40 = jldopen("JLD2_ECMParam/err40.jld2")["data"]

data130 = jldopen("JLD2_ECMParam/err130.jld2")["data"]

