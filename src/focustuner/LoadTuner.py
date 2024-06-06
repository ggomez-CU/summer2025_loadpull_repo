"""
Created on Mon Jul 02 13:18:38 2012

Tuner Instrument Class

@author: srschafer

Updated to Python 3, PEP 8 style and for Windows 10 by Devon Donahue
Nov 2018

Updated for CCMT-1808 ituner (class renamed; `tuneto`, `loadfreq` functions
added, communication with ituner changed) by Devon Donahue
July-August 2021
"""
import sys
import time
import re
import socket
import warnings
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

class TunerCongifuration:
    def __init__(self, SN, IP, step_size, cross_over_freq, axis_limits):
        """
        Tuner configration class. Called from config in Tuner class and automatically defined.

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

def set_DHCP():
    print('Changing IP to DYNAMIC address')
    subprocess.call(
        'netsh interface ipv4 set address "Ethernet" dhcp',
        shell=True,
        )
    return


class BreakHandler:
    """
    Trap CTRL-C, set a flag, and keep going.  This is very useful for
    gracefully terminating Tuner communication.

    To use this, make an instance and then enable it.  You can check
    whether a break was trapped using the trapped property.
    """

    def __init__(self, emphatic=3):
        """``BreakHandler(emphatic=3)``

        Create a new break handler.

        Parameters
        ----------
        emphatic : int
            This is the number of times that the user must press break to
            *disable* the handler.  If you press break this number of times,
            the handler is  disabled, and one more break will trigger an old
            style keyboard interrupt.
        """
        self._count = 0
        self._enabled = False
        self._emphatic = emphatic
        self._oldhandler = None
        return

    def _reset(self):
        """
        Reset the trapped status and count.  You should not need to use this
        directly; instead you can disable the handler and then re-enable it.
        """
        self._count = 0
        return

    def enable(self):
        """
        Enable trapping of the break.  This action also resets the
        handler count and trapped properties.
        """
        if not self._enabled:
            self._reset()
            self._enabled = True
            self._oldhandler = signal.signal(signal.SIG_IGN, self)
        return

    def disable(self):
        """
        Disable trapping the break.  You can check whether a break
        was trapped using the count and trapped properties.
        """
        if self._enabled:
            self._enabled = False
            signal.signal(signal.SIG_IGN, self._oldhandler)
            self._oldhandler = None
        return

    def __call__(self, signame, sf):
        """
        An break just occurred.  Save information about it and keep
        going.
        """
        self._count += 1
        # If we've exceeded the "emphatic" count disable this handler.
#        if self._count >= self._emphatic:
#            self.disable()
        return

    def __del__(self):
        # self.disable()
        return

    @property
    def count(self):
        """The number of breaks trapped."""
        return self._count

    @property
    def trapped(self):
        """Whether a break was trapped."""
        return self._count > 0


class Tuner:
    def __init__(self, 
        address, 
        timeout = 30,
        port = 23):
        """
        Control object for ethernet-controlled Focus tuners.

        Parameters
        ----------
        address : string
            TCPIP address of tuner.
        port : int
            port of IP address, default is TELNET 23 (def=23).  If not
            specified, will use the class constructor port number.
        """
        self.address = str(address)
        self.connected = False
        self.port = str(port)
        self.xPos = -1
        self.yPos = -1
        self.timeout = 1000 #1 second
        self.instr = None

        self.kbInt = BreakHandler()
        return

    def connect(self, address = False, port=None):
        """
        Initialize tuner.

        Parameters
        ----------
        address : string
            TCPIP address of tuner.  Will change the default (stored) ip
            address in the class. If not specified, will use the class
            constructor address.
        port : str, optional
            Port of IP address, default is TELNET 23 (def=23).  If not
            specified, will use the class constructor port number.
        """
        print('Attempting connection... ', end='')

        if (address):
            self.address = address
        if (port):
            self.port = port

        rm = pyvisa.ResourceManager()
        dev = 'TCPIP0::' + self.address + '::' + self.port + '::SOCKET'

        try:
            self.instr = rm.open_resource(dev)
        except Exception as e: 
            print('connection unsuccessful')
            self.connected = False
            print("Something is wrong with %s::%d. Exception is %s" % (self.address, port, e))
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
                print("Something is wrong with %s:%d. Exception is %s" % (address, port, e))
            else:
                self.configure()
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
        self.configuration = TunerCongifuration(SN, IP, step_size, cross_over_freq, axis_limits)
        
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
        if (axis == '1' and abs(self.pos()[0] - position) < self.configuration.step_size):
            # already there, return
            return
        elif (axis == '2' and abs(self.pos()[1] - position) < self.configuration.step_size):
            # already there, return
            return
        elif (axis == '3' and abs(self.pos()[2] - position) < self.configuration.step_size):
            # already there, return
            return

        # Send the command to move slug
        print(self.instr.query('POS ' + axis + ' ' + str(int(position))))

        # Return the tuner position
        return self.pos

    def tuneto(self, magnitude, phase):
        """tuneto(magnitude, phase)

        Tune to specific reflection coefficient.  Wait until tuned.

        Parameters
        ----------
        mag : float
            Desired reflection coefficient magnitude.
        phase : float
            Desired reflection coefficient phase (in degrees).

        Returns
        -------
        None
        """
        if (not self.instr):
            err = ('TunerClass:', sys._getframe(0).f_code.co_name, ':'
                   ' Connection Error')
            raise SystemError(err)

        # Send the command to tune.
        print('iTuner tuning... ', end='')
        # self.instr.send(
        #     ('TUNETO ' + str(magnitude) + ' ' + str(phase) + '\r\n').encode()
        #     )
        self.instr.query('TUNETO ' + str(magnitude) + ' ' + str(phase))
        self.waitForReady()
        print('done')

        return

    def calpoint(self, index):
        """tuner_calpoint(index)

        Tune to calibration point.  Wait until tuned.

        Parameters
        ----------
        index: int
            the index of the desired calibration point. Must be within the range of the number of points within the loaded cal

        Returns
        -------
        None
        """
        if (not self.instr):
            err = ('TunerClass:', sys._getframe(0).f_code.co_name, ':'
                   ' Connection Error')
            raise SystemError(err)

        # Send the command to tune.
        print('iTuner tuning... ', end='')
        # self.instr.send(
        #     ('CALPOINT ' + str(int(index))  + '\r\n').encode()
        #     )
        self.instr.query('CALPOINT ' + str(int(index)))
        self.waitForReady()
        print('done')

        return

    def loadfreq(self, freq):
        """tuner_loadfreq(freq)

        Load tuner calibration at specified frequency (in GHz).

        Parameters
        ----------
        freq : float
            Frequency of saved calibration.

        Returns
        -------
        None
        """
        if (not self.instr):
            err = ('TunerClass:', sys._getframe(0).f_code.co_name, ':'
                   ' Connection Error')
            raise SystemError(err)

        # Send the command to load calibration.
        print('iTuner loading calibration... ', end='')
        # self.instr.send((
        #     'LOADFREQ '
        #     + str(round(freq*1e-6))
        #     + '\r\n'
        #     ).encode())
        self.instr.query('LOADFREQ ' + str(round(freq*1e-6)))
        self.waitForReady()
        print('done')

        return

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
