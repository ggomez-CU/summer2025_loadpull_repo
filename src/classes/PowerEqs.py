import numpy as np
import time

def get_percent_error_DUTout(loadZ:complex, power_meter_dBm, output_comped_dBm):
    # returns a percentage
    gamma = (loadZ-50)/(loadZ+50)
    expected = power_meter_dBm + 20*np.log10(abs(gamma))
    return abs(output_comped_dBm - expected)/output_comped_dBm*100

def get_Pin_comp(rf, coupling, input_desired):
    return (input_desired-(rf['input_awave']['dBm_mag'][0]+coupling['input coupling']))

def set_Pin(pna, coupling, input_desired, tolerance=0.1, max_limit_pna=2, min_limit_pna=-27):
    rf = pna.get_loadpull_data()
    error = get_Pin_comp(rf, coupling, input_desired)
    current_power = pna.get_power()
    print(f"Setting power to {input_desired},", end="")
    while(abs(error) > tolerance):
        if (current_power + error) > max_limit_pna:
            print(f"Attempted power exceeds specified limit of {max_limit_pna}: dBm")
            return 1
        if (current_power + error) < min_limit_pna:
            print(f"Attempted power less than minimum specified limit of {min_limit_pna}: dBm")
            return 1
        pna.set_power(current_power + error)
        time.sleep(0.5)
        current_power = pna.get_power()
        print(f"{current_power},", end="")
        rf = pna.get_loadpull_data()
        error = get_Pin_comp(rf, coupling, input_desired)
    return 0

def get_PA_metrics(dc:dict, rf:dict, coupling:dict):
    rf_input = rf['input_awave']+coupling['input coupling']
    rf_output = rf['output_bwave']+coupling['output coupling']
    Pdc = dc['gate current']*dc['gate voltage']+ dc['drain current']*dc['drain voltage']
    return {'Gain': rf_output-rf_input,
            'PAE': (rf_output-rf_input)/Pdc}