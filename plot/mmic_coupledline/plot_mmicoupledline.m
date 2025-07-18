clear all
close all
clc

filename = 'C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\coupledline_samplers\MMIC_coupledline_freqpower2025-07-16_16_31_Freq10.0to10.0\2025-07-16_16_31_10.0GHz.json';
temp = CoupledLinePowerBiasClass(filename)

plot(temp.input_awave_dBm,temp.sampler2-temp.sampler2(1,:))
plot(temp.input_awave_dBm,temp.bias-temp.sampler2)