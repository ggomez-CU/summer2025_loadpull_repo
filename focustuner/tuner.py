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


class CCMT1808(object):
    def __init__(self, address, xMax, yMax, timeout=30,port=23):
        """
        Control object for ethernet-controlled Focus tuners.

        Parameters
        ----------
        address : string
            TCPIP address of tuner.
        xMax : int
            Maximum travel for X axis slug (def=1000)
        yMax : int
            Maximum travel for Y axis slug (def=1000)
        port : int
            port of IP address, default is TELNET 23 (def=23).  If not
            specified, will use the class constructor port number.
        """
        self.address = address
        self.connected = False
        self.port = port
        self.xMax = xMax
        self.yMax = yMax
        self.xPos = -1
        self.yPos = -1
        self.timeout = 30
        self.resultCode = 0
        self.instr = None

        self.kbInt = BreakHandler()
        return

    def connect(self, address=None, port=23):
        """
        Initialize tuner.

        Parameters
        ----------
        address : string
            TCPIP address of tuner.  Will change the default (stored) ip
            address in the class. If not specified, will use the class
            constructor address.
        port : int, optional
            Port of IP address, default is TELNET 23 (def=23).  If not
            specified, will use the class constructor port number.
        """
        print('Attempting iTuner connection... ', end='')

        if (address):
            self.address = address
        if (port != self.port):
            self.port = port

        try:
            self.instr = socket.socket()
            self.instr.settimeout(self.timeout)
            self.instr.connect((self.address, int(self.port)))
            self.connected = True
            print('connected')
            print('iTuner initializing... ', end='')
            try:
                self.instr.send('INIT\r\n'.encode())
                trash = self.instr.recv(2048)
                self.waitForReady()
            except:
                print('connection unsuccessful')
                self.connected = False
                exit()
            print('done')
            return self.connected

        except:
            print('connection unsuccessful')
            self.connected = False
            return self.connected



    def close(self):
        """
        Close tuner communication.
        """
        if(self.instr):
            self.instr.close()
            self.instr = None
            self.connected = False
            print('Tuner Connection Closed')
        else: 
            self.instr = -1
            self.connected = False
            print('No Tuner Connected. Did not close properly. Consider Rebooting')

        return self.instr

    def move(self, axis, position):
        """tuner_move(axis, position)

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
        if (not self.instr):
            err = ('TunerClass:', sys._getframe(0).f_code.co_name, ':'
                   ' Connection Error')
            raise SystemError(err)

        # check position against axis limits
        if (axis.lower() == 'x'):
            axis = '1'
            if (position > self.xMax or position < 0):
                raise SystemError('Exceeds X position limit, tuner not moved!')
        elif (axis.lower() == 'y'):
            axis = '3' #for higher frequency operation
            if (position > self.yMax or position < 0):
                raise SystemError('Exceeds Y position limit, tuner not moved!')
        elif (axis.lower() == 'aux'):
            axis = '2' #for higher frequency operation
            if (position > self.yMax or position < 0):
                raise SystemError('Exceeds Y position limit, tuner not moved!')
        
        else:
            warnings.warn('Invalid axis, tuner not moved!')
            return self.pos()

        # Open a connection to the tuner
#        self._open()
        if (axis == '1' and self.pos()[0] == position):
            # already there, return
            return
        elif (axis == '2' and self.pos()[1] == position):
            # already there, return
            return
        elif (axis == '3' and self.pos()[2] == position):
            # already there, return
            return

        # Send the command to move slug
        # self.kbInt.enable()
        self.instr.send(('POS '+axis+' '+str(int(position))+'\r\n').encode())
        self.waitForReady()
        # if (self.kbInt.trapped):
        #     raise KeyboardInterrupt
        # self.kbInt.disable()

        # Query the tuner position
        # x, y = self.pos()

        # self.close()
        # return x, y
        return

    def tuneto(self, magnitude, phase):
        """tuner_tune(magnitude, phase)

        Tune to specific reflection coefficient.  Wait until tuned.

        Parameters
        ----------
        mag : float
            Desired reflection coefficient magnitude.
        phase : float
            Desired reflection coefficieny phase (in degrees).

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
        self.instr.send(
            ('TUNETO ' + str(magnitude) + ' ' + str(phase) + '\r\n').encode()
            )

        self.waitForReady()
        print('done')

        return

    def calpoint(self, index):
        """tuner_calpoint(index)

        Tune to calibration point.  Wait until tuned.

        Parameters
        ----------
        mag : float
            Desired reflection coefficient magnitude.
        phase : float
            Desired reflection coefficieny phase (in degrees).

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
        self.instr.send(
            ('CALPOINT ' + str(int(index))  + '\r\n').encode()
            )

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
        self.instr.send((
            'LOADFREQ '
            + str(round(freq*1e-6))
            + '\r\n'
            ).encode())

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
        #self.instr.send('STATUS? \r'.encode())
        return_string = self.instr.recv(1024).decode()
        #print((return_string))

        # print('~~~~~RETURN STRING~~~~~')
        # print(return_string)
        status_string = re.search(
            'STATUS:.*\nResult=.*ID#', return_string
            )
        # print('~~~~~STATUS STRING~~~~~')
        # print(status_string)
        if status_string is not None:
            status_code = int(
            status_string.group().split('0x000')[1].split(' ')[0]
                )
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
#        self.kbInt.enable()
        #self.status()
        self.instr.send('\r\nPOS? \r\n'.encode())
        # try:
        r = self.instr.recv(1024)  # write response
        # except:
        #     try:
        #         self.instr.send('POS?\r\n'.encode())
        #         r = self.instr.recv(1024)  # write response
            # except:
            #     exit()
        m = re.search('A1=([-0-9]+) A2=([-0-9]+) A3=([-0-9]+)'.encode(), r)
        while (not m):
            # try:
            #     self.instr.send('POS?\r\n'.encode())
            r = self.instr.recv(1024)  # command response
            m = re.search('A1=([-0-9]+) A2=([-0-9]+) A3=([-0-9]+)'.encode(), r)
            # except:
            #     exit()
        if (self.kbInt.trapped):
            raise KeyboardInterrupt
#        self.kbInt.disable()
        self.xPos = m.group(1)
        #self.yPos = m.group(2)
        self.yPos = m.group(3) #for higher frequencies
        #print("Tuner posistion is 1: " + str(m.group(1)) + " 2: " + str(m.group(2)) + " 3: " + str(m.group(3)))
        return [int(self.xPos), int(m.group(2)), int(self.yPos)]

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
        status_code = 1
        lastQuery = 0
        queryRepeat = 0.25
        while (time.time() - starttime < timeout and status_code):
            try:
                std_trsh = self.instr.recv(1024).decode()
            except:
                return
        while (time.time() - starttime < timeout and status_code):
            # print('~~~~~ENTERING WHILE LOOP~~~~~')
            while (time.time() - lastQuery < queryRepeat):
                pass
            status_code = self.status()
            # print('~~~~~STATUS CODE~~~~~')
            # print(status_code)
            lastQuery = time.time()

        if (status_code != 0):
            print('TunerClass: ERROR Ready Timeout')
            print('   ', sys._getframe(2).f_code.co_name, ':',
                  sys._getframe(1).f_code.co_name,
                  sys._getframe(0).f_code.co_name)
        return

#   {o.O}
#   (  (|
# ---"-"-
