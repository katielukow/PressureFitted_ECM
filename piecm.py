import pandas as pd
import numpy as np
import matplotlib.pyplot as plt




def piecm():
    # some ecm stuff
    print("this will be the ecm")

def data_rename(file_name, format):

    df = pd.read_csv(file_name)
    if format == "new":
        df.rename(columns={"Step Index":"Step_Index", "Test Time (s)":"Test_Time(s)", "Step Time (s)":"Step_Time(s)", "Date Time":"Date_Time", "Cycle Index":"Cycle_Index","Voltage (V)" :"Voltage(V)", "Cycle Index" : "Cycle_Index","Voltage (V)" :"Voltage(V)", "Current (A)" : "Current(A)", "Internal Resistance (Ohm)": "Internal_Resistance(Ohm)", "Discharge Capacity (Ah)" :"Discharge_Capacity(Ah)", "Discharge Energy (Wh)" : "Discharge_Energy(Wh)", "Charge Capacity (Ah)" : "Charge_Capacity(Ah)", "Aux_Temperature_1 (C)" :"Aux_Temperature_(C)"}, inplace=True)

    return df

def hppc_pulse(data, soc, soc_increment, dis_pulse_step, char_pulse_step):
    df_temp = data[(data['TC_Counter1'] == np.round(((100-soc) / soc_increment)))]
    df = df_temp[(df_temp['Step_Index'] == dis_pulse_step) | (df_temp['Step_Index'] == char_pulse_step) | (df_temp['Step_Index'] == dis_pulse_step-1) | (df_temp['Step_Index'] == char_pulse_step + 1) | (df_temp['Step_Index'] == char_pulse_step -1)]

    return df