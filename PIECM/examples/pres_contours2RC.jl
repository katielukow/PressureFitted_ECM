using PIECM, Statistics, PlotlyJS, JLD2

# Data Import
data25 = jldopen("/Users/katielukow/Documents/git-repos/JLD2_ECMParam/err25_2RC.jld2")["data"]

data40 = jldopen("/Users/katielukow/Documents/git-repos/JLD2_ECMParam/err40_2RC.jld2")["data"]

data130 = jldopen("/Users/katielukow/Documents/git-repos/JLD2_ECMParam/err130_2RC.jld2")["data"]

t = pres_contour_2RC(data25[0.9], "25 kPa, 90SOC")
data = data25[0.9]

df_all = DataFrame(R0 = data[:, 1],
R1 = data[:, 2],
R2 = data[:, 3],
C1 = data[:, 4],
C2 = data[:, 5],
Error = data[:, 6])

min = findmin(df_all[:,:Error])
R_fil = df_all[min[2], :R0]
df = filter(row -> row.R0 == R_fil, df_all)

err_temp = findmin(df[:,:Error])
df_fil = filter(row -> row.R1 == df[err_temp[2], :R1] && row.R2 == df[err_temp[2], :R2], df)

r1values = unique(df_fil[:,:C1])
r2values = unique(df_fil[:,:C2])

mat = zeros(length(r1values), length(r2values))
for i in 1:length(r1values)
    for j in 1:length(r2values)
        df_temp = filter(row -> row.C1 == r1values[i] && row.C2 == r2values[j], df_fil)
        if length(df_temp[:,:Error]) > 0
            mat[i,j] = df_temp[1,:Error]
            mat[j,i] = df_temp[1,:Error]
        # else
        #     mat[i,j] = NaN
        end 
    end
end
t1 = contour(z=mat, x=r1values, y=r2values, contours_start=0, contours_end=2, colorbar_title="Error", showscale=true)

# Define the plot size
plot_width = 800
plot_height = 800

layout1 = Layout(title="25 kPa, 90SOC", width=plot_width, height=plot_height)

# Plot the figure
plot([t1], layout1)
