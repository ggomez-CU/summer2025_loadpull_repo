''' Driver for Keysight 34400 series digital multimeters. 

https://www.keysight.com/us/en/assets/9018-03876/service-manuals/9018-03876.pdf?success=true 
'''

import array
from .base import *
from .digital_multimeter_ctg import *

class Keysight_34400(DigitalMultimeterCtg1):
	
	def __init__(self, address:str):
		super().__init__(address) 
		
		# Unit to make sure is matched by returned string
		self.check_units = ""
	
	def set_low_power_mode(self, enable:bool, four_wire:bool=False):
		''' If enable is true, sets the resistance measurement to be in low-power mode.'''
		
		# TODO: better four wire res measurmenet handling
		if four_wire:
			self.write(f"SENS:FRES:POW:LIM:STATE {bool_to_ONFOFF(enable)}")
		else:
			self.write(f"SENS:RES:POW:LIM:STATE {bool_to_ONFOFF(enable)}")
	
	def get_low_power_mode(self, four_wire:bool=False):
		''' If enable is true, sets the resistance measurement to be in low-power mode.'''
		
		# TODO: better four wire res measurmenet handling
		if four_wire:
			rval = self.query(f"SENS:FRES:POW:LIM:STATE?")
		else:
			rval = self.query(f"SENS:RES:POW:LIM:STATE?")
		
		return str_to_bool(rval)
		
	def set_measurement(self, measurement:str, meas_range:str=DigitalMultimeterCtg1.RANGE_AUTO):
		''' Sets the measurement, using a DitigalMultimeterCtg0 constant. 
		Returns True if successful, else false.
		'''
		
		# Get measurement string
		match measurement:
			case DigitalMultimeterCtg1.MEAS_RESISTANCE_2WIRE:
				mstr = "RES" 
				self.check_units = "OHM"
			case DigitalMultimeterCtg1.MEAS_RESISTANCE_4WIRE:
				mstr = "FRES"
				self.check_units = "OHM"
			case DigitalMultimeterCtg1.MEAS_VOLT_AC:
				mstr = "VOLT:AC" 
				self.check_units = "V"
			case DigitalMultimeterCtg1.MEAS_VOLT_DC:
				mstr = "VOLT:DC"
				self.check_units = "V"
			case _:
				self.log.error(f"Failed to interpret measurement argument '{measurement}'. Aborting.")
				return False
		
		# Get range string
		match meas_range:
			case DigitalMultimeterCtg1.RANGE_AUTO:
				rstr = "AUTO"
			case _:
				self.log.error(f"Failed to interpret meas_range argument '{meas_range}'. Defaulting to auto.")
				rstr = "AUTO"
		
		self.write(f"CONFigure:{mstr} {rstr}")
		
		return True
	
	def send_manual_trigger(self, send_cls:bool=True):
		''' Tells the instrument to begin measuring the selected parameter.'''
		
		if send_cls:
			self.write("*CLS")
		self.write(f"INIT:IMM")
	
	def get_last_value(self) -> float:
		''' Returns the last measured value. Will be in units self.check_units. Will return None on error '''
		
		str_val = self.query("DATA:LAST?")
		
		# Remove line endings
		str_val = str_val.strip()
		
		# Remove units from string
		first_space = str_val.find(' ') # Find first space
		last_space = str_val.rfind(' ') # Find last space
		
		# Get flaot data
		try:
			val = float(str_val[:first_space])
		except Exception as e:
			self.log.error(f"Failed to convert string data to gloat.", detail=f"({e})")
			return None
		
		# Check units
		try:
			unit_str = str_val[last_space+1:last_space+1+len(self.check_units)]
			if self.check_units != unit_str:
				self.log.error(f"Received wrong type of units. Aborting.", detail=f"Received '{unit_str}', expected '{self.check_units}'.")
				return None
		except Exception as e:
			try:
				unit_str = str_val[last_space+1:]
			except:
				unit_str = "??"
			
			self.log.error(f"Received wrong type of units. Aborting.", detail=f"Received '{unit_str}', expected '{self.check_units}' ({e}).")
			return None
		
		return val

	def trigger_and_read(self):
		''' Tells the instrument to read and returns teh measurement result. '''
		
		self.send_manual_trigger(send_cls=True)
		self.wait_ready()
		return self.get_last_value()

	def get_voltage(self):
		self.write("CONF:VOLT:DC")
		return float(self.query(f"READ?").replace("\n", ""))
	
	def fetch_voltage(self):
		return float(self.query(f"READ?").replace("\n", ""))