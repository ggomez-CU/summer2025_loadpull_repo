# -*- coding: utf-8 -*-
"""
@author: srschafer

Created on Tue Jul 17 23:38:25 2012

Contains functions to read / write a variety of RF data files.

Updated to Python 3, PEP 8 style by Devon Donahue
Nov 2018
"""
import os
# import time
import csv
import re
import warnings
import numpy as np
# import rfmath  # rfGeneral
import h5py


def understand_hdf5(filename):
    """Helps a programmer (or poor, helpless engineer who happens to be trying
    to write test bench code) understand the contents of an hdf5 file.

    Parameters
    ----------
    filename : string
        Name of hdf5 file.

    """
    # Read file and "print file."
    file = h5py.File(filename, 'r')
    print('file:')
    print(file)

    # Print out the keys.
    print('\nkeys:')
    for key in file.keys():
        print(key)

    # Print the information for the group of each key.
    for key in file.keys():
        group = file[key]
        print('\ngroup:', key)
        print(group)

    # Close the file... because practicing good practice and stuff.
    file.close()
    return


def writeData(filename, values, names, delimiter=',', mode='w'):
    """``writeData(filename, values, names)``

    General output file writer.

    Parameters
    ----------
    filename : string
        Output filename.
    values : array
        Data array
    names : string array
        Single header line to define columns.
    delimiter : char (optional)
        csv delimiter property.
    mode : char (optional)
        Specify mode to open file.  'r': read, 'w':write, 'a':append

    Example
    -------
    >>> wtrArr = np.array([V1_f,V1_A,V1_q,V1_0]).T
    >>> wtrNames = ['V1_f','V1_A','V1_q','V1_0']
    >>> writeData(filename, wtrArr, wtrNames)

    To use with dictionary dataset:

    >>> writeData(filename, np.array(data.values()).T, data.keys())
    """
    fid = open(filename, mode)
    wtr = csv.writer(fid, lineterminator='\n', delimiter=delimiter)
    if (mode != 'a' and names):
        wtr.writerow(names)
    for row in values:
        wtr.writerow(row)
    fid.close()
    return


def readAWR(filename, hl=1, delimiter=None, retDict=False, dtype=float, file_id=False):
    """::

    header, data = readAWR(filename, hl=1, delimiter=None, retDict=False,
                           dtype=np.float, file_id=False)

    Read in AWR exported graph trace datafile.  Default delimiter from AWR is
    ``'\\t'``. However, this function can be used for csv files with ``','``
    delimiter.  Function can return data in dictionary format with keys as
    header names.

    Parameters
    ----------
    filename : string
        Filename of file.
    hl : int (Optional)
        Number of headerlines.
    delimiter : char (Optional)
        Delimiter between values.  Set to ``None`` to automatically detect the
        delimiter from the line after the header.
    retDict : bool
        Return data in a dictionary format.  Keyvalues are header names.
    dtype : type
        Data type to read in data as.  Primarily used to read data in as a
        complex number.
    file_id : bool
        If true, uses ``filename`` as a open file_id instead of a string.
        Allows use of zip files.
    """
    def findDelimiter(delimiter, l):
        if delimiter is not None:
            return delimiter
        return re.findall('[\\(\\) + j0-9]([\\t, ] + )[\\(\\) + j\\-0-9]',
                          l)[0]

    if (file_id):
        lines = filename.readlines()
    else:
        fid = open(filename)
        lines = fid.readlines()
        fid.close()

    if delimiter is None:
        delimiter = findDelimiter(delimiter, lines[hl])

    reader = csv.reader(lines, delimiter=delimiter)

    if (hl == 0):
        for i in range(0, 1):
            header = reader.next()
        header = ['']*len(header)
        reader = csv.reader(lines, delimiter=delimiter)
    else:
        header = []
        for i in range(0, hl):
            header.append(reader.next())

    # Test if any data columns are complex split into (real) (imag)
    # AWR style - (Real), (Imag)
    coltype = [[i] for i in range(0, len(header[-1]))]
    nc = 0
    i = 0
    while (i < len(header[-1])):
        j = i + 1
        while (j < len(header[-1])):
            ai = header[-1][i].find('(Real)')
            bj = header[-1][j].find('(Imag)')
            if (ai != -1 and bj != -1):
                if (header[-1][i][:ai] == header[-1][i][:bj]):
                    dtype = np.complex
                    header[-1].pop(j)
                    header[-1][i] = header[-1][i].replace('(Real)',
                                                          '(Complex)').strip()
                    coltype[i].append(coltype.pop(j)[0])
                    nc += 1
            j += 1
        i += 1

    data = np.zeros((len(lines)-hl, len(header[-1])), dtype=dtype)
    i = 0
    s = [1, 1j]
    for row in reader:
        try:
            dtmp = np.array(row, dtype='|S50')
        except:
            if (len(row)-nc != len(header[-1])):
                warnings.warn('readAWR: Warning: Line {:d} has incorrect'
                              ' length ({:d} vs {:d})'.format(i + hl, len(row),
                                                              len(header)))
            else:
                warnings.warn('readAWR: Error: Line ' + str(i + hl))

        if (len(row) == 0):
            continue
#        data = np.resize(data, (np.shape(data)[0] + 1,len(header)))
#        dtmp = filter(None, dtmp) #for space delimited files
#        import pdb; pdb.set_trace()
        dtmp[np.where(dtmp == '')] = np.nan
        try:
            if (nc != 0):
                d1 = [[np.float(dtmp[coltype[k]][j])*s[j]
                       for j in range(0, len(coltype[k]))]
                      for k in range(0, len(header[-1]))]
                d1 = [np.sum(d1[k]) for k in range(0, len(d1))]
                data[i, :] = np.array(d1, dtype=dtype)
            else:
                data[i, :] = np.array(dtmp, dtype=dtype)
        except ValueError:
            # try complex data type
            warnings.warn('Data type changed to complex')
            data = data.astype(np.complex, copy=False)
            try:
                data[i, :] = np.array(dtmp, dtype=np.complex)
            except ValueError:
                print('Error in line:', i)
                print('   ', row)
                raise
            dtype = np.complex
        i += 1

    if (retDict):
        ddata = RFDict()
        ddata.update({header[-1][i]: data[:, i]
                      for i in range(0, len(header[-1]))})
        data = ddata
    return header, data


# def reformatFile(infile, outFile=None, hdf5=True):
#     """``h,d = reformatFile(infile, outFile=None, hdf5=True)``
#
#     Reformate AWR export file using header information to one independent
#     measurement per line.
#
#     Parameters
#     ----------
#     inFile : str
#         Path to input file.
#     outFile : str
#         New file path.  Will overwrite.  If ``None``, no file will be output.
#     hdf5 : bool
#         Save data in a HDF5 format file.
#     """
#     h,d = readAWR(infile)
#     h = h[-1]
#     #scale = re.search('^[\w] + ',h[col]).group()
#     # get measurement
#     hmeas = []
#     iy = []
#     for i in range(1,len(h)):
#         s = ''.join(h[i].split(' ')[0:2])
#         m = re.search('\([RealImag]{2,4}\)',h[i])
#         if (m):
#             s = s  +  m.group()
#
#         if (h[i] == h[0] or (h[0].split(' ')[-1] == 'Time' and h[i].split(' ')[-1] == 'Time')):
#             if (not np.all(d[:,i] == d[:,0])):
#                 print('Error: reformatFile: identical header with mismatched data')
#                 raise ValueError
#         elif (s not in hmeas):
#             hmeas.append(s)
#             iy.append(i)
#         else:
#             iy.append(i)
#
#     rows = np.shape(d)[0]
#     cols = len(iy) # np.shape(d)[1]
#     nmeas = len(hmeas)
#
#     mtype = []
#     for i in range(0,nmeas):
#         if (hmeas[i].count('(') == 1):
#             mtype.append(hmeas[i].split('(')[0])
#         else:
#             try:
#                 tmp = re.search('([ReIm]{0,2}?)\(([|\w] + )\([\\\_\.,\w] + \)([|\w]?)\)',hmeas[i]).groups()
# #                tmp = re.search('\(([|\w] + )\([\\\_\.,\w] + \)([|\w]?)\)',hmeas[i]).groups()
#                 mtype.append(''.join(tmp))
#             except:
#                 tmp = re.search('([\w] + )\(. + (\([\w] + \))',hmeas[i]).groups()
#                 mtype.append(''.join(tmp))
#
#     # get x variables
#     xvar = d[:,0]
#     xname = str(h[0])
# #    xname = str(h[0]).split(' ')[-1]
#
# #    data = np.reshape(d[:,1:],(rows,(cols-1)/nmeas,nmeas), order='F')
#     data = np.reshape(d[:,iy], (rows,-1,nmeas), order='F')
#     h = np.reshape(np.array(h)[iy],(cols/nmeas,nmeas), order='F')
#
#     measdict = []
#     for j in range(0,np.shape(data)[1]): # column
#         # gather header variable information
#         v = re.findall('([A-Za-z0-9\_] + )[ ] + ?=[ ] + ?([-0-9.] + )',h[j,0])
#         vd = {v[i][0]:float(v[i][1]) for i in range(0,len(v))}
#
#         for i in range(0,np.shape(data)[0]): # row
#             measdict.append({})
#             measdict[-1].update(vd)
#             # get measurement
#             for m in range(0,len(mtype)):
#                 measdict[-1][mtype[m]] = data[i,j,m]
#             measdict[-1][xname] = xvar[i]
#
#     outdata = dictToDict(measdict)
#
#     if (outFile):
#         if (hdf5):
#             info = """Reformatted AWR export file.
#                 Original filename: {:}
#                 Created: {:}
#             """.format(infile,time.ctime())
#             write_hdf5(outFile, outdata, info=info)
#         else:
#             wtrArr = np.array(outdata.values()).T
#             wtrNames = outdata.keys()
#             writeData(outFile, wtrArr, wtrNames)
#     return


# def read_mdif(filename, delimiter=' ', hl=1):
#     """``read_mdif(filename, hl=1)``
#
#     Read MDIF file and return data in multidimentional array.
#
#     Parameters
#     ----------
#     filename : string
#         Filename to read.
#     delimiter : character
#         Delimiter for reading mdif file.
#
#     Returns
#     -------
#     data : array
#         Data
#     xdata : array
#         X data
#     names : string array
#         Header names
#     """
# #TODO: Consider using NaN for array values so as to not confuse missing values with a measured zero value
# #    fid = open(filename)
# #    header = fid.readline()
#     _freq_units = {'hz':1., 'khz':1e3, 'mhz':1e6, 'ghz':1e9, 'thz':1e12}
#
#     fid = open(filename)
#     lines = fid.readlines()
#     fid.close()
#
#     names = []
#     currVarName = []
#     currVarValue = []
#     reader = csv.reader(lines, delimiter=delimiter)
#     data = np.zeros((0))
#     xdata = np.zeros((0))
#
#     readAC = False
#     beginReadAC = False
#     while 1:
#
#         try:
#             l = reader.next()
#         except:
#             break
#         l = map(lambda x: l[x].strip(), range(0,len(l)))
#         l = filter(None, l)
# #        print "Line:",l
#
#         # check for empty line
#         if (not l):
#             continue
#         # check for comment
#         if (l[0][0] == '!'):
#             continue
#
#         # read variable
#         #   VAR XY=0,1136
#         elif (l[0].find('VAR') != -1):
#             var = re.sub('VAR[ ]?','',''.join(l)).split('=')
#             currVarName.append(var[0])
#             currVarValue.append(var[1])
#
#
#         # read begin Data
#         #   BEGIN ACDATA
#         elif (l[0].find('BEGIN') != -1):
#             if (''.join(l).find('ACDATA') != -1):
#                 beginReadAC = True
#
#         # read S-Parameter format string
#         #   # Hz S RI R 50
#         elif (l[0][0] == '#' and beginReadAC):
#             # frequency scaling
#             if (delimiter == ' '):
#                 fmt = l[2:]
#                 fmt_fs = _freq_units[l[1].lower()]
#             else:
#                 fmt = re.split(' ', l)[2:]
#                 fmt_fs = _freq_units[re.split(' ', l)[1]]
#             fmt_data = fmt[1]
#             fmt_norm = fmt[fmt.index('R') + 1]
#             readAC = True
#
#         # read second S-Parameter format string
#         #   # %F n11x n11y n21x n21y n12x n12y n22x n22y
#         elif (l[0][0] == '%' and beginReadAC):
#             # frequency scaling
#             readAC = True
#
#         # read S-Parameters
#         #   9790000000.000000	-0.029217	-0.034503	0.754943	0.575368	0.755527	0.575773	0.041893	0.016588
#         elif (readAC):
#             acdata = np.zeros((0,len(l)-1), dtype='|S20')
#             freq = np.zeros(0, dtype='|S20')
#             while (l[0] != 'END'):
#                 acdata = np.append(acdata, [l[1:]], axis=0)
#                 freq = np.append(freq, l[0])
#                 l = reader.next()
#                 l = filter(None, l)
#
#             acdata = np.array(acdata, dtype=np.float64)
#             freq = np.array(freq, dtype=np.float64) * fmt_fs
#
#             oldShape = np.shape(data)
#
#             # new named parameter (variable)
#             for i in range(0, len(currVarName)):
#                 if (currVarName[i] not in names):
#                     names.append(currVarName[i])
#
#             # increase size for additional parameter (variable) value
#
#             if (len(np.shape(data)) < 3):
#                 # first time through loop
#                 newShape = (1,) + np.shape(acdata)
#             else:
#                 newShape = (oldShape[0] + 1,) + oldShape[1:]
#
#             data = np.resize(data, newShape)
#             xdata = np.resize(xdata, newShape[0:2] + (3,))
#
#             data[-1,:,:] = acdata
#
#             xdata[-1,:,names.index(currVarName[0])] = currVarValue[0]
#             xdata[-1,:,names.index(currVarName[1])] = currVarValue[1]
#             xdata[-1,:,2] = freq
#
#             # end reading of S-Parameters
#             #   END
#             readAC = False
#             beginReadAC = False
#             currVarName = []
#             currVarValue = []
#
#         else:
#             print('read_mdif: Error: Unparsable line:', l)
#             print('    -> Was S-parameter format line forgot?')
#
#
#     return data, xdata, names


# def read_gmdif(filename, delimiter=' '):
#     """``d = read_gmdif(filename, delimiter=' ')``
#
#     Read General MDIF file and return data in dictionary format.
#
#     Parameters
#     ----------
#     filename : string
#         Filename to read.
#     delimiter : character
#         Delimiter for reading mdif file.
#
#     Returns
#     -------
#     d : dict
#         Data dictionary.
#     """
#     d = RFDict()
#     h = {}
#     vard = {}
#     sweeph = []
#
#     fid = open(filename)
#     lines = fid.readlines()
#     fid.close()
#
#     reader = csv.reader(lines, delimiter=delimiter)
#
#     currSweepName = ''
#     beginReadSweep = False
#     while 1:
#         try:
#             try:
#                 l = reader.next()
#             except:
#                 break
#             l = map(lambda x: l[x].strip(), range(0,len(l)))
#             l = filter(None, l)
#     #        print "Line:",l
#
#             # check for empty line
#             if (not l):
#                 continue
#             # check for comment
#             if (l[0][0] == '!'):
#                 continue
#
#             # read variable
#             #   VAR XY=0,1136
#             elif (l[0].find('VAR') != -1):
#                 var = re.findall('VAR[ ]?([\w] + )\(?([\w] + )?\)?=([-\w\d\.] + )',''.join(l))[0]
#                 vard[var[0]] = float(var[2])
#                 if (var[0] not in d):
#                     h[var[0]] = var[1]
#                     d[var[0]] = []
#
#
#             # read begin Data
#             elif (l[0].find('BEGIN') >= 0):
#                 currSweepName = l[1]
#                 beginReadSweep = True
#                 sweeph = []
#
#             # read ACDATA
#             elif (l[0][0] == '#' and currSweepName == 'ACDATA' and beginReadSweep):
#                 aclines = []
#                 aclines.append(' '.join(l))
#                 while (' '.join(l).find('END') == -1):
#                     l = reader.next()
#                     l = map(lambda x: l[x].strip(), range(0,len(l)))
#                     l = filter(None, l)
#                     if (l[0][0] == '!' or l[0] == 'END'):
#                         continue
#                     aclines.append(' '.join(l))
#
#                 f,S = parse_xNp(aclines, N=None)
# #                import pdb; pdb.set_trace()
#                 # end reading of swept data
#                 #   END
#                 for i in range(0,len(f)):
#                     try:
#                         d['freq'].append(f[i])
#                         d['S'].append(S[i])
#                     except KeyError:
#                         d['freq'] = [f[i]]
#                         d['S'] = [S[i]]
#                     for k,v in vard.items():
#                         d[k].append(v)
#                 beginReadSweep = False
#                 vard = {}
#                 currSweepName = ''
#
#             # read format string
#             elif (l[0][0] == '%' and beginReadSweep):
#                 sweeph.append([])
#                 var = re.findall('([\[\]\w\d\.,] + )\(?([\w] + )?\)?',''.join(l))
#                 for v in var:
#                     sweeph[-1].append(v[0])
#                     if (v[0] not in d):
#                         h[v[0]] = v[1]
#                         d[v[0]] = []
#
#             # read data
#             elif (beginReadSweep):
#                 while (l[0].find('END') == -1):
#                     if (l[0][0] == '!'):
#                         l = reader.next()
#                         l = map(lambda x: l[x].strip(), range(0,len(l)))
#                         l = filter(None, l)
#                         continue
#                     # read all header elements
#                     # line
#                     for i in range(0,len(sweeph)):
#                         dtmp = np.array(l, dtype=np.float)
#                         # element
#                         di = 0
#                         for j in range(0,len(sweeph[i])): #dtmp)):
#                             if (h[sweeph[i][j]] == 'complex'):
#                                 d[sweeph[i][j]].append(dtmp[di]  +  1j*dtmp[di + 1])
#                                 di  + = 1
#                             else:
#                                 d[sweeph[i][j]].append(dtmp[di])
#                             di  + = 1
#
#                         l = reader.next()
#                         l = map(lambda x: l[x].strip(), range(0,len(l)))
#                         l = filter(None, l)
#                         if (not l):
#                             l = ['!']
#                     # add in swept VARs
#                     for k,v in vard.items():
#                         d[k].append(v)
#
#
#                 # end reading of swept data
#                 #   END
#                 beginReadSweep = False
#                 vard = {}
#                 currSweepName = ''
#
#             else:
#                 print('read_mdif: Error: Unparsable line:', l)
#         except:
#             print('Error on line',reader.line_num)
#             print('line:',l,'\n')
#             print('current sweep:',currSweepName,'\n')
#             print('header info:',h,'\n')
#             print('VAR info:',vard,'\n')
#             print('data block header:',sweeph,'\n')
#             raise
#
#
#     # convert to numpy arrays
#     for k,v in d.items():
#         d[k] = np.array(v)
#     return d


def read_xNp(filename, delimiter=' '):
    """``freq, S = read_xNp(filename)``

    Read xNp files and return data.  x in ``syzgh``.

    Parameters
    ----------
    filename : string
        Filename to read.
    delimiter : character
        Delimiter for reading xNp files.

    Returns
    -------
    freq : array
        Frequency array in Hz (f,)
    S : array
        Network parameters. For multi-port data (fxNxN), N = number of ports
        (N > 2).
    """
    ext = os.path.splitext(filename)[1]
    N = int(ext[2:].replace('p', ''))

    fid = open(filename)
    lines = fid.readlines()
    fid.close()

    f, S = parse_xNp(lines, N=N)
    return f, S


def parse_xNp(lines, N=2):
    """``f, S = parse_xNp(lines, N=2)``

    Lower level function that constructes the xNp-parameter matrix.
    Credit to Werner Hoch (mwavepy) for some parts of this code.

    Parameters
    ----------
    lines : list
        List of strings corresponding to each line.
    N : int
        Number of ports.

    Returns
    -------
    freq : array
        Frequency array in Hz (f,)
    S : array
        Network parameters. For multi-port data (fxNxN), N = number of ports
        (N > 2).
    """
    _freq_units = {'hz': 1., 'khz': 1e3, 'mhz': 1e6, 'ghz': 1e9, 'thz': 1e12}

    values = []
    ports = []
    for line in lines:

        # remove comments '!'
        line = line.split('!', 1)[0].strip().lower()
        # check for empty line
        if (not line):
            continue

        # read S-Parameter format string
        #   # Hz S RI R 50
        if (line[0] == '#'):
            fmt = line[1:].strip().split()
            fmt_freq_str = fmt[0]
            fmt_parameter = fmt[1]
            fmt_format = fmt[2]
            fmt_resistance = fmt[4]
            if (fmt_freq_str not in _freq_units):
                print('ERROR: Illegal format string: frequency unit [%s]',
                      fmt_freq_str)
                return
            else:
                fmt_freq_scale = _freq_units[fmt_freq_str]
            if (fmt_parameter not in 'syzgh'):
                print('ERROR: Illegal format string: network parameter value'
                      ' [%s]', fmt_parameter)
                return
            if (fmt_format not in ['ma', 'db', 'ri']):
                print('ERROR: Illegal format string: data format [%s]',
                      fmt_format)
                return
            continue
        # read Port information format string
        #   %F n11x n11y n21x n21y n12x n12y n22x n22y
        if (line[0][0] == '%' and N is None):
            ports.append(line.replace('%', '').strip().split())
            try:
                ports[-1].pop(ports[-1].index('f'))
            except ValueError:
                pass
            n = [len(ports[i]) for i in range(0, len(ports))]
            N = int(np.sqrt(np.sum(n)/2))
            continue

        # collect all values without caring about their meaning
        values.extend([float(v) for v in line.split()])

    # let's do some postprocessing to the read values
    # for s2p parameters there may be noise parameters in the value list
    values = np.array(values, dtype=np.float)
    # Test for noise parameter data
    if (N == 2):
        # the first frequency value that is smaller than the last one is the
        # indicator for the start of the noise section
        # each set of the s-parameter section is 9 values long
        pos = np.where(np.sign(np.diff(values[::9])) == -1)
        if len(pos[0]) != 0:
            # we have noise data in the values
            pos = pos[0][0] + 1  # add 1 because diff reduced it by 1
            noise_values = values[pos*9:]
            values = values[:pos*9]
            noise = noise_values.reshape((-1, 5))

    # reshape the values to match the port number
    S = values.reshape((-1, 1 + 2*N**2))
    freq = S[:, 0] * fmt_freq_scale  # to convert to Hz
    S = S[:, 1:]

    # format parameters to complex
    if (fmt_format == 'db'):
        S = (10**(S[:, 0::2]/20.)) * np.exp(1j*np.pi/180. * S[:, 1::2])
    elif (fmt_format == 'ma'):
        S = S[:, 0::2] * np.exp(1j*np.pi/180. * S[:, 1::2])
    elif (fmt_format == 'ri'):
        S = S[:, 0::2] + 1j*S[:, 1::2]

    if (N == 2):
        # in file: [S11 S21 S12 S22]
        # exchange the backward values -> [S11 S12 S21 S22]
        # S12 = np.array(S[:,2])
        # S21 = np.array(S[:,1])
        # S[:,2] = S21
        # S[:,1] = S12
        S[:, 1], S[:, 2] = np.array(S[:, 2]), np.array(S[:, 1])
    elif (N > 2):
        S = np.reshape(S, (-1, N, N))

    return freq, S


# def write_xNp(filename, f, S, precision=10, overwrite=False):
#     """``write_xNp(filename, f, S, precision=10, overwrite=False)``
#
#     Write xNp file.
#
#     Parameters
#     ----------
#     filename : string
#         Output file name.
#     f : array
#         Frequency array in Hz.
#     S : array (f,)
#         Complex array of network parameters.
#     precision : int (optional)
#         Precision of float numbers to write to file.
#     overwrite : bool
#         If file exists, overwrite.
#     """
#     col = np.max([precision + 4 + 3, len(str(np.max(f))) + 2])
#     fmt = '{:<' + str(col) + '.' + str(precision) + '}'
#     fmt_freq = '{:<' + str(col) + '.0f}'
#     fmt_inner = ' '*col
#
#     if (len(np.shape(S)) < 3):
#         if (np.shape(S)[-1] > 4):
#             raise ValueError('S-parameter array too big. Want fx1, fx4, or'
#                              'fxNxN')
#         N = int(np.sqrt(np.shape(S)[-1]))
#     else:
#         N = np.shape(S)[-1]
#     fn = np.shape(S)[0]
#     if (not overwrite):
#         if (os.path.exists(filename)):
#             overwrite = raw_input('Overwrite file [' + filename + '] (y/n)? ')
#             if (not overwrite.lower() == 'y'):
#                 print('Canceled write_xNp.')
#                 return
#
#     fid = open(filename, 'w')
#     fid.write('! Generated from write_xNp\n')
#     fid.write('! Date: ' + time.ctime() + '\n')
#     fid.write('! Ports: ' + str(N) + ', Freqs: ' + str(fn) + '\n')
#     if (N > 2):
#         fid.write('# Hz S MA R 50\n')
#     else:
#         fid.write('# Hz S RI R 50\n')
#     fid.write('!--------------------------------------------------------------'
#               '---------------\n')
#
#     # create format strings
#     if (N < 3):
#         line = np.zeros(2*N**2 + 1)
#         fmt_str = fmt_freq + fmt*(2*N**2) + '\n'
#     elif (N > 4):
#         line = np.zeros(2*4 + 1)
#         fmt_str = fmt_freq + fmt*(2*4) + '\n'
#         fmt_str_inner = fmt_inner + fmt*(2*4) + '\n'
#     else:
#         line = np.zeros(2*N + 1)
#         fmt_str = fmt_freq + fmt*(2*N) + '\n'
#         fmt_str_inner = fmt_inner + fmt*(2*N) + '\n'
#
#     class limitN(object):
#         def __init__(self, N=4):
#             self._c = 0
#             self.lN = N
#             return
#
#         @property
#         def c(self):
#             return self._c
#
#         @c.setter
#         def c(self, value):
#             if (value > self.lN):
#                 self._c = self.lN
#             else:
#                 self._c = value
#             return
#
#     # main loop
#     for i in range(0, len(f)):
#         line[0] = f[i]
#         if (N == 1):
#             line[1::2] = np.real(S[i])
#             line[2::2] = np.imag(S[i])  # , deg=True)
#             fid.write(fmt_str.format(*tuple(line)))
#         elif (N == 2):
#             line[1:] = rfMath.m4tom8(S[i])
#             fid.write(fmt_str.format(*tuple(line)))
#         elif (N > 4):
#             ln = limitN(N)  # limit to 8 network parameters per line max
#             for j in range(0, N):
#                 ln.c = 0
#                 while (ln.c < N):
#                     cp = ln.c
#                     ln.c = ln.c + 4
#                     line[1:(ln.c - cp)*2:2] = np.abs(S[i, j, cp:ln.c])
#                     line[2:(ln.c-cp)*2 + 1:2] = np.angle(S[i, j, cp:ln.c],
#                                                        deg=True)
#                     if (j == 0 and ln.c == 4):
#                         fid.write(fmt_str.format(*tuple(line)))
#                     else:
#                         nprint = len(line[1:(ln.c - cp)*2 + 1])
#                         # (len(line[1:(ln.c-cp)*2 + 1]) < 8):
#                         fmt_str_inner = fmt_inner + fmt*(nprint) + '\n'
#                         fid.write(fmt_str_inner.format(*tuple(line[1:(ln.c
#                                                        - cp)*2 + 1])))
#             fid.write('\n')
#         else:
#             line[1::2] = np.abs(S[i, 0])
#             line[2::2] = np.angle(S[i, 0], deg=True)
#             fid.write(fmt_str.format(*tuple(line)))
#             for j in range(1, N):
#                 line[1::2] = np.abs(S[i, j])
#                 line[2::2] = np.angle(S[i, j], deg=True)
#                 fid.write(fmt_str_inner.format(*tuple(line[1:])))
#             fid.write('\n')
#     fid.close()
#     return


# def write_mdif(filename, data, xdata, names):
#     """``write_mdif(filename, data, xdata, names)``
#
#     Write multidimentional array to MDIF file.
#
#     Only two parameters supported currently.  Only two port s-parameters in
#     array format are supported currently.
#
#     Parameters
#     ----------
#     filename : string
#         Filename to write to.
#     data : Data array
#         Must be in format: nParam x mParam x nfreq x 8.  Holds s-parameters.
#     xdata : Data array
#         Parameter values of data array. Must be in format: nParam x mParam x
#         nfreq x 3.  Lowest level contains [nParamX, mParamY, freq].
#     names : String array
#         Names of parameters.
#     """
#     fid = open(filename, 'w')
#
#     s = np.shape(data)
#     for i in range(0, s[0]):
#         for j in range(0, s[1]):
#             fid.write('VAR' + str(names[0]) + '=' + str(xdata[i, j, 0, 1]))
#             if (s[0] != 1 or s[1] != 1):
#                 fid.write('VAR' + str(names[1]) + '=' + str(xdata[i, j, 0, 1]))
#             fid.write('BEGIN ACDATA\n')
#             fid.write(' # Hz S RI R 50\n')
#             fid.write(' %F n11x n11y n21x n21y n12x n12y n22x n22y\n')
#             for k in range(0, s[2]):
#                 wrt = csv.writer(fid, delimiter=' ')
#                 wrt.writerow([xdata[i, j, k, 2], data[i, j, k, :]])
#             fid.write('END')
#             fid.write('')
#
#     fid.close()
#     return


# def write_s2p_to_mdif(fileout, s2pfiles, varnames=[], paramname='a'):
#     """``write_s2p_to_mdif(fileout, s2pfiles, varnames=[], paramname='a')``
#
#     Write MDIF from multiple s2p files.
#
#     Parameters
#     ----------
#     fileout : str
#         Filename to write to.
#     s2pfiles : list
#         String list of filenames to read in and output to MDIF.
#     varnames : list
#         String list of parameter VAR names to distinguish s2p files.  If not
#         given, use s2p filenames.
#     """
#     fid = open(fileout, 'w')
#     fid.write('! Generated from write_s2p_to_mdif')
#     fid.write('! Date: ' + time.ctime() + '\n')
#     fid.write('! Number of files: ' + str(len(s2pfiles)) + '\n')
#
#     if (not varnames):
#         varnames = s2pfiles
#
#     for i in range(0, len(s2pfiles)):
#         # get s2p data
#         fs = open(s2pfiles[i])
#         lines = fs.readlines()
#         fs.close()
#
#         firstchar = [lines[j][0] for j in range(0, len(lines))]
#         index_fmt = firstchar.index('#')
#         firstchar.reverse()
#         index_data = len(lines) - firstchar.index('!')
#
#         fid.write('VAR ' + paramname + '="' + varnames[i] + '"\n')
#         # write VAR line
#         fid.write('BEGIN ACDATA\n')
#         fid.write(lines[index_fmt])  # write format line from s2p file
#         fid.write('% F    N11X    N11Y    N21X    N21Y    N12X    N12Y    N22X'
#                   '    N22Y\n')
#         fid.write(''.join(lines[index_data:]))
#         fid.write('END\n')
#         fid.write('\n')
#
#     fid.close()
#     return


# def write_mdif_single(filename, data, xdata, pdata, names):
#     """write_mdif_single(filename, data, xdata, pdata, names)
#
#     Write single entry of array to MDIF file.
#
#     Parameters
#     ----------
#     filename : string
#         Filename to write to.  Will create / append depending if file exists.
#     data : Data array
#         Must be in format: nfreq x 8 or nfreq x 4.  Holds s-parameters.
#     xdata : Data array
#         Linearly indepedent parameter.  Typically frequency for S-Parameters.
#     pdata : Data array
#         Parameter values of data array.  Same shape as names array.
#     names : String array
#         Names of parameters.  Same shape as pdata array.
#     """
#     fid = open(filename, 'a')
#
#     try:
#         length = len(xdata)
#     except:
#         length = 1
#     if (len(np.shape(data)) == 1):
#         data = np.reshape(data, (1, np.shape(data)[0]))
#     if (np.shape(data)[1] == 4):
#         data = rfMath.m4tom8(data)
#
#     for i in range(0, len(names)):
#         fid.write('VAR ' + str(names[i]) + '=' + str(pdata[i]) + '\n')
#     fid.write('BEGIN ACDATA\n')
#     fid.write(' # Hz S RI R 50\n')
#     fid.write(' %F n11x n11y n21x n21y n12x n12y n22x n22y\n')
#
#     if (length > 1):
#         for i in range(0, length):
#             fid.write('    ' + str(xdata[i]))
#             for j in range(0, 8):
#                 fid.write(' ' + str(data[i, j]))
#             fid.write('\n')
#     else:
#         fid.write('    ' + str(xdata))
#         for j in range(0, 8):
#             fid.write(' ' + str(data[0, j]))
#         fid.write('\n')
#
#     fid.write('END\n')
#     fid.write('\n')
#
#     fid.close()
#     return


# def write_lpMDF(filename, d, z0=50.0, info=None):
#     """```write_lpMDF(filename, d, z0=50.0)```
#
#     Write an MDF file with load-pull data. Warning, specific for Python
#     load-pull code and importing into AWR.
#
#     Parameters
#     ----------
#     filename : string
#         Filename of MDF file.
#     d : dictionary
#         Data to be written.
#     z0 : complex float
#         Characteristic impedance of measurement.
#     """
#     fid = open(filename, 'w')
#
#     if (info):
#         info = info.split('\n')
#         for i in info:
#             s = '!' + i + '\n'
#             fid.write(s)
#     else:
#         try:
#             info = d['attrs']['info'].split('\n')
#             for i in info:
#                 s = '!' + i + '\n'
#                 fid.write(s)
#         except:
#             print('No attrs or info')
#
#     #   Check for number of harmonic frequencies
#     if ('gLoad2fo' in d.keys() or 'gSrc2fo' in d.keys()):
#         nharms = 3
#     else:
#         nharms = 1
#
#     #   Find all swept variables
#     nv = 1
#     v = []
#     vNames = []
#     if (len(list(set(d['freq']))) > 1):
#         v.append('freq')
#         vNames.append('F1(1)')
#         nv *= len(list(set(d['freq'])))
#     if (len(list(set(d['psource']))) > 1):
#         v.append('psource')
#         vNames.append('iPower')
#         nv *= len(list(set(d['psource'])))
#     if (len(list(set(d['gSrc']))) > 1):
#         v.append('gSrc')
#         vNames.append('iGammaS1')
#         nv *= len(list(set(d['gSrc'])))
#     if (len(list(set(d['gLoad']))) > 1):
#         v.append('gLoad')
#         vNames.append('iGammaL1')
#         nv *= len(list(set(d['gLoad'])))
#     if (len(list(set(d['vg1_var']))) > 1):
#         v.append('vg1_var')
#         vNames.append('iVg')
#         nv *= len(list(set(d['vg1_var'])))
#     if (len(list(set(d['vd1_var']))) > 1):
#         v.append('vd1_var')
#         vNames.append('iVd')
#         nv *= len(list(set(d['vd1_var'])))
#
#     if (nv != len(d['freq'])):
#         raise ValueError('Product of swept VARs does not equal number of'
#                          ' measurement points!')
#
#     #   Write header
#     fid.write('BEGIN HEADER\n')
#     if ('freq' in v):
#         fid.write('% index(0) NHARM(0) ZO(3)\n')
#         fid.write('1 {} {} {}\n'.format(nharms, np.real(z0), np.imag(z0)))
#     else:
#         fid.write('% index(0) NHARM(0) F1(1) Z0(3)\n')
#         fid.write('1 {} {} {} {}\n'.format(nharms, list(set(d['freq']))[0],
#                                            np.real(z0), np.imag(z0)))
#     fid.write('END\n\n')
#
#     #   Write each entry
#     for n in range(nv):
#         for iv in range(len(v)):
#             s = ''
#             s += 'VAR {:s}(0)'.format(vNames[iv])
#             if (v[iv] == 'gSrc' or v[iv] == 'gLoad'):
#                 s += ' = {:d}\n'.format(np.where(list(set(d[v[iv]]))
#                                         == d[v[iv]][n])[0][0] + 1)
#             else:
#                 s += ' = {:d}\n'.format(np.where(np.sort(list(set(d[v[iv]])))
#                                         == d[v[iv]][n])[0][0] + 1)
#             fid.write(s)
#         fid.write('BEGIN LPDATA\n')
#         s = '% '
#         s += ('harm(1) GammaS(3) GammaL(3) PSrc_Ava(1) PLoad(1) PAE(1)'
#               ' G_Trans(1) Drain_eff_%(1) ')
#         s += ('Vq_out_v(1) Vq_in_v(1) Vvar_out_v(1) Vvar_in_v(1) Iout_a(1)'
#               ' Iin_a(1)\n')
#         fid.write(s)
#         for h in np.arange(1, nharms + 1, 1):
#             if ('iGammaS1' in vNames):
#                 if (h == 1):
#                     s = ''
#                     s += '{:d} {:8.8} {:8.8} '.format(h,
#                                                       np.real(d['gLoad'][n]),
#                                                       np.imag(d['gLoad'][n]))
#                     s += '{:8.8} {:8.8} '.format(np.real(d['gSrc'][n]),
#                                                  np.imag(d['gSrc'][n]))
#                     s += '{:f} {:f} {:f} '.format(d['pin'][n]-30,
#                                                   d['pout'][n]-30,
#                                                   d['pae'][n])
#                     s += '{:f} {:f} {:f} {:f} '.format(d['gain'][n],
#                                                        d['ndrain'][n],
#                                                        d['vd1'][n],
#                                                        d['vg1'][n])
#                     s += '{:f} {:f} {:f} {:f}\n'.format(d['vd1_var'][n],
#                                                         d['vg1_var'][n],
#                                                         d['id1'][n],
#                                                         d['ig1'][n])
#                 else:
#                     s = ''
#                     s += '{:d} {:8.8} {:8.8} '.format(h,
#                                                       np.real(d['gLoad'
#                                                               + str(h)
#                                                               + 'fo'][n]),
#                                                       np.imag(d['gLoad'
#                                                               + str(h)
#                                                               + 'fo'][n]))
#                     s += '{:8.8} {:8.8} '.format(np.real(d['gSrc' + str(h) + 'fo'][n]),np.imag(d['gSrc' + str(h) + 'fo'][n]))
#                     s += '{:f} {:f} {:f} {:f} {:f} {:f} {:f} {:f} {:f} '.format(-800,-800,-800,-800,-800,-800,-800,-800,-800)
#                     s += '{:f} {:f}\n'.format(-800,-800)
#             else:
#                 if (h == 1):
#                     s = ''
#                     s += '{:d} {:8.8} {:8.8} '.format(h,np.real(d['gSrc'][n]),np.imag(d['gSrc'][n]))
#                     s += '{:8.8} {:8.8} '.format(np.real(d['gLoad'][n]),np.imag(d['gLoad'][n]))
#                     s += '{:f} {:f} {:f} '.format(d['pin'][n]-30,d['pout'][n]-30,d['pae'][n])
#                     s += '{:f} {:f} {:f} {:f} '.format(d['gain'][n],d['ndrain'][n],d['vd1'][n],d['vg1'][n])
#                     s += '{:f} {:f} {:f} {:f}\n'.format(d['vd1_var'][n],d['vg1_var'][n],d['id1'][n],d['ig1'][n])
#                 else:
#                     s = ''
#                     s += '{:d} {:8.8} {:8.8} '.format(h,np.real(d['gSrc' + str(h) + 'fo'][n]),np.imag(d['gSrc' + str(h) + 'fo'][n]))
#                     s += '{:8.8} {:8.8} '.format(np.real(d['gLoad' + str(h) + 'fo'][n]),np.imag(d['gLoad' + str(h) + 'fo'][n]))
#                     s += '{:f} {:f} {:f} {:f} {:f} {:f} {:f} {:f} {:f} '.format(-800,-800,-800,-800,-800,-800,-800,-800,-800)
#                     s += '{:f} {:f}\n'.format(-800,-800)
#             fid.write(s)
#         fid.write('END\n\n')
#
#     fid.close()
#
#     return


# def write_focus_lpd_single(filename, meas_data, file_order, formatArr=[]):
#     """write_focus_lpd(filename, meas_data):
#
#     Write entry in Focus load pull data file.
#
#     Parameters
#     ----------
#     filename : string
#         Filename of LPD file.
#     meas_data : dict
#         Data that will be put in the data file.  These should be
#         consistent with what was written using create_focus_lpd_file!  Takes
#         last index for eahc key specified.
#     file_order : list
#         Order that dictionary items whould be entered into the file.  Must have
#         same keywords.  May specify less measurements that are in the dict.
#     formatArr : int vector
#         Array that specifies what decimal to round to of the corresponding
#         meas_data value of index.
#     """
#     N = len(file_order)
#     if (formatArr):
#         if (len(formatArr) != N):
#             print 'Error: formatArr is not the same length as the number of parameters in meas_data'
#             return
#     else:
#         formatArr = np.ones(N)*4
#
#     fid = open(filename, 'a')
#     for i in range(0,N):
#         fid.write('{:>15}'.format(str(np.round(meas_data[file_order[i]][-1], decimals=int(formatArr[i])))))
#     fid.write('\n')
#     fid.close()
#     return


# def write_focus_lpd_file(filename, comment, f0, file_order, meas_data, Z0=50., Z0_load=50., Z0_source=50., parameter='load'):
#     """''write_focus_lpd_file(filename, comment, f0, file_order, meas_data, Z0=50., Z0_load=50., Z0_source=50., parameter='load')''
#
#     Create Focus load pull data file.
#
#     Parameters
#     ----------
#     filename : string
#         Filename of LPD file.
#     comment : string
#         Comment for loadpull file.
#     f0 : float
#         Freqeuency loadpull performed at.
#     meas_data : dict
#         Dictionary containing keys that will be put in the data file.
#     file_order : list
#         Order that dictionary items should be entered into the file.  Must have
#         same keywords. Do not input the Point column.
#     Z0 : float
#         Charcteristic impedance of loadpull file.
#     Z0_source : float
#         Source Impedance.
#     Z0_load : float
#         Load Impedance.
#     parameter : string, optional
#         Determines loadpull or sourcepull.  Either 'load' or 'source'.
#
#     Example
#     -------
#     Below is an example of what it will look like
#     ! Load Pull Measurement Data
#     !-------------------------------
#     ! File = C:\FOCUS\DATA\AWR_DATA\S1F60_925MHZ.LPD
#     ! Date = Tue Jul 17 09:42:17 2001
#     !-------------------------------------------------------
#     ! Comment =
#     ! Frequency = 0.9250 GHz
#     ! Char.Impedances = Source: 3.00 Ohm, Load: 3.00 Ohm
#     ! Source Impedance = 1.21  + j -0.54 Ohm
#     ! Input Power = 30.42 dBm
#     ! GAMMA_SR = Gs1fo=0.440<-155.8(deg)
#     ! IMPED_SR = Zs1fo=1.21-j0.54
#     ! Setup: 01G_708-TUNERS_WITH_OLDCKT.SET, DUT REF.
#     ! PreMatch: PMT_LD: Xpos=0, Ypos=0 ,PMT_SR: Xpos=0, Ypos=120
#     ! Impedance
#     !-------------------------------------------------------
#     Point    R       jX     Pin[dBm] Pout[dBm] Gain[dB] P.A.Eff[%] IMD3[dBc]
#     !-------------------------------------------------------
#     """
#     Z0_source = 50.; Z0_load = 50.; Z0 = 50.
#     N = len(file_order)
#     M = len(meas_data[file_order[0]])
#     fmt_pt = '{:>5d}'
#     fmt_col = '{:>20.10f}'
#     fmt = fmt_pt  +  N*fmt_col
#
#     # Create the file
#     fid = open(filename,'w')
#
#     if (parameter.lower() != 'load' and parameter.lower() != 'source'):
#         print 'Error: Invalid parameter to pull: parameter=',parameter
#         print '    No pull performed'
#         return
#
#     # Write header information
#     fid.write('! Load Pull Measurement Data\n')
#     fid.write('!---------------------------\n')
#     fid.write('! File = ' + filename + '\n')
#     fid.write('! Date = ' + time.asctime() + '\n')
#     fid.write('!---------------------------\n')
#     fid.write('! Comment = ' + comment + '\n')
#     fid.write('! Frequency = ' + str(f0) + ' Hz\n')
#     fid.write('! Char.Impedances = Source: ' + str(Z0_source) + ' Ohm, Load: ' + str(Z0_load) + ' Ohm\n')
#     if (parameter.lower() == 'load'):
#         Gamma = rfMath.z2gamma(Z0, Z0_load)
#         fid.write('! Load Impedance = ' + str(np.real(Z0)) + '  +  j' + str(np.imag(Z0)) + ' Ohm\n')
# #        fid.write('! Input Power = ' + str(Pin_dBm) + ' dBm\n')
#         fid.write('! GAMMA_LD = ' + str(np.abs(Gamma)) + '<' + str(np.angle(Gamma)*180/np.pi) + '(deg)\n')
#         fid.write('! IMPED_LD = ' + str(np.real(Z0)) + '  +  j' + str(np.imag(Z0)) + '\n')
#         fid.write('! Setup: Load Pull\n')
#     elif (parameter.lower() == 'source'):
#         Gamma = rfMath.z2gamma(Z0, Z0_source)
#         fid.write('! Source Impedance = ' + str(np.real(Z0)) + '  +  j' + str(np.imag(Z0)) + ' Ohm\n')
# #        fid.write('! Input Power = ' + str(Pin_dBm) + ' dBm\n')
#         fid.write('! GAMMA_SR = ' + str(np.abs(Gamma)) + '<' + str(np.angle(Gamma)*180/np.pi) + '(deg)\n')
#         fid.write('! IMPED_SR = ' + str(np.real(Z0)) + '  +  j' + str(np.imag(Z0)) + '\n')
#         fid.write('! Setup: Source Pull\n')
#     fid.write('! Prematch:\n')
#     fid.write('! Impedance\n')
#     fid.write('!-------------------------------------------------------\n')
#
#     fid.write('{:>5}'.format('Point'))
#     for s in file_order:
#         fid.write('{:>20}'.format(s))
#     fid.write('\n')
#     fid.write('!-------------------------------------------------------\n')
#
#     for m in range(M):
#         row = [m + 1]
#         row  + = [meas_data[i][m] for i in file_order]
#         fid.write(fmt.format(*row))
#         fid.write('\n')
#     fid.close()
#     return


def write_hdf5(filename, d, info='', overwrite=False, **kwargs):
    """write_hdf5(filename, d, info='', **kwargs)

    Create hdf5 file from multidimentional array.

    Parameters
    ----------
    filename : string
        Filename of output file.
    d : dict
        Dictionary of data.
    info : string (Optional)
        String that describes the data.
    overWrite : boolean
        Make sure to overwrite a file if it exists.
    kwargs : Keyword arguments (optional)
        Additional attributes to store with the data.
    """
    if (os.path.splitext(filename)[-1] != '.hdf5'):
        filename = filename + '.hdf5'
    if (os.path.exists(filename)):
        print('HDF5 file', filename, 'exists: DATA MAY BE OVERWRITTEN')
    if (overwrite):
        f = h5py.File(filename, 'w')
        print('DATA WILL DEFINITELY BE OVERWRITTEN ... you asked for it')
    else:
        f = h5py.File(filename, 'a')

    try:
        for k, v in d.items():
            try:
                f[k] = v
            except RuntimeError:
                del f[k]
                f[k] = v

        f.attrs['info'] = info
        for k in kwargs.keys():
            f.attrs[k] = kwargs[k]
    except:
        f.close()
        raise
    f.close()
    return


def read_hdf5(filename, verbose=True):
    """d = read_hdf5(filename, verbose=True)

    Read data from hdf5 file.  All attributes are stored in the keyword
    ``attrs``.

    Parameters
    ----------
    filename : string
        Filename of file to read.
    verbose : bool
        Print out information when opening file.

    Returns
    -------
    d : dict
        Data dictionary.
    """
    import h5py
    d = RFDict()

    if (verbose):
        print('Opening hdf5 file:', filename)
    if (not os.path.exists(filename)):
        raise IOError('File does not exist.')
    f = h5py.File(filename, 'r')
    for k, ds in f.items():
        d[k] = ds[()]

    d['attrs'] = {}
    for k, v in f.attrs.items():
        d['attrs'][k] = v
        if (k == 'info' and verbose):
            print('Info string:\n', v)

    if (verbose):
        print('')
    f.close()
    d._filename = filename
    return d


# def write_CITI(filename, NAME, Vname, VAR, Vtype, Dname, DATA, Dtype):
#     """``write_CITI(filename, VAR, Vtype, DATA, Dtype)``
#
#     Write a CITI formatted file. Since all data and inputs are in vector form
#     care must be taken in converting 2-D data to vectors.
#
#     Parameters
#     ----------
#     filename : string
#         Output file name.
#     NAME : string
#         Name for data set
#     Vname : array of strings
#         Names of independent variables
#     VAR : array of vectors (1-D)
#         Data of independent variables (keep order corresponding to data)
#     Vtype : array of strings
#         Types of independent variables, must be MAG or RI
#     Dname : array of strings
#         Names of dependent variables
#     DATA : array of vectors (1-D)
#         Data of dependent variables (order should correspond to variables)
#     Dtype : array of strings
#         Types of dependent variables, must be MAG or RI
#
#     Example
#     -------
#     >>> write_CITI('output.txt','LP data',['Bias', 'Pin'],[Bias,Pin],['MAG','MAG'],['Pout','PAE'],[Pout,PAE],['RI','MAG'])
#     """
#     if (len(Vname)!= len(VAR) or len(VAR) != len(Vtype)):
#         raise ValueError('Lengths of Vname, VAR, Vtype lists do not match')
#         return
#
#     if (len(Dname)!= len(DATA) or len(DATA) != len(Dtype)):
#         raise ValueError('Lengths of Dname, DATA, Dtype lists do not match')
#         return
#
#     Dtotal = 1
#     for i in range(0,len(VAR)):
#         Dtotal *= len(VAR[i])
# #        print Dtotal
#
#     for i in range(0,len(DATA)):
#         if len(DATA[i]) != Dtotal:
#             raise ValueError('Total data length is not correct')
#             return
#
#     fid = open(filename, 'w')
#     fid.write('CITIFILE A.01.01\n')
#     fid.write('NAME {}\n'.format(NAME))
#     # Write variables in header
#     for i in range(0,len(VAR)):
#         fid.write('VAR {} {} {}\n'.format(Vname[i], Vtype[i], len(VAR[i])))
#     # Write data in header
#     for i in range(0,len(DATA)):
#         fid.write('DATA {} {}\n'.format(Dname[i], Dtype[i]))
#     # Write variables
#     for i in range(0,len(VAR)):
#         fid.write('VAR_LIST_BEGIN\n')
#         for j in range(0,len(VAR[i])):
#             fid.write('{}\n'.format(VAR[i][j]))
#         fid.write('VAR_LIST_END\n')
#     # Write data
#     for i in range(0,len(DATA)):
#         fid.write('BEGIN\n')
#         for j in range(0,len(DATA[i])):
#             fid.write('{}\n'.format(DATA[i][j]))
#         fid.write('END\n')
#
#     fid.close()
#     return


# def s2ptos3p(filenames, output_filename, rev=[False, False, False], avg=False):
#     """``s3ptos2p(filenames, output_filenames, rev=[False, False, False], avg=False)``
#
#     Convert three s2p files into an s3p file
#
#     Parameters
#     ----------
#     filenames : tuple
#         Filenames of s2p files in this order:
#             1. File with VNA P1 = P1, VNA P2 = P3 (S13)
#             2. File with VNA P1 = P2, VNA P2 = P3 (S23)
#             3. File with VNA P1 = P1, VNA P2 = P2 (S12)
#     output_filename : string
#         Filename of output file (add .s3p)
#     rev : bool list
#         Specify whether file S-parameters are reversed.  (ie S11->S22, S12->S21,
#         etc.)
#     avg : bool
#         Average redundant S-parameters: S11, S22, S33
#     """
#     # Read in three s2p files
#     f1, S1 = read_xNp(filenames[0])
#     f2, S2 = read_xNp(filenames[1])
#     f3, S3 = read_xNp(filenames[2])
#
#     if (rev[0]):
#         S1 = rfMath.exchangePorts(S1, 0, 1)
#     if (rev[1]):
#         S2 = rfMath.exchangePorts(S2, 0, 1)
#     if (rev[2]):
#         S3 = rfMath.exchangePorts(S3, 0, 1)
#
#     # Check to make sure all s2p files have same freq points
#     for i in range(0,len(f1)):
#         if f1[i] == f2[i] == f3[i]:
#             continue
#         else:
#             print 's2p files do not have same freq points'
#             return
#
#     n = len(f1)
#
#     S = np.zeros((n,3,3),dtype=np.complex)
#     if (avg):
#         S[:,0,0] = np.average([S1[:,0],S3[:,0]],axis=0)
#         S[:,1,1] = np.average([S2[:,0],S3[:,3]],axis=0)
#         S[:,2,2] = np.average([S1[:,3],S2[:,3]],axis=0)
#     else:
#         S[:,0,0] = S1[:,0]
#         S[:,1,1] = S2[:,0]
#         S[:,2,2] = S1[:,3]
#
#     S[:,0,2] = S1[:,1]
#     S[:,2,0] = S1[:,2]
#
#     S[:,1,2] = S2[:,1]
#     S[:,2,1] = S2[:,2]
#
#     S[:,0,1] = S3[:,1]
#     S[:,1,0] = S3[:,2]
#
#     write_xNp(output_filename, f1, S)
#     return


# def s2ptos4p(filenames, output_filename, rev=[False, False, False, False, False, False], avg=False):
#     """``s3ptos2p(filenames, output_filenames, rev=[False, False, False, False, False, False], avg=False)``
#
#     Convert six s2p files into an s4p file
#
#     Parameters
#     ----------
#     filenames : tuple
#         Filenames of s2p files in this order (connections defined as VNA P1 to P2):
#             1. input to output
#             2. input to coupled port
#             3. input to isolated port
#             4. coupled port to isolated port
#             5. coupled port to output
#             6. isolated port to output
#     output_filename : string
#         Filename of output file (add .s4p). The ports are defined as:
#             Port 1 - Input
#             Port 2 - Output (thru)
#             Port 3 - Coupled
#             Port 4 - Isolated
#     rev : bool list
#         Specify whether file S-parameters are reversed.  (ie S11->S22, S12->S21,
#         etc.)
#     avg : bool
#         Average redundant S-parameters: S11, S22, S33
#     """
#     # Read in three s2p files
#     f1, Sin_out = read_xNp(filenames[0])
#     f2, Sin_cpld = read_xNp(filenames[1])
#     f3, Sin_isol = read_xNp(filenames[2])
#     f4, Scpld_isol = read_xNp(filenames[3])
#     f5, Scpld_out = read_xNp(filenames[4])
#     f6, Sisol_out = read_xNp(filenames[5])
#
#     if (rev[0]):
#         Sin_out = rfMath.exchangePorts(Sin_out, 0, 1)
#     if (rev[1]):
#         Sin_cpld = rfMath.exchangePorts(Sin_cpld, 0, 1)
#     if (rev[2]):
#         Sin_isol = rfMath.exchangePorts(Sin_isol, 0, 1)
#     if (rev[3]):
#         Scpld_isol = rfMath.exchangePorts(Scpld_isol, 0, 1)
#     if (rev[4]):
#         Scpld_out = rfMath.exchangePorts(Scpld_out, 0, 1)
#     if (rev[5]):
#         Sisol_out = rfMath.exchangePorts(Sisol_out, 0, 1)
#
#     # Check to make sure all s2p files have same freq points
#     for i in range(0,len(f1)):
#         if f1[i] == f2[i] == f3[i] == f4[i] == f5[i] == f6[i]:
#             continue
#         else:
#             print 's2p files do not have same freq points'
#             return
#
#     n = len(f1)
#
#     S = np.zeros((n,4,4),dtype=np.complex)
#     if (avg):
#         S[:,0,0] = np.average([Sin_out[:,0],Sin_cpld[:,0],Sin_isol[:,0]],axis=0) #S11
#         S[:,1,1] = np.average([Sin_out[:,3],Scpld_out[:,3],Sisol_out[:,3]],axis=0) #S22
#         S[:,2,2] = np.average([Sin_cpld[:,3],Scpld_isol[:,0],Scpld_out[:,0]],axis=0) #S33
#         S[:,3,3] = np.average([Sin_isol[:,3],Scpld_isol[:,3],Sisol_out[:,0]],axis=0) #S44
#     else:
#         S[:,0,0] = Sin_out[:,0] #S11
#         S[:,1,1] = Sin_out[:,3] #S22
#         S[:,2,2] = Sin_cpld[:,3] #S33
#         S[:,3,3] = Sin_isol[:,3] #S44
#
#     S[:,0,1] = Sin_out[:,1] #S12
#     S[:,0,2] = Sin_cpld[:,1] #S13
#     S[:,0,3] = Sin_isol[:,1] #S14
#
#     S[:,1,0] = Sin_out[:,2] #S21
#     S[:,1,2] = Scpld_out[:,2] #S23
#     S[:,1,3] = Sisol_out[:,2] #S24
#
#     S[:,2,0] = Sin_cpld[:,2] #S31
#     S[:,2,1] = Scpld_out[:,1] #S32
#     S[:,2,3] = Scpld_isol[:,1] #S34
#
#     S[:,3,0] = Sin_isol[:,2] #S41
#     S[:,3,1] = Sisol_out[:,1] #S42
#     S[:,3,2] = Scpld_isol[:,2] #S43
#
#     write_xNp(output_filename, f1, S)
#     return


##############################################################################
# Data functions
##############################################################################


# def dictToDict(dictionary):
#     row = len(dictionary)
#     data = {}
#     for key, value in dictionary[0].items():
#         try:
#             tmp = np.zeros((row,) + np.shape(value), dtype=value.dtype)
#             data[key] = tmp
#         except:
#             data[key] = np.zeros(row)
#
#     for i in range(row):
#         for key, value in dictionary[0].items():
#             try:
#                 data[key][i] = dictionary[i][key]
#             except:
#                 print 'Keyerror:',key, i
#                 data[key][i] = np.nan
#
#     return data


# def flattenDict(d):
#     dr = {}
#     ds = {}
#     n1 = 0
#     for k,v in d.items():
#         if (len(v.shape) <= 2):
#             ds[k] = v.shape
#             dr[k] = []
#         if (len(v.shape) == 1):
#             n1 = v.shape[0]
#     for i in range(0,n1):
#         im = max([v[1] if (len(v)==2) else v[0] for v in ds.values()])
#         for k,v in ds.items():
#             if (len(v) == 1):
#                 dr[k].extend(np.ones((im,))*d[k][i])
#             elif (len(v) == 2):
#                 dr[k].extend(d[k][i])
#     for k,v in dr.items():
#         dr[k] = np.array(v)
#     return dr


# def filterIndices(filterDict, data, retDict=False):
#     """``i_s = filterIndices(filterDict, data, retDict=False)``
#
#     Filter a dict object to contain only indices contained in filterDict.
#
#     Parameters
#     ----------
#     filterDict : dict
#         Key and value that data must have.
#     data : dict
#         Data dictionary.  Key is header name and value is numpy array.
#     retDict : bool (optional)
#         Returns dictionary with filtered values instead of the indices.
#
#     Returns
#     -------
#     i_s : array
#         Array of indices that satisfy filter.
#
#     Edits
#     -----
#     141027 :
#         Modified where(data == value) to ``np.isclose`` function.  Should help
#         with numbers that cannot be represented exactly as a float.
#     """
#     aix = []
#
#     if (filterDict):
#         for key,value in filterDict.items():
#             aix.append(np.where(np.isclose(data[key],value))[0])
# #            aix.append(np.where(data[key] == value)[0])
#         i_s = aix[0]
#         for i in range(1,len(aix)):
#             i_s = np.intersect1d(i_s, aix[i])
#     else:
#         N = np.shape(data[data.keys()[0]])[0]
#         i_s = np.where(np.ones(N))[0]
#     if (retDict):
#         newD = RFDict()
#         for key,value in data.items():
#             if (key == 'attrs'):
#                 continue
#             newD[key] = value[i_s]
#         return newD
#     return i_s


class RFDict(dict):
    def __init__(self, filename=None, **kwargs):
        """``rffile(filename=None)``

        Create file/data class.  Can handle hdf5, s2p, csv and delimited txt
        files.
        """
        if (filename):
            if (filename.split('.')[-1] == 'hdf5'):
                d = read_hdf5(filename, **kwargs)
                self._h = d.keys()
            elif (filename.split('.')[-1] == 's2p'):
                f, S = read_xNp(filename)
                d = {}
                d['S'] = S
                d['freq'] = f
            else:
                self._h, d = readAWR(filename, delimiter=None, retDict=True,
                                     **kwargs)
        else:
            d = {}
        super(RFDict, self).__init__(d)
        self._filename = filename
        return

    def __getitem__(self, y):
        rval = None
        try:
            rval = super(RFDict, self).__getitem__(y)
        except KeyError:
            if (isinstance(y, int) or isinstance(y, slice)):
                rval = self.get_meas(y)
            else:
                k = self._searchKey(y)
                if (y == k):
                    raise
                else:
                    rval = self[k]
        except TypeError:
            rval = self.get_meas(y)
        return rval

    def __repr__(self):
        """Output representation of RFDict"""
        h = 'RFDict from file: {:}'.format(self._filename)
        d = ('{' + ', '.join(['"' + str(k) + '":' + str(v.shape)
                              for k, v in self.items()]) + '}')
        return h + '\n' + d

    def keys(self):
        k = super(RFDict, self).keys()
        if ('attrs' in k):
            k.remove('attrs')
        return k

    def values(self):
        k = super(RFDict, self).keys()
        v = super(RFDict, self).values()
        if ('attrs' in k):
            i = k.index('attrs')
            v.pop(i)
        return v

    def items(self):
        k = super(RFDict, self).keys()
        v = super(RFDict, self).values()
        if ('attrs' in k):
            i = k.index('attrs')
            k.pop(i)
            v.pop(i)
        return zip(k, v)

    def get_meas(self, i):
        """``d = get_meas(i)``

        Get all keys at index ``i``.

        Parameters
        ----------
        i : int
            Index

        Returns
        -------
        d : dict
            Dictionary of parameters with index ``i``.
        """
        d = RFDict()
        d.update({k: v[i] for k, v in self.items()})
        return d

    def keySet(self, key, sort=True):
        """``set = keySet(key)``

        Return unique values for a dictionary key.

        Parameters
        ----------
        key : str
            Dictionary key.

        Returns
        -------
        set : array
            Unique values.
        """
        if (sort):
            return np.sort(list(set(self[key])))
        else:
            return list(set(self[key]))

    def saveData(self, filename=None, **kwargs):
        """``saveData(filename=None)``

        Saves data to original file.  If ``filename`` specified, changes save
        to new file (does not overwrite original).

        Parameters
        ----------
        filename : str
            Specify new filename to save to.
        """
        if filename is None:
            fout = self._filename
        else:
            fout = filename

        try:
            attrs = {}
            attrs.update(self['attrs'])
            attrs.pop('info')
            attrs.update(**kwargs)
            write_hdf5(fout, self, info=self['attrs']['info'], **attrs)
        except KeyError:
            writeData(fout, np.array(self.values()).T, self.keys())
        return

    def _searchKey(self, string):
        k = string
        h = self.keys()
        i = [i for i in range(len(h)) if h[i].lower().find(string.lower())
             != -1]
        if (len(i) == 1):
            k = h[i[0]]
        elif (len(i) > 1):
            m = ', '.join([h[j] for j in i])
            raise KeyError('Cannot match, ' + k + ', to a single key: ' + m)
        return k


#   {o.O}
#   (  (|
# ---"-"-
