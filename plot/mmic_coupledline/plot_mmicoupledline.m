clear all
close all
clc

filename = ['/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/MMIC_coupledline_freqpower2025-07-30_09_34_Freq12.0to8.0'];
filename = ['/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/MMIC_coupledline_freqpower2025-07-29_09_57_Freq10.0to10.0'];
temp = CoupledLinePowerBiasClass(filename)
% % plot(temp.input_awave_dBm,temp.sampler2-temp.sampler2(1,:))

%%
subplot(2,2,1)
semilogy(temp.DUT_input_dBm,temp.sampler2(1,:)-temp.sampler2)
hold on 
semilogy(temp.DUT_input_dBm,temp.sampler1(1,:)-temp.sampler1)

subplot(2,2,2)
plot(temp.DUT_input_dBm,temp.sampler2)
hold on 
plot(temp.DUT_input_dBm,temp.sampler1)
