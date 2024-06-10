import numpy as np
from focustuner import tuner
from focustuner import zva

# from DevonSubclasses import rffile
# from DevonSubclasses import tuner
# from DevonSubclasses import zva
import cmath
import time

class loadPoint(object):
    """Data for a single load.

    Parameters
    ----------
    S : complex 4x4 array
        S parameters of tuner at load "S11".
    mag : float
        Magnitude of S11.
    phase : float
        Phase of S11 in degrees.
    x : float
        x-position of tuner.
    y : float
        y-position of tuner.

    """

    def __init__(self, S, mag=None, phase=None, x=None, y=None):
        """Initialize load data and calculate mag and phase from Gamma."""
        self.x = x
        self.y = y
        self.S = S

        # Provide option to override mag and phase values instead of
        # calculating them from the actual measurement.
        if (mag is None) and (phase is None):
            s = complex(S[0],S[4])
            [self.mag, temp] = cmath.polar(s)
            self.phase = np.rad2deg(temp)
        else:
            self.mag = mag
            self.phase = phase
        return


def create_Gamma_circles(mags, innercircle_phase_step):
    """Create circles of Gamma at `mags` magnitudes.

    Parameters
    ----------
    mags : list or tuple
        Circle magnitudes.
    innercircle_phase_step : float
        Phase spacing of Gammas in innermost magnitude circle in degrees.

    Returns
    -------
    list
        Gamma values.

    """
    phase_steps = tuple(innercircle_phase_step*mags[0]/np.array(mags))
    print('Phase steps: ' + str(phase_steps))

    Gammas = np.array([0, 0]).reshape(1,2)
    for mag, phase_step in zip(mags, phase_steps):
        phases = tuple(np.linspace(0, 360 - phase_step,
                                   int(np.ceil(360/phase_step))))
        for phase in phases:
            Gammas = np.concatenate((Gammas, np.array([mag, phase-135]).reshape(1,2)),axis = 0)

    return Gammas


def linear_estimate(known_point_1, known_point_2, target_value, UpperBound = 100000, LowerBound = 0):
    """Linearly inter-/extra-polate from the known points.

    Parameters
    ----------
    known_point_1, known_point_2 : tuples
        x vs mag
        Known data points as (independent value, dependent value).
    target_value : float
        Desired dependent value.

    Returns
    -------
    float
        Estimated independent value for the desired dependent value.

    """

    if (known_point_2[0] > UpperBound):
        x2 = UpperBound
    elif  (known_point_2[0] < LowerBound):
        x2 = LowerBound
    else:
        x2 = float(known_point_2[0])

    if (known_point_1[0] > UpperBound):
        x1 = UpperBound - 1
    elif  (known_point_1[0] < LowerBound):
        x1 = LowerBound + 1
    else:
        x1 = float(known_point_1[0])

    y1 = float(known_point_1[1])
    y2 = float(known_point_2[1] )

    slope = float(float(y2-y1) / float(x2- x1))
    target = (target_value-(-slope*x1 +y1))/slope

    return target


def meas_S(zva):
    """Measure S parameters from the zva object."""
    time.sleep(1)

    temp = zva.instr.query('CALC:DATA:CALL? SDAT').replace(',',' ').split()
    Sarray = np.array([float(i) for i in temp])

    freq_min = 9e9
    freq_max = 11e9
    freq_points = int(zva.instr.query('SWE:POIN?'))
    freq_sweep = np.linspace(freq_min,freq_max,freq_points)

    stemp = np.reshape(Sarray,(4,-1))
    stemp=np.reshape(stemp.T,(freq_points,4,-1))
    stemp = np.reshape(stemp,(freq_points,-1))

    Smat = np.concatenate((freq_sweep.reshape(freq_points, 1),stemp),axis=1)

    return Smat