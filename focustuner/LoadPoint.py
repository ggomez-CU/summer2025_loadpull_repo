import numpy as np

class LoadPoint(object):
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
        print(S.T)
        print(S.T[1])

        # Provide option to override mag and phase values instead of
        # calculating them from the actual measurement.
        if mag is None:
            self.mag = abs(np.array(S)[0])
        else:
            self.mag = mag
        if phase is None:
            self.phase = np.rad2deg(np.array(S)[1])
        else:
            self.phase = phase
        return
