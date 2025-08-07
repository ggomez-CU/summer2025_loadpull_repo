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
from optparse import OptionParser
import io
import math
def updateplot(axs, line, data, coupling, idx):
    keys_list = list(data.keys())

    outputdBm =  round(data[keys_list[0]]['wave data']['output_bwave']['dBm_mag'][0]+coupling['output coupling'],3)
    inputdBm = round(data[keys_list[0]]['wave data']['input_awave']['dBm_mag'][0]+coupling['input coupling'],3)
    plots['set_power'] = np.append(plots['set_power'],inputdBm)
    plots['power_PAE'] = np.append(plots['power_PAE'],data[keys_list[0]]['PA Performance']['PAE'])
    plots['power_gain'] = np.append(plots['power_gain'],data[keys_list[0]]['PA Performance']['Gain'])
    plots['sampler1'] = np.append(plots['sampler1'],data[keys_list[0]]['Samplers']['1'])
    plots['sampler2'] = np.append(plots['sampler2'],data[keys_list[0]]['Samplers']['2'])

    load = complex(data[keys_list[0]]['load_gamma']['real'],data[keys_list[0]]['load_gamma']['imag'])

    plots['gammaload'] = np.append(plots['gammaload'],load)

    line[0][0].set_data([np.angle(plots['gammaload'])], [np.abs(plots['gammaload'])])
    line[6*idx+1][0].set_data(plots['set_power'],plots['power_gain'])
    line[6*idx+2][0].set_data(plots['set_power'],plots['power_PAE'])
    line[6*idx+5][0].set_data(plots['set_power'],plots['sampler1'])
    line[6*idx+6][0].set_data(plots['set_power'],plots['sampler2'])
    axs['MeasTable'].cla()
    axs['MeasTable'].axis('off')
    axs['MeasTable'].table(cellText=[[inputdBm],
            [outputdBm],
            [outputdBm-inputdBm],
            [round(data[keys_list[0]]['PA Performance']['PAE'],3)],
            [round(data[keys_list[0]]['Input Power'],3)],
            [round(10*np.log10(data[keys_list[0]]['PA Performance']['DC Power'])+30,3)],
            [round(data[keys_list[0]]['Samplers']['1'],3)],
            [round(data[keys_list[0]]['Samplers']['2'],3)]],
            rowLabels=rows,
            colLabels=columns,
            loc='center')

def main(config, options, visa_instrs):

    now = datetime.now().strftime("%Y-%m-%d_%H_%M")
    upper_output_dir = os.getcwd() + "\\data\\PA_Spring2023\\LoadPullBiasing" \
            + now + "_Freq" \
            + str(config.frequency[0]) + "to" + str(config.frequency[-1])
    os.mkdir(upper_output_dir)

    if not options.informal:
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

    config_file = upper_output_dir + "\\config_file.json"
    config_data = output_file_test_config_data(config_file, config, now, paragraph)
    
    if not (options.force): 
        print(" ==========\tTEST CONFIGURATION\t========== ")
        print(json.dumps(config_data, indent=4))
        print('\n\n')
        if config.specifyDUTinput:
            print(f"Estimated Pout of the PreAmp: {[float(x) for x in config.input_power_dBm]}")
        else:
            print(f"Estimated Pout of the PreAmp: {[float(x)+30 for x in config.input_power_dBm]}")  
        expected_test_time(config)

    columns = ('Power (dB/dBm)')
    rows = ['DUT Input (dBm)','DUT Output (dBm)','Gain','PAE','Pin','Pdc','Sampler 1','Sampler 2']

    if not options.verbose:
        text_trap = io.StringIO()
        sys.stdout = text_trap

    fig = plt.figure(constrained_layout=True)

    for idx, bias in enumerate(config.gatebiasvoltage):
        visa_instrs.pna.power_off()
        visa_instrs.dc_supply.set_channel(config.dc_supply_config.gate_channel,bias,0.1) #channel voltage current
        dc_init = {"Initial DC Parameters":
                get_PA_dc(visa_instrs.dc_supply, 
                                                    config.dc_supply_config.gate_channel, 
                                                    config.dc_supply_config.drain_channel) 
            }
        visa_instrs.pna.power_on()
        config_bias = config_data
        lower_output_dir = upper_output_dir + f'\\draincurrent_{round(dc_init["Initial DC Parameters"]["drain current"]*1000,3)}mA'
        os.mkdir(lower_output_dir)
        if options.plot:
            plt.close(fig) 
            fig = plt.figure(constrained_layout=True)
            axs = fig.subplot_mosaic([['Power','Frequency','Gamma'],[ 'Samplers','MeasTable', 'MeasTable']],
                                per_subplot_kw={"Gamma": {"projection": "polar"}})
            axs['Power'].set_title('Over Power')
            axs['Gamma'].set_title('Gamma')
            axs['Samplers'].set_title('Samplers')
            axs['Frequency'].set_title('Over Frequency')
            axs['MeasTable'].set_title('Power Values')
            axs['Gamma'].grid(True)
            line = []
            line.append(axs['Gamma'].plot([], [], marker='o', ms=1, linewidth=0))
            fig.suptitle(f'PA Drive Up', fontsize=16)
            plots = {}

        for idx, freq in enumerate(config.frequency):
            
    #region Set Instrumentation and Data to Frequency
            visa_instrs.pna.set_freq_start((float(freq)*1e9))
            visa_instrs.pna.set_freq_end((float(freq)*1e9))	
            visa_instrs.pm.set_freq((float(freq)*1e9))	
            visa_instrs.loadtuner.set_freq(str(float(freq)*1e9))
            visa_instrs.loadtuner.checkError()

            #file generation
            output_file = lower_output_dir + f"\\{now}_{freq}GHz_{round(dc_init["Initial DC Parameters"]["drain current"]*1000,3)}mA.json"

            with open(output_file, 'w') as f:
                json.dump(config_bias, f, indent = 4)
            data = config_bias

            #Get calibration coefficients (power and sparameters)
            error_terms = config.get_error_terms_freq(freq)
            coupling = config.get_comp_freq(freq)
            
    #endregion

            if options.plot:
                line.append(axs['Power'].plot([min(config.output_power_dBm), max(config.output_power_dBm)],[-0.05, 0.5], marker='o', ms=4, linewidth=0,label='Gain'))
                line.append(axs['Power'].plot([min(config.output_power_dBm), max(config.output_power_dBm)],[0, 50], marker='o', ms=4, linewidth=0,label='PAE'))
                line.append(axs['Frequency'].plot([min(config.frequency), max(config.frequency)],[-0.05, 0.5], marker='o', ms=4, linewidth=0,label='Gain'))
                line.append(axs['Frequency'].plot([min(config.frequency), max(config.frequency)],[0, 50], marker='o', ms=4, linewidth=0,label='PAE'))
                line.append(axs['Samplers'].plot([min(config.output_power_dBm), max(config.output_power_dBm)],[0, .150], marker='o', ms=4, linewidth=0,label='Sampler 1'))
                line.append(axs['Samplers'].plot([min(config.output_power_dBm), max(config.output_power_dBm)],[0, .15], marker='o', ms=4, linewidth=0,label='Sampler 2'))
                
                axs['Frequency'].legend()
                axs['Power'].legend()
                plots.update({'power_gain': np.array([])})
                plots.update({'power_PAE': np.array([])})
                plots.update({'set_power': np.array([])})
                plots.update({'gammaload': np.array([])})
                plots.update({'sampler1': np.array([])})
                plots.update({'sampler2': np.array([])})

            string = str(round(freq,3)) + " GHz"
            time.sleep(2)

            for power in tqdm(config.input_power_dBm, ascii=True, desc=string):

                if config.specifyDUTinput:
                    set_Pin(visa_instrs.pna, coupling, power)
                else:
                    visa_instrs.pna.set_power(power)

                for loadpoint in config.loadpoints:

                    visa_instrs.loadtuner.set_gamma_complex(loadpoint)
                    for i in range(1):
                        if not visa_instrs.loadtuner.connected:
                            print("There is an error")
                            exit()
                        print("Taking data")
                        time.sleep(1)
                        try:
                            rf_data = visa_instrs.pna.get_loadpull_data()
                            dc_data = get_PA_dc(visa_instrs.dc_supply, 
                                                            config.dc_supply_config.gate_channel, 
                                                            config.dc_supply_config.drain_channel)             
                            datatemp = {'Load Point: '+ str(loadpoint) + '_' + str(i): 
                                        {'load_gamma': 
                                            {'real': loadpoint.real,
                                            'imag': loadpoint.imag},
                                        'wave data': rf_data,
                                        'Power Meter': visa_instrs.pm.get_power(),
                                        'Input Power': visa_instrs.pna.get_power(),
                                        'Samplers':{
                                            '1': visa_instrs.dmm1.fetch_voltage(),
                                            '2': visa_instrs.dmm2.fetch_voltage(),
                                            'Bias': visa_instrs.dc_supply.get_voltage(config.dc_supply_config.sampler_channel),
                                            'Bias Current': visa_instrs.dc_supply.get_current(config.dc_supply_config.sampler_channel)
                                            },
                                        'PA Performance':get_PA_metrics(dc_data,rf_data,coupling),
                                        'DC Parameters':dc_data
                                        }}
                            visa_instrs.pm.write("INIT:CONT")
                            data.update(datatemp)

                            with open('temp.json', 'w') as f:
                                json.dump(data,f,indent=4)

                            os.remove(output_file)
                            shutil.copyfile('temp.json', output_file)

                            if options.plot:
                                updateplot(axs, line, datatemp, coupling, (idx))
                                plt.pause(0.25)
                                fig.canvas.draw()
                                fig.canvas.flush_events()

                        except Exception as e:
                            print(f"Failed to collect data: {e}")
                # line[6*idx+3][0].set_data(np.full(len(plots['power_gain']),float(freq)),plots['power_gain'])
                # line[6*idx+4][0].set_data(np.full(len(plots['power_PAE']),float(freq)) ,plots['power_PAE'])
                

if __name__ == "__main__":
    print("Program started. Press Ctrl+C to exit gracefully.")
    parser = OptionParser(
            description="Specifies User outputs and test validation on or off"
        )
    parser.add_option("-p", "--plot",
                  action="store_true", dest="plot", default=False,
                  help="plot output data while running tests")
    parser.add_option("-f", "--force",
                  action="store_true", dest="force", default=False,
                  help="Run without checking valid config")
    parser.add_option("-v", action="store_true", dest="verbose", default=True)
    parser.add_option("-q", action="store_false", dest="verbose",
                  help="don't print status messages to stdout")
    parser.add_option("-i", "--informal",
                  action="store_true", dest="informal", default=False,
                  help="no comment from user when initiated. Makes understanding the data harder later")
    (options, args) = parser.parse_args()

    print(f"This test will run as quiet {options.verbose} forced {options.force} and plotted {options.plot}")
    config = MMICDriveUpBiasConfig(r"C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\PA_Spring2023\MMIC_driveupbias_config.json")
    visa_instrs = VisaInstrsClass(config)

    try:
        main(config, options, visa_instrs)
    except KeyboardInterrupt:
        print("\nKeyboardInterrupt caught. Shutting down gracefully...")
    except Exception as e:
        print(f"Failed to execute: {e}")
    finally:
        print("Performing cleanup operations...")
        visa_instrs.clean_shutdown()
        print("Cleanup complete. Exiting program.")
        sys.exit(0) # Exit with status code 0 (success)