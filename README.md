# Pressure-Fitted Equivalent Circuit Model

The pressure fitted ECM explores the impact of stack pressure on high power, low impedance pouch cells. 
A Thevenin circuit model was developed and fit at three different initial (100% SOC) stack pressures for a 3RC circuit. 

The model included can be fit with the desired RC parameters with parameter optimisation currently completed using the Nelder-Mead algorithm through Optim.jl. 
