% This assumes wavelength in freespace for simplicity
frequency = linspace(8,12,41)*10^9;
c = 299792458;
wavelength = c./frequency;
physical_line = 0.0075;

mag = .5;
angle = -180:5:180;
gammaL = mag.*exp(j*angle/180*pi)';

phs = 2*pi./wavelength*physical_line;

% Set phase 1 to 0 for all frequencies for simplicity
V1 = abs(gammaL+1).^2;
V2 = abs(gammaL.*exp(-j*phs)+exp(j*phs)).^2;
gamma = sqrt(abs(1/2*V1+1/2*V2-1))

% hold on
% subplot(2,2,1)
% plot(frequency,phs/pi*180);
% 
% subplot(2,2,2)
% hold on
% plot(angle,V1)
% plot(angle,V2)
% 
% subplot(2,2,3)
% plot(angle,gamma)
% 
% subplot(2,2,4)
plot(frequency./10^9,sqrt(sum(gamma-abs(gammaL)).^2/size(gammaL,1)))
xlabel("Frequency (GHz)")
ylabel("RMS Error |Gamma_load|")