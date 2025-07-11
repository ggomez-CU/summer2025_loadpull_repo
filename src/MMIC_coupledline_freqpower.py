import matplotlib.pyplot as plt
import numpy as np
from classes import *
from pylogfile.base import *
from tqdm import tqdm
from datetime import datetime
import shutil
import matplotlib.pyplot  as plt
import os
from scipy.io import loadmat
import sys

# I know it is bad practice but these are global
output_power_plot = np.array([])
input_power_plot = np.array([])
set_power_plot = np.array([])
sampler1_plot = np.array([])
sampler2_plot = np.array([])
gammaload_plot = np.array([]).astype(complex)
load_plot = np.array([]).astype(complex)
meas_power_plot = np.array([])

def ab2gamma(T,R,directivity,tracking,port_match):
    # eq from hackborn. extrapolated equation 
    return directivity + (tracking*T/R)/(1-port_match*T/R)

                        datatemp = {'PNA Power: '+ str(power) + str(i): 
                                    {'Input power': power,
                                    'wave data': pna.get_loadpull_data(),
                                    'Gamma Load': {'real': gammaload.real,
                                        'imag': gammaload.imag},
                                    'Power Meter': pm.fetch_power(),
                                    'Samplers':{
                                        '1': dmm1.fetch_voltage()
                                        '2': dmm2.fetch_voltage()},                                    }
                                    }

def updateplot(axs, line, data,coupling,idx):
    keys_list = list(data.keys())

    set_power_plot = np.append(set_power_plot,data[keys_list[0]]['Input Power'])

    outputdBm =  round(data[keys_list[0]]['output_awave']['dBm_mag'][0]+coupling['output coupling'],3)
    inputdBm = round(data[keys_list[0]]['input_awave']['dBm_mag'][0]+coupling['input coupling'],3)
    output_power_plot = np.append(output_power_plot,outputdBm)
    input_power_plot = np.append(input_power_plot,inputdBm)

    sampler1_plot = np.append(sampler1_plot,set_power_plot,data[keys_list[0]]['Samplers']['1'])
    sampler2_plot = np.append(sampler2_plot,set_power_plot,data[keys_list[0]]['Samplers']['2'])

    gammaload = ab2gamma(complex(data[keys_list[0]]['output_awave']['real'][0], data[keys_list[0]]['output_awave']['imag'][0]),
            complex(data[keys_list[0]]['output_bwave']['real'][0], data[keys_list[0]]['output_bwave']['imag'][0]),
                                error_terms['match'], error_terms['tracking'], error_terms['directivity'])[0]

    gammaload_plot = np.append(gammaload_plot,gammaload)

    line[0].set_data([np.angle(gammaload_plot)], [np.abs(gammaload_plot)])
    line[1].set_data(set_power_plot,output_power_plot)
    line[2].set_data(set_power_plot,output_power_plot)
    line[3].set_data(set_power_plot,output_power_plot-input_power_plot)
    line[2*idx+2].set_data(set_power_plot,sampler1_plot)
    line[2*idx+3].set_data(set_power_plot,sampler2_plot)
    axs['MeasTable'].cla()
    axs['MeasTable'].axis('off')
    axs['MeasTable'].table(cellText=[[inputdBm],
            [outputdBm],
            [outputdBm-inputdBm],
            [data[keys_list[0]]['Samplers']['Bias']]
            [data[keys_list[0]]['Input Power']]],
            rowLabels=rows,
            colLabels=columns,
            loc='center')

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Specifies User outputs and test validation on or off"
    )
    parser.add_option("-p", "--plot",
                  action="store_false", dest="plot", default=True,
                  help="plot output data while running tests")
    parser.add_option("-f", "--force",
                  action="store_false", dest="force", default=False,
                  help="Run without checking valid config")
    parser.add_option("-q", "--quiet",
                  action="store_false", dest="verbose", default=False,
                  help="don't print status messages to stdout")
    parser.add_option("-i", "--informal",
                  action="store_false", dest="informal", default=False,
                  help="no comment from user when initiated. Makes understanding the data harder later")
    (options, args) = parser.parse_args()

    print(f"This test will run as quiet {options.verbose} forced {options.force} and plotted {options.plot}")

    config = SystemValidationPowerConfig(r"C:\Users\grgo8200\Documents\AFRL_Testbench\data\coupledline_samplers\coupledline_samplers_config.json")
    now = datetime.now().strftime("%Y-%m-%d_%H_%M")
    output_dir = os.getcwd() + "\\data\\coupledline_samplers\\" \
            + now + "_Freq" \
            + str(config.frequency[0]) + "to" + str(config.frequency[-1])
    os.mkdir(output_dir)

    if not option.informal:
        paragraph_lines = []
        print("Enter your Comments. Press Enter on an empty line to finish:")
        while True:
            line = input()
            if not line:  # Check if the line is empty
                break
            paragraph_lines.append(line)

        paragraph = "\n".join(paragraph_lines)
    else:
        paragraph = "None"


#region Optional Configuration User Validation
    #Estimate Time and ensure test should be run.
    config_file = output_dir + "\\config_file.json"
    config_data = output_file_test_config_data(config_file, config, paragraph, now)
    
    if not (options.force): 
        print(" ==========\tTEST CONFIGURATION\t========== ")
        print(json.dumps(config_data, indent=4))
        print('\n\n')
        expected_test_time(config)
        print(f"Estimated Pout of the PreAmp: {[float(x)+30 for x in config.input_power_dBm]}")
        print(f"Estimated Pin Power Meter: {[float(x)+24 for x in config.input_power_dBm]}")
        input("Press Enter to continue...")   
#end region

#region Initialize Instruments
    loadtuner = MY982AU(config.loadtuner_config.port, config.loadtuner_config.sn)
    loadtuner.connect()
    if not loadtuner.connected:
        exit()
    loadtuner.set_cal(config.loadtuner_config.calfile)
    loadtuner.set_freq(str(float(config.frequency[0])*1e9))
    loadtuner.checkError
    pm = HP_E4419B("GPIB1::13::INSTR")
    pm.inst.timeout = 10000
    pna = Agilent_PNA_E8300("GPIB1::16::INSTR")
    pna.set_freq_start((float(config.frequency[0])*1e9))
    pna.set_freq_end((float(config.frequency[0])*1e9))	
    pna.write("SENS:SWE:POIN 1")
    pna.init_loadpull()
    pna.set_power(-27)
    dmm = Keysight34400()
    dmm.set_measurement("voltage-dc")
#end region

    columns = ('Power (dB/dBm)')
    rows = ['DUT Input (dBm)','DUT Output (dBm)','Gain','Bias','Pin']
    if not (options.force): 
        input("Press Enter to continue...")

    if options.verbose:
        text_trap = io.StringIO()
    sys.stdout = text_trap

    fig = plt.figure(constrained_layout=True)

    for freq in config.frequency:

        if options.plot:
            plt.close(fig) 
            fig = plt.figure(constrained_layout=True)
            axs = fig.subplot_mosaic([['Power','OutputIL','Coupling'],[ 'Gamma','MeasTable', 'MeasTable']],
                                per_subplot_kw={"Gamma": {"projection": "polar"}})
            axs['Power'].set_title('Power')
            axs['Gamma'].set_title('Gamma')
            axs['OutputIL'].set_title('Output Insertion Loss')
            axs['Coupling'].set_title('Output Coupling')
            axs['MeasTable'].set_title('Power Values')
            axs['Gamma'].grid(True)
            line[0], = axs['Gamma'].plot([], [], marker='o', ms=1, linewidth=0)
            line[1], = axs['Power'].plot([min(config.input_power_dBm), max(config.input_power_dBm)],[20, -30], marker='o', ms=4, linewidth=0,label='Input')
            line[2], = axs['Power'].plot([min(config.input_power_dBm), max(config.input_power_dBm)],[20, -30], marker='o', ms=4, linewidth=0,label='Output')
            axs['Power'].legend()
            axs['Coupling'].plot(config.freqs_IL,config.output_coupling, linewidth=3)
            axs['OutputIL'].plot(config.freqs_IL,config.output_IL, linewidth=3)
            fig.suptitle(f'Sampler Characterization for {freq} GHz', fontsize=16)
            output_power_plot = np.array([])
            input_power_plot = np.array([])
            set_power_plot = np.array([])
            gammaload_plot = np.array([]).astype(complex)
            meas_power_plot = np.array([])
            line[0].set_data([np.angle(gammaload_plot)], [np.abs(gammaload_plot)])

#region Set Instrumentation and Data to Frequency
        pna.set_freq_start((float(freq)*1e9))
        pna.set_freq_end((float(freq)*1e9))	
        pm.set_freq((float(freq)*1e9))	
        loadtuner.set_freq(str(float(freq)*1e9))
        loadtuner.checkError

        #file generation
        output_file = output_dir + f"\\{now}_{freq}GHz.json"
                with open(output_file, 'w') as f:
            json.dump(config_data, f, indent = 4)
        data = config_data

        #Get calibration coefficients (power and sparameters)
        error_terms = config.get_error_terms_freq(freq)
        coupling = config.get_comp_freq(freq)
        
#endregion

        for idx, bias in enumerate(config.sampler1.bias):
            dc_supply.setvoltage(bias)

            if options.plot:
                sampler1_plot = np.array([])
                sampler2_plot = np.array([])
                line[2*idx+2], = axs['Samplers'].plot([min(config.input_power_dBm), max(config.input_power_dBm)],[-1, -1], marker='o', ms=4, linewidth=0,label='Sampler 1')
                line[2*idx+3], = axs['Samplers'].plot([min(config.input_power_dBm), max(config.input_power_dBm)],[-1, -1], marker='o', ms=4, linewidth=0,label='Sampler 2')

            for power in tqdm(config.input_power_dBm):
    #region Set input power
                if config.specifyDUTinput:
                    set_Pin_DUT(pna, coupling, power)
                else:
                    pna.set_power(power)
    #endregion
                for i in range(5):
                    if not loadtuner.connected:
                        print("There is an error")
                        exit()

                    if i == 1:
                        time.sleep(1)
                        datatemp = {'PNA Power: '+ str(power) + str(i): 
                                    {'wave data': pna.get_loadpull_data(),
                                    'Gamma Load': {'real': gammaload.real,
                                        'imag': gammaload.imag},
                                    'Power Meter': pm.get_power(),
                                    'Samplers':{
                                        '1': dmm1.get_voltage()
                                        '2': dmm2.get_voltage()
                                        'Bias': dc_supply.get_voltage()},                                    }
                                    }
                        pm.write("INIT:CONT")
                        dmm1.write("INIT:CONT")
                        dmm2.write("INIT:CONT")
                    else:
                        datatemp = {'PNA Power: '+ str(power) + str(i): 
                                    {'wave data': pna.get_loadpull_data(),
                                    'Gamma Load': {'real': gammaload.real,
                                        'imag': gammaload.imag},
                                    'Power Meter': pm.fetch_power(),
                                    'Samplers':{
                                        '1': dmm1.fetch_voltage()
                                        '2': dmm2.fetch_voltage()
                                        'Bias': dc_supply.get_voltage()},                                    }
                                    }
                    data.update(datatemp)

                    with open('temp.json', 'w') as f:
                        json.dump(data,f,indent=4)

                    os.remove(output_file)
                    shutil.copyfile('temp.json', output_file)

                    if options.plot:
                        updateplot(axs,line,meas_power, datatemp,coupling,idx)
                        plt.pause(0.25)
                        fig.canvas.draw()
                        fig.canvas.flush_events()
pna.set_power(-27)
pna.close()
loadtuner.close()
pm.close()