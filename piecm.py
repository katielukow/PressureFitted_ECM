import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
from scipy import optimize
from sklearn.metrics import mean_squared_error




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

    return df.iloc[5:]

def ocv_fun(file_name, dis_step, chg_step, OCV_steps):
    df = data_rename(file_name, "new")
    dis = df[(df['Step_Index'] == dis_step)]
    chg = df[(df['Step_Index'] == chg_step)]

    res_dis = pd.DataFrame()
    res_chg = pd.DataFrame()

    Q_dis = dis["Discharge_Capacity(Ah)"] - dis["Discharge_Capacity(Ah)"].iloc[0]
    Q_chg = chg["Charge_Capacity(Ah)"] - chg["Charge_Capacity(Ah)"].iloc[0]


    res_dis["SOC"] = 100 - Q_dis / Q_dis.iloc[-1] * 100
    res_dis["Voltage"] = dis["Voltage(V)"]
    res_chg["SOC"] = Q_chg / Q_chg.iloc[-1] * 100
    res_chg["Voltage"] = chg["Voltage(V)"]

    POCVc = np.zeros((OCV_steps+1, 2))
    POCVd = np.zeros((OCV_steps+1, 2))

    j = 0
    for i in np.linspace(0, 100, OCV_steps+1):
        min_c = np.argmin(np.abs(res_chg["SOC"] - i))
        min_d = np.argmin(np.abs(res_dis["SOC"] - i))
        POCVc[j, 0] = np.round(res_chg["SOC"].iloc[min_c], 1)
        POCVc[j, 1] = res_chg["Voltage"].iloc[min_c]
        POCVd[j, 0] = np.round(res_dis["SOC"].iloc[min_d], 1)
        POCVd[j, 1] = res_dis["Voltage"].iloc[min_d]

        j += 1
        
    pocv = (POCVc + POCVd) / 2
    

    return res_dis, res_chg, pocv

def ecm_discrete(fitparams, I, t, Q, ocv, Init_SOC, n_RC):

    r1, c1, r0 = fitparams
    interp_SOC = interp1d(ocv[:,0], ocv[:,1])

    z = np.zeros(len(t))
    v = np.zeros(len(t))
    iR = np.zeros(len(t))
    v[0] = interp_SOC(Init_SOC)
    z[0] = Init_SOC

    A_RC = np.zeros((n_RC, n_RC))
    B_RC = np.zeros((n_RC, 1))

    I = -I

    tau = t - t.iloc[0]
    delta_t = np.diff(tau)
    delta_t = np.concatenate(([0], delta_t))

    for i in np.linspace(0,len(I)-2, len(I)-1, dtype = int):
        F = np.exp(-delta_t[i] / (r1*c1))
        A_RC = F
        B_RC = (1 - F)

        z[i+1] = z[i] + (delta_t[i]/3600) * (I.iloc[i] / Q)
        iR[i+1] = A_RC * iR[i] + B_RC * I.iloc[i]

        v[i] = interp_SOC(z[i]).item() - r1 * iR[i] - r0 * I.iloc[i]


    return v[:-1]

def ecm_cf(fitparams, I, t, Q, ocv, Init_SOC, n_RC, data):
    return mean_squared_error(data[:-1], ecm_discrete(fitparams, I, t, Q, ocv, Init_SOC, n_RC))


df = hppc_pulse(data_rename("/Users/katielukow/Documents/git-repos/PressureFitted_ECM/PIECM/data/HPPC/230606_MBPF_PCharact_Mel_SLPBA442124_50kpa_25C_Channel_4_Wb_1.csv", "new"), 50, 5, 19, 21)

ocv_d, ocv_c, ocv = ocv_fun("/Users/katielukow/Documents/git-repos/PressureFitted_ECM/PIECM/data/OCV/230621_MBPF_PCharact_POCV_Mel_SLPBA442124_0kpa_25C_Channel_3_Wb_1.csv", 11, 13, 1000)



I = df["Current(A)"]
t = df["Test_Time(s)"]
Q = 5.5
ocv = ocv
n_RC = 1
Init_SOC = 50
data = df["Voltage(V)"]

res = optimize.minimize(ecm_cf, x0=[0.01, 7000, 0.01], args=(I,t,Q,ocv,Init_SOC,n_RC, data))
v = ecm_discrete(res.x, df["Current(A)"], df["Test_Time(s)"], 5.5, ocv, 50, 1)

plt.plot(df["Test_Time(s)"][:-1],v)
plt.plot(df["Test_Time(s)"][:-1],df["Voltage(V)"][:-1])
plt.show()