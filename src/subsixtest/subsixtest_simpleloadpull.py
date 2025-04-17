"""
Created on 4/2/2025

Simple Loadpull Sub6 Testbench

@author: Grace Gomez

This is a python script for running a single power and single frequency (simple) load pull on the CU Boulder RFPAL ZVA Sub 6 GHz test bench 

"""
from classes import *

from focustuner.Tuner import Tuner
from pylogfile.base import *
from tqdm import tqdm
from datetime import datetime
import shutil
import os

if __name__ == "__main__":

    config_filename = find_config_file()
    log = LogPile()
    config = SimpleLoadpullConfig(config_filename, log)
    position_cal = LoadTunerCalCalc()

    #Initialize instruments and log pile
    loadtuner = Tuner(config.loadtuner_config.IP_address, 
                          config.loadtuner_config.timeout , 
                          config.loadtuner_config.port, 
                          config.loadtuner_config.printstatements)
    loadtuner.connect()

    print(loadtuner.cal)

    loadtuner.load_cal_freq(3) #Frequency in GHz
    zva = RohdeSchwarzZVA("TCPIP0::10.0.0.10::INSTR", log)
    zva.init_zva_subsix_loadpull(config.ZVA_config, log)

    expected_test_time(config)

    now = datetime.now().strftime("%Y-%m-%d_%H_%M")
    output_file = os.getcwd() + "\\data\\simpleloadpull\\" \
            + now + "_Freq" \
            + str(config.frequency[0]) \
            + "_Pow" + str(config.input_power_dBm[0]) \
            + ".json"
    
    data = output_file_test_config_data(output_file, config, now)
    
    ## Need to set ZVA power and frequency

    print(data)
    print(type(data))

    for loadpoint in tqdm(config.loadpoints):
        # loadtuner.move_Z(loadpoint)
        loadtuner.move('x', position_cal.linear_phi_pos(np.angle(loadpoint)))
        loadtuner.move('y_low', position_cal.linear_gamma_pos(abs(loadpoint)))

        data.update({'Load Point: '+ str(loadpoint): 
                     {'load_impedance': loadpoint, 'wave_data': zva.get_loadpull_data()} 
                     })

        with open('temp.json', 'w') as f:
            json.dump(data,f,indent=4)

        os.remove(output_file)
        shutil.copyfile('temp.json', output_file)
    



    


