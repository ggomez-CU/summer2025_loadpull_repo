clear all
close all
clc

filename = 'C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\systemvalidation\loadimpedance\2025-07-07_13_51_Freq8.0to12.0';

data = LoadFreqRawClass(filename)

data.plot_data
% 
% s11_phscorrection = abs(data.s11).*exp(j*(angle(data.s11)+2.93*2/180*pi));
% scatter(real(s11_phscorrection),imag(s11_phscorrection),"filled")
% figure
% hold on
% plot(10*log10(abs(data.s11-data.gammaload)))
% plot(10*log10(abs(s11_phscorrection-data.gammaload)))
% legend("S11 vs Gamma Load uncorrected","S11 vs Gamma Load corrected based on phase of 2port cal")