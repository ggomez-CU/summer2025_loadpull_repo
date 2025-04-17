import csv
import matplotlib.pyplot as plt
import numpy as np

class LoadTunerCalCalc:
    def __init__(self, filename, x_max, y_max, step_size):
        self.filename =filename
        self.readfile()
        self.linear_fitting_gamma(x_max,step_size)
        self.linear_fitting_phi(y_max,step_size)
        self.plotdata()

    def readfile(self):
        cal_data_temp = csv.DictReader(open(self.filename),delimiter='\t')
        self.x_pos = np.array([float(row['X pos']) for row in cal_data_temp]).flatten()
        cal_data_temp = csv.DictReader(open(self.filename),delimiter='\t')
        self.y_pos = np.array([float(row['Y pos']) for row in cal_data_temp]).flatten()
        cal_data_temp = csv.DictReader(open(self.filename),delimiter='\t')
        self.gamma_s11 = np.array([float(row['Gamma s11']) for row in cal_data_temp]).flatten()
        cal_data_temp = csv.DictReader(open(self.filename),delimiter='\t')
        self.phi_s11 = np.array([float(row['Phi s11']) for row in cal_data_temp]).flatten()

    def plotdata(self):
        plt.subplot(1,2,1)
        plt.scatter(self.y_pos, self.gamma_s11, label='Data Gamma')
        plt.plot(self.y_pos_linear, self.gamma_linear , color='red', label=f'Linear fit: Gamma')
        plt.xlabel('x,y')
        plt.ylabel('phi,gamma')
        plt.legend()

        plt.subplot(1,2,2)
        plt.scatter(self.x_pos, self.phi_s11, label='Data Gamma')
        plt.plot( self.x_pos_linear, self.phi_linear , color='red', label=f'Linear fit: Gamma')
        plt.xlabel('x,y')
        plt.ylabel('phi,gamma')
        plt.legend()

        plt.show()

    def linear_fitting_gamma(self, y_max,step_size):
        idx = np.argwhere(self.gamma_s11 > .2)    
        coefficients = np.polyfit(self.y_pos[idx].flatten(), self.gamma_s11[idx].flatten(), deg=1)
        slope = coefficients[0]
        intercept = coefficients[1]

        num = int((y_max) / step_size + 1)
        self.y_pos_linear = np.linspace(0,y_max,num)

        # Create the regression line
        self.gamma_linear = slope * self.y_pos_linear + intercept

    def linear_fitting_phi(self, x_max,step_size):
        idx = np.argsort(self.x_pos)
        step = np.mean(np.diff(self.x_pos[idx]))
        L = len(self.x_pos)
        fft = np.fft.fft(self.phi_s11[idx])

        phi_range_len = int(step*L/(np.argmax(abs(fft[0:int(len(fft)/2)]))))
        phi_idx_len = int(L/(np.argmax(abs(fft[0:int(len(fft)/2)]))))

        x = self.x_pos[idx]
        phi_s11 = self.phi_s11[idx]

        phi_idx_start = np.argwhere(phi_s11 > 170)[0]
        phi_start = phi_s11[phi_idx_start][0]
        phi_idx_stop = phi_idx_start+int(phi_idx_len)
        phi_stop = phi_s11[phi_idx_stop][0]

        x_start = x[phi_idx_start][0]
        x_stop = x[phi_idx_stop][0]

        print(phi_idx_len, phi_idx_start, phi_idx_stop, [x_start, x_stop], [phi_start, phi_stop])

        coefficients = np.polyfit(np.array([x_start, x_stop]).flatten(), 
                                  np.array([phi_start, phi_stop]).flatten(),
                                  deg=1)
        slope = coefficients[0]
        intercept = coefficients[1]

        num = int((x_stop-x_start + 200) / step_size + 1)

        self.x_pos_linear = np.linspace(x_start - 100, x_stop + 100,num)

        # Create the regression line
        self.phi_linear = slope * self.x_pos_linear + intercept

    def linear_gamma_pos(self, gamma_desired):
        index = np.argmin(np.abs(self.gamma_linear-gamma_desired))
        return self.y_pos_linear[index]
    
    def linear_phi_pos(self, phase_desired):
        index = np.argmin(np.abs(self.phi_linear-phase_desired))
        return self.x_pos_linear[index]