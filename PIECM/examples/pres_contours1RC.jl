using PIECM, Statistics, PlotlyJS, JLD2

# Data Import
data25 = jldopen("../../JLD2_ECMParam/err25.jld2")["data"]

data40 = jldopen("JLD2_ECMParam/err40.jld2")["data"]

data130 = jldopen("JLD2_ECMParam/err130.jld2")["data"]

t1 = contour(z=dict[mins[1,:R0]][2:end, 2:end], x=dict[mins[1,:R0]][1, 2:end], y=dict[mins[1,:R0]][2:end,1], 
contours_start =0,contours_end=2, 
colorbar_title="Error",  showscale=true)
t2 = scatter(x=[mins[1,:C1]],y=[mins[1,:R1]], mode="markers", showlegend = false)
layout1 = PlotlyJS.Layout(titlefont_size=20, font_size=18, width=600, height=600, margin_l=100, margin_r=100, margin_t=100, margin_b=100, showlegend=false, xaxis_title="C1", yaxis_title="R1")
p = plot([t1,t2], layout1)
# e