clear all
close all
clc

dname = '../../data/systemvalidation/2025-07-07_13_51_Freq8.0to12.0/';

myFiles = dir(fullfile(dname,"*.json"));

%%
figure(1)
polar(0,0)
hold on
figure(2)
hold on
for file_idx= 1:size(myFiles,1)
    data = LoadPullDataClass(strcat(dname, '/', myFiles(file_idx).name)); 
    figure(1)
    data.plot_data
    figure(2)
    data.plot_s11gamma_dB(0)
    [xCenter, yCenter, radius, ~] = circlefit(real(data.gammaload),imag(data.gammaload)),
    offset_data(file_idx,:) = [data.frequency(file_idx), xCenter, yCenter, radius];
end