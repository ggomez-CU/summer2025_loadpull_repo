clear all
% close all

loadfolder = '..\..\data\systemvalidation\loadgain2025-07-17_16_31_Freq8.0to8.0';
% loadfolder = '..\..\data\systemvalidation\loadgain2025-07-18_11_09_Freq8.0to8.0';
loadfolder = '..\..\data\systemvalidation\loadgain2025-07-18_10_58_Freq8.0to12.0';
% loadfolder = '..\..\data\systemvalidation\loadgain2025-07-18_13_20_Freq8.0to8.0';
% loadfolder = '..\..\data\systemvalidation\loadgain2025-07-17_14_15_Freq8.0to8.0';
pna2dutfolder = '..\..\data\deembedatten\2025-07-15_21_30_Freq12.0to8.0';
errorfolder = '..\..\data\errordata\1PORT_20250718';

data = LoadFreqClass(loadfolder,CalibrationClass(errorfolder,pna2dutfolder));

%%
polar(0,0)
hold on
freq_idx = 1
title("Comparing expected and measured load impedences")
scatter(real(data.gammaload(:,freq_idx)),imag(data.gammaload(:,freq_idx)),"filled")
% scatter(real(data.gammaload2),imag(data.gammaload2),"filled")
% scatter(real(data.tunerload(:,freq_idx)),imag(data.tunerload(:,freq_idx)),"filled")
scatter(real(data.s11(:,freq_idx)),imag(data.s11(:,freq_idx)),"filled")

% Look into magnitude of compensated input and output waves. expected the
% same or 40dB difference. 