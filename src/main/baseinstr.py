# -*- coding: utf-8 -*-
"""
@author: srschafer

Created on Tue Jul 24 15:24:54 2012

Updated to Python 3, PEP 8 style by Devon Donahue
Nov 2018
"""
import pyvisa as visa

rm = None
if ('__version__' in dir(visa)):
    useRM = False
    v1 = '1.6.1'
    v2 = visa.__version__
    lv1 = v1.split('.')
    lv2 = v2.split('.')
    length = max(len(lv1), len(lv2))
    for i in range(0, length):
        if (i < len(lv1)):
            sv1 = int(lv1[i])
        else:
            sv1 = 0
        if (i < len(lv2)):
            sv2 = int(lv2[i])
        else:
            sv2 = 0
        if (sv1 < sv2):
            useRM = True
            break
        if (sv1 > sv2):
            break
    else:
        useRM = True
    if (useRM):
        rm = visa.ResourceManager()


class BaseInstr(object):
    def __init__(self, address=None, checkIDN=False, **kwargs):
        """Constructor for Instrument

        Parameters
        ----------
        address : string
            VISA address of instrument.
        checkIDN : bool
            After connecting, check that ``*IDN?`` of instrument matches class
            name.
        """

        self._connected = False
        self.address = None
        if (address):
            self.address = address
        else:
            print('No address specified: set one with connect(address) or '
                  + self.__class__.__name__ + '.address')
        if (checkIDN):
            self._idn = self.__class__.__name__
        else:
            self._idn = None
        return

    ##########################################################################
    def connect(self, address=None):
        """``connect()``

        Open connection to Instrument.
        """
        if (address):
            self.address = address
        if (not self.address):
            print('No address specified: set one with connect(address) or '
                  + self.__class__.__name__+'.address')
            raise ValueError
            return

        if (rm):
            self.instr = rm.open_resource(self.address)
        else:
            self.instr = visa.instrument(self.address)
        self._connected = True
        self._checkIDN()
        return

    def close(self):
        """``close()``

        Close connection to instrument; connection will be invalid afterward.
        """
        self.instr.close()
        self._connected = False
        return

    def _checkIDN(self):
        """``_checkIDN()``

        Query the instrument for its ``*IDN?`` string and check if connected to
        an appropriate instrument.  Checks if private variable ``_idn`` is in
        the identification string.

        If ``_idn`` is ``None``, ignore check.

        If check fails, it raises ``SystemError``.
        """
        if (not self._connected):
            print('WARNING: Not connected when calling _checkIDN.  ('
                  + self.__class__.__name__ + ')')
            return

        if (self._idn):
            idnstring = self.instr.query('*IDN?')
            if (idnstring.find(self._idn) == -1):
                raise SystemError('Instrument *IDN is not consistent with'
                                  'class:\n\tClass:'
                                  + self.__class__.__name__
                                  + '\n\tIDN:' + idnstring)
        return


#   {o.O}
#   (  (|
# ---"-"-
