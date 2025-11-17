% This assumes wavelength in freespace for simplicity
clear frequency c wavelength f0 physical_line magG angleG clear phs
clear V1 clear V2 clear gamma gammaL i j

frequency = linspace(8.9,11.9,31)*10^9;
c = 299792458;
Eeff = 9.7;
wavelength = c./(frequency*sqrt(Eeff));
f0=10.4*10^9;
physical_line = .25* c./(f0*sqrt(Eeff));

magG = .5;
angleG = -180:5:180;
gammaL = magG.*exp(1i*angleG/180*pi)';

phs = 2*pi./wavelength*physical_line;

% Set phase 1 to 0 for all frequencies for simplicity
V1 = abs(gammaL+1).^2;
V2 = abs(gammaL.*exp(-1i*phs)+exp(1i*phs)).^2;
gamma = sqrt(abs(1/2*V1+1/2*V2-1));

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
plot(frequency./10^9,sqrt(sum(gamma-abs(gammaL)).^2/size(gammaL,1)),'--','DisplayName',"RMS Error Theoretical",'LineWidth',3)
xlabel("Frequency (GHz)")
ylabel("RMS Error |Gamma_load|")

%%
wavelength = c./(frequency);
physical_line = .25* c./(f0);
phase0 = 2*pi./wavelength*physical_line;

wavelength = c./(frequency*sqrt(Eeff));
physical_line = .25* c./(f0*sqrt(Eeff));
phaseg = 2*pi./wavelength*physical_line;

figure
plot(phase0/pi*180)
hold on
plot(phaseg/pi*180)