% This assumes wavelength in freespace for simplicity
% clear frequency c wavelength f0 physical_line magG angleG clear phs
% clear V1 clear V2 clear gamma gammaL i j
clear all
% close all
clc
hold on

frequency = linspace(8.9,11.9,31)*10^9;
c = 299792458;

wavelength = c./frequency;
f0=10.4*10^9;
line = .25* c./(f0); %at 10.4 GHz = 90 degree of SiC

idx = 1;
maglist = .1:.1:.4;
for magG = maglist
    angleG = -180:5:180;
    gammaL = magG.*exp(1i*angleG/180*pi);
    
    phs = 2*pi./wavelength'*line;
    
    % Set phase 1 to 0 for all frequencies for simplicity
    V1 = abs(gammaL+1).^2;
    V2 = abs(gammaL.*exp(-1i*phs)+exp(1i*phs)).^2;
    gamma(:,:,idx) = sqrt(abs(1/2*V1+1/2*V2-1));
    idx = idx+1;
end

gammaL = (maglist)'.*exp(1i*angleG/180*pi);
for freqidx = 1:1:length(frequency)
    Gtest = permute(gamma(freqidx,:,:),[3 2 1]);
    rmserror(freqidx) = rmse(abs(gammaL(:)),Gtest(:));
    % rmsG(freqidx) = sqrt(sum(Gtest(:)-abs(gammaL(:)).^2./size(gammaL(:),1)))
end


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
plot(frequency./10^9,rmserror,'--','DisplayName',"RMS Error Theoretical",'LineWidth',3)
% plot(frequency./10^9,rmsG,'--','DisplayName',"RMS Error Theoretical",'LineWidth',3)

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

%% From Beta and Pozar
clear all
close all
clc
points = 31; %must be odd
e = 8.8554*10^-12;
u = 4*pi*10^-7;
w = linspace(8.9,11.9,points)*10^9*2*pi;
k_0 = w*sqrt(e*u);
e_r = 9.7;
d= .5*10^-3;%depth where to find?
W= 45*10^-6;%Width
e_eff = (e_r+1)/2 + (e_r-1)/sqrt(1+12*d/W);
B_eff = k_0*sqrt(e_eff);
lambda_0 = 2*pi./k_0;
lambda_eff = 2*pi./B_eff;

hold on
plot(lambda_eff)
plot(lambda_0)

linelength_0 = lambda_0(floor(points/2)+1);
linelength_eff = lambda_eff(floor(points/2)+1);

phase_0 = linelength_0./lambda_0;
phase_eff = linelength_eff./lambda_eff;

figure
hold on
plot(phase_0)
plot(phase_eff)

%%
clear all
close all
clc

samplerphase = readmatrix('../Sparameters/phasefreq/phasevsfreqforsamplersbias.txt');
freq = samplerphase(:,1);
sampler1 = samplerphase(:,2:2+15);
sampler2 = samplerphase(:,end-15:end);

frequency = freq*10^9;
c = 299792458;
wavelength = c./frequency;
f0=10.6*10^9;
line = .25* c./(f0); %at 10.4 GHz = 90 degree of SiC
phs_0 = 2*pi./wavelength*line/pi*180;

diff = sampler2'-sampler1';
phs_mask = diff <0;
diff(phs_mask) = diff(phs_mask)+360;

subplot(1,2,1)
plot(freq,diff'-phs_0)
subplot(1,2,2)
hold on
plot(freq,phs_0)
plot(freq,diff)

mean(mean(diff'-phs_0))
