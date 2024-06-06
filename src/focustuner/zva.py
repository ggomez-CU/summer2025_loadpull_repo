# -*- coding: utf-8 -*-
"""
Created on Sat Oct 27 19:57:28 2018

@author: MicrowaveLab
"""

import src
from src.main import BaseInstr
import numpy as np

class ZVA40(BaseInstr.BaseInstr):
    def __init__(self, address=None):
        BaseInstr.BaseInstr.__init__(self, address)
        self._connected = False
        self._verbose = False
        return

    def set_generator_state(self, ch, pt, state):
        self.instr.write('SOUR'+str(ch)+':POW'+str(pt)+':PERM '+state)

    def set_phase_ref(self, ref):
        self.instr.write('SOUR:CMODe:RPORt' + str(ref))

    def set_coherent_mode(self, port, state):
        self.instr.write('SOUR:CMODe:PORT' + str(port)+' '+state)

    def set_rel_phase(self, port, rel_phi):
        self.instr.write('SOUR:CMODe:PORT' + str(port)
                         + ':PHASe ' + str(rel_phi))

    def set_rel_pow(self, port, rel_pow):
        self.instr.write('SOUR:CMODe:PORT' + str(port)
                         + ':AMPlitude ' + str(rel_pow))

    def load_cal(self, calname):
        self.instr.write('MMEM:LOAD:CORR 1,'+ calname)

    def connect(self, address=None, reset=True):
        """``connect()``

        Open connection to Instrument.
        """
        BaseInstr.BaseInstr.connect(self, address)

        if (reset):
            self.instr.write('*RST')
            self.instr.query('*OPC?')
        return

    def set_output(self, state):
        self.instr.write('OUTPut:STATe '+str(state))

    def create_measurement(self, chn, traceno, measurement, format_string):
        tracename = 'Ch'+str(chn)+'Tr'+str(traceno)
        self.instr.write('CALC'+str(chn)+':PAR:SDEF \''
                         + tracename+'\', \''+measurement+'\'')
        self.instr.write('DISP:WIND1:STAT ON')
        self.instr.write('DISP:WIND1:TRAC'+str(traceno)
                         + ':FEED \''+tracename+'\'')
        self.instr.write('CALC'+str(chn)+':PAR:SEL \''+tracename+'\'')
        self.instr.write('CALC'+str(chn)+':FORM '+format_string)

    def set_marker_format(self, chn, trace, format_string):
        self.instr.write('CALC'+str(chn)+':MARK'
                         + str(trace)+':FORMat '+format_string)

    def create_marker(self, chn, num):
        # frequency must be in GHZ
        self.instr.write('CALC'+str(chn)+':MARK'+str(num)+' ON')

    def set_marker_x(self, chn, num, freq):
        self.instr.write('CALC'+str(chn)+':MARK'
                         + str(num)+':X '+str(freq)+'GHZ')

    def close(self):
        """
        """
        self.set_output(0)
        BaseInstr.BaseInstr.close(self)
        return

    def send_command(self, text):
        x = self.instr.write(text)
        return x

    def send_query(self, text):
        x = self.instr.query(text)
        return x

    def set_active_trace(self, chn, tracename):
        self.instr.write('CALC'+str(chn)+':PAR:SEL \''+tracename+'\'')

    def get_marker_value(self, ch, markno):
        x = self.instr.query('CALC'+str(ch)+':MARK'+str(markno)+':Y?')
        return x

    def set_snp_matrix(self, ch, port_str):
        self.instr.write('CALC'+str(ch)+':PAR:DEF:SGR '+port_str)

    def get_gamma_matrix(self, ch):
        # port_str='1,2' for example
        self.instr.write('INIT:CONT OFF')
        self.instr.write('INIT:IMMediate *OPC')
        nop = int(self.instr.query('SWE:POIN?'))

        matrixunicode = self.instr.query('CALCulate'+str(ch)+':DATA:CALL?')
        matrixstr = str(matrixunicode)

        matrixtemp = matrixstr.split(',')
        for x in np.arange(0, len(matrixtemp), 2):
            if x == len(matrixtemp)-1:
                matrixtemp[x] = matrixtemp[x][0:-2]+'j'
            else:
                matrixtemp[x] = matrixtemp[x]+'j'

        numparams = len(matrixtemp)//(2*nop)
        matrix = np.zeros((nop, int(numparams)), dtype=np.complex_)
        for x in np.arange(0, numparams):
            matrixentry = []
            subset_start = 2*x*nop  # 0, 404, 708
            subset_stop = (2*x+2)*nop  # 403, 707
            # print [x,subset_start, subset_stop]
            for a in np.arange(subset_start, subset_stop, 2):
                matrixentry.append(
                    complex(matrixtemp[a])+complex(matrixtemp[a+1]))
            matrix[:, x] = np.transpose(matrixentry)
        # print(matrix.shape)
        matrixreshape = matrix.reshape(
            (nop, int(np.sqrt(numparams)), int(np.sqrt(numparams))))

        return matrixreshape

    def get_stim_data(self, ch):
        info = self.instr.query('CALC'+str(ch)+':DATA:STIM?')
        infostr = str(info)

        infotemp = infostr.split(',')
        stim = []
        for x in np.arange(0, len(infotemp)):
            # print x
            if x == len(infotemp)-1:
                stim.append(float(infotemp[x][0:-1]))
            else:
                stim.append(float(infotemp[x]))
        return stim

    def get_wave_data(self, ch, tracename=None, alltraces=True):
        if alltraces and tracename is None:
            self.instr.write('INIT:CONT OFF')
            self.instr.write('INIT:IMMediate *OPC')
            matrixunicode = self.instr.query('CALC'+str(ch)+':DATA:ALL? SDAT')

            nop = int(self.instr.query('SWE:POIN?'))

            matrixstr = str(matrixunicode)

            matrixtemp = matrixstr.split(',')
            for x in np.arange(1, len(matrixtemp), 2):
                # print x
                if x == len(matrixtemp)-1:
                    matrixtemp[x] = matrixtemp[x][0:-2]+'j'
                else:
                    matrixtemp[x] = matrixtemp[x]+'j'

            numparams = len(matrixtemp)/(2*nop)
            matrix = np.zeros((nop, numparams), dtype=np.complex_)
            for x in np.arange(0, numparams):
                matrixentry = []
                subset_start = 2*x*nop  # 0, 404, 708
                subset_stop = (2*x+2)*nop  # 403, 707
                # print [x,subset_start, subset_stop]
                for a in np.arange(subset_start, subset_stop, 2):
                    matrixentry.append(
                        complex(matrixtemp[a])+complex(matrixtemp[a+1]))
                matrix[:, x] = matrixentry
            # print matrix.shape
            x = matrix.reshape((nop, np.sqrt(numparams), np.sqrt(numparams)))

        else:
            self.instr.write('CALC'+str(ch)+':PAR:SEL \''+tracename+'\'')
            x = self.instr.query('CALC'+str(ch)+':DATA? FDAT')

        self.instr.write('INIT:CONT ON')
        return x

    def get_trace_data(self, ch, tracename=None, alltraces=True):
        if alltraces and tracename is None:
            self.instr.write('INIT:CONT OFF')
            self.instr.write('INIT:IMMediate *OPC')
            matrixunicode = self.instr.query('CALC'+str(ch)+':DATA:CALL? SDAT')

            nop = int(self.instr.query('SWE:POIN?'))

            matrixstr = str(matrixunicode)

            matrixtemp = matrixstr.split(',')
            for x in np.arange(1, len(matrixtemp), 2):
                print(x)
                if x == len(matrixtemp)-1:
                    matrixtemp[x] = matrixtemp[x][0:-2]+'j'
                else:
                    matrixtemp[x] = matrixtemp[x]+'j'

            numparams = len(matrixtemp)//(2*nop)
            matrix = np.zeros((nop, numparams), dtype=np.complex_)
            for x in np.arange(0, numparams):
                matrixentry = []
                subset_start = 2*x*nop  # 0, 404, 708
                subset_stop = (2*x+2)*nop  # 403, 707
                # print [x,subset_start, subset_stop]
                for a in np.arange(subset_start, subset_stop, 2):
                    matrixentry.append(
                        complex(matrixtemp[a])+complex(matrixtemp[a+1]))
                matrix[:, x] = matrixentry
            # print matrix.shape
            x = matrix.reshape((
                nop, int(np.sqrt(numparams)), int(np.sqrt(numparams)))
                )

        else:
            self.instr.write('CALC'+str(ch)+':PAR:SEL \''+tracename+'\'')
            x = self.instr.query('CALC'+str(ch)+':DATA? FDAT')

        self.instr.write('INIT:CONT ON')
        return x

    def export_snp(self, ch, filename, format_str, port_str):
        self.instr.write('MMEM:STOR:TRAC:PORT '+str(ch)+' '
                         + filename+', '+format_str+' '+port_str)
