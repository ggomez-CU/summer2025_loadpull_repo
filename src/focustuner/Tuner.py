"""
Created on Mon Jul 02 13:18:38 2012

Tuner Instrument Class

@author: srschafer

Updated to Python 3, PEP 8 style and for Windows 10 by Devon Donahue
Nov 2018

Updated for CCMT-1808 ituner (class renamed; `tuneto`, `loadfreq` functions
added, communication with ituner changed) by Devon Donahue
July-August 2021

Updated to use pyvisa instead of socket. Removed the tuneto, loadfreq and 
load cal function because the FDCS software was not giving reproducible 
calibrations so it was not worth rewriting. Old functions are saved in _Tuner.txt.
By Grace Gomez
June 2024
"""
import sys
import time
import re
import socket
import warnings
# from pylogfile.base import *
import signal
import subprocess
import pyvisa

def set_staticIP():
    print('Changing IP to STATIC address')
    subprocess.call(
        'netsh interface ipv4 set address name="Ethernet" static 10.0.0.100'
        ' 255.255.255.0',
        shell=True,
        )
    time.sleep(3)
    return

def set_DHCP():
    print('Changing IP to DYNAMIC address')
    subprocess.call(
        'netsh interface ipv4 set address "Ethernet" dhcp',
        shell=True,
        )
    return

class TunerConfiguration:
    def __init__(self, SN, IP, step_size, cross_over_freq, axis_limits):
        """
        Tuner configuration class. Called by  Tuner class in self.config() and automatically defines 
        load tuner parameters by querying "CONFIG?" to the load tuner connected

        Parameters
        ----------
        SN: str
            Serial Number
        IP: str
            IP address
        step_size: str
            Maximum step size of the load tuner um
        cross_over_frequency: float in MHz
            Frequency from low to high frequency x axis (see manual for vswr details)
        axis_limits: int array
            Limits of the three axis (x, y low frequency, y high frequency)
        """
        self.SN = SN 
        self.IP = IP
        self.step_size = step_size
        self.cross_over = cross_over_freq
        self.axis_limits = axis_limits
        return

class Tuner:
    def __init__(self, address = '10.0.0.1', timeout=1000 , port=23):
            # log:LogPile=None
        """
        Control object for ethernet-controlled Focus tuners.

        Parameters
        ----------
        address : string
            IP address of tuner
        timeout: int
            time out in ms (def=1000)
        port : int
            port of IP address, default is TELNET 23 (def=23).  If not
            specified, will use the class constructor port number.
        log : LogPile
            log of the protocol and errors saved to text files. (def=None)
        """
        self.address = str(address)
        self.connected = False
        self.port = str(port)
        self.xPos = -1
        self.y_highPos = -1
        self.y_lowPos = -1
        self.timeout = timeout #In milliseconds
        self.instr = None
        # self.log = log
        return

    def connect(self, address = False, port=None, configure:TunerConfiguration=None):
        """
        Initialize tuner.

        Parameters
        ----------
        address : string
            IP address of tuner.  Will change the default (TunerConfiguration) IP
            address
        port : str, optional
            Port of IP address, default is TELNET 23 (def=23).  If not
            specified, will use the class constructor port number.
        """
        print('Attempting connection... ', end='')

        if (address):
            self.address = address
        if (port):
            self.port = port

        set_staticIP()

        rm = pyvisa.ResourceManager()
        dev = 'TCPIP0::' + self.address + '::' + self.port + '::SOCKET'

        try:
            self.instr = rm.open_resource(dev)
        except Exception as e: 
            print('connection unsuccessful')
            self.connected = False
            print("Exception is %s" % (e))
        except:
            print("Failure Unknown")
        else: 
            self.instr.read_termination = 'CCMT->'
            self.instr.write_termination = '\r\n'
            self.instr.timeout = self.timeout
            self.instr.query_delay = .2
            print('connection successful')
            print('Attempting to initialize tuner... ', end='')
            try:
                self.instr.read()
                time.sleep(2)
                self.instr.query('INIT')
            except Exception as e:
                print('initialization unsuccessful')
                self.connected = False
                print("Exception is %s" % (e))
            if (configure == None):
                try:
                    self.configure()
                except Exception as e:
                    print("Exception is %s" % (e))
            else:
                self.configuration = configure
            print('initialization successful')
            self.connected = True
        finally:
            return self.connected

    def configure(self):
        """
        Configure parses the configuration returned 
            from the load tuner and saves the data 
            in the form of a TunerConfiguration class 
        """

        print("Configuring load tuner...",end="")
        
        config_string = self.instr.query('CONFIG?')
        
        SN = re.findall('SN#: \\d+', config_string)[0]
        IP = re.findall('IP: \\d+\\.\\d+\\.\\d+\\.\\d+', config_string)[0]
        step_size = float(re.findall('Step Size: \\d+\\.\\d+', config_string)[0].split('Step Size: ')[1])
        cross_over_freq = float(re.findall('CrossOver:\\d+\\.\\d+', config_string)[0].split('CrossOver:')[1])
        axis1 = re.findall('#1\t1\t\\d+', config_string)[0].split('#1\t1\t')[1]
        axis2 = re.findall('#2\t2\t\\d+', config_string)[0].split('#2\t2\t')[1]
        axis3 = re.findall('#3\t3\t\\d+', config_string)[0].split('#3\t3\t')[1]
        axis_limits = [int(axis1), int(axis2), int(axis3)]
        self.configuration = TunerConfiguration(SN, IP, step_size, cross_over_freq, axis_limits)

        print(" done... ",end='')
        
        return

    def close(self):
        """
        Close tuner communication.
        """

        print('Closing tuner connection... ', end='')

        try:
            self.instr.close()
        except Exception as e:
            print(e)
            self.connected = None
        else:
            print("done")
            self.instr = None
            self.connected = False
        finally:
            set_DHCP()
            return self.connected

    def move(self, axis, position):
        """move(axis, position)

        Move Tuner X or Y slug.  Wait until moved.

        Parameters
        ----------
        axis : string
            'X' or 'Y'.  Corresponds to the single movable slug.
        position : int
            positive integer.  Position to move to limited by
            TunerClass.xMax and TunerClass.yMax

        Returns
        -------
        pos : (xPos, yPos) tuple representing the position according to the
            tuner
        """
        self.waitForReady()
        self.pos()  #Update current position
        self.waitForReady()
        print("Moving...")
        # check position against axis limits
        if (axis.lower() == 'x'):
            axis = '1'
            if (position > self.configuration.axis_limits[0]  or position < 0):
                raise SystemError('Exceeds X position limit, tuner not moved!')
        elif (axis.lower() == 'y_low'):
            axis = '2' 
            if (position > self.configuration.axis_limits[1]  or position < 0):
                raise SystemError('Exceeds Y low position limit, tuner not moved!')
        elif (axis.lower() == 'y_high'):
            axis = '3' #for higher frequency operation
            if (position > self.configuration.axis_limits[2] or position < 0):
                raise SystemError('Exceeds Y high position limit, tuner not moved!')
        else:
            warnings.warn('Invalid axis, tuner not moved!')
            return self.pos()

        # Open a connection to the tuner
        if (axis == '1' and (abs(self.xPos - position) < self.configuration.step_size)):
            # already there, return
            return
        elif (axis == '2' and (abs(self.y_lowPos - position) < self.configuration.step_size)):
            # already there, return
            return
        elif (axis == '3' and (abs(self.y_highPos - position) < self.configuration.step_size)):
            # already there, return
            return

        # Send the command to move slug
        print(self.instr.query('POS ' + axis + ' ' + str(int(position))))

        # Return the tuner position
        return self.pos()

    def status(self):
        """status()

        Check 'STATUS?' of tuner.

        Parameters
        ----------
        none

        Returns
        -------
        statusCode : status string
        """

        return_string = self.instr.query('STATUS?')
        status_string = re.search('STATUS:.*\nResult=.*ID#', return_string)
        if status_string is not None:
            status_code = int(status_string.group().split('0x000')[1].split(' ')[0])
        else:
            status_code = 1
        return status_code

    def pos(self):
        """[x, y] = pos()

        Check 'POS?' (position) slugs.

        Returns
        -------
        [x, y] : int
            Position of slugs.
        """
        self.waitForReady()
        return_string = self.instr.query('POS?')
        parsed = re.findall('A\\d=\\d+', return_string)
        self.xPos = int(parsed[0].split('=')[1])
        self.y_lowPos = int(parsed[1].split('=')[1])
        self.y_highPos = int(parsed[2].split('=')[1]) #for higher frequencies

        return [self.xPos, self.y_lowPos, self.y_highPos]

    def waitForReady(self):
        """waitForReady(timeout=tuner.timeout)

        Wait until Status Code is 0.

        Parameters
        ----------
        timeout : int
            Time in seconds to wait for Result string (def=tuner.timeout).

        Returns
        -------
        none
        """
        timeout = self.timeout
        starttime = time.time()
        status_code = self.status()
        lastQuery = 0
        queryRepeat = 0.25

        # if status_code > 3:
        #     print("Unaccepted status: " + str(status_code) + " Tuner likely needs to be power cycled")
        # else:
        while (time.time() - starttime < timeout and status_code):
            time.sleep(queryRepeat)
            try:
                self.instr.read()
            except: pass
            status_code = self.status()
            print("Status: " + str(status_code))

        if (status_code != 0):
            print('TunerClass: ERROR Ready Timeout')
            print('   ', sys._getframe(2).f_code.co_name, ':',
                sys._getframe(1).f_code.co_name,
                sys._getframe(0).f_code.co_name)
            try:
                self.close()
            except: pass
            else:
                exit()
        return status_code

#   {o.O}
#   (  (|
# ---"-"-
