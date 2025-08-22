clear all
close all
clc

folder = ['2025-07-28_23_39_Freq12.0to8.0';
'2025-07-28_21_32_Freq12.0to8.0';
'2025-07-28_19_24_Freq12.0to8.0';
'2025-07-28_17_17_Freq12.0to8.0';
'2025-07-28_15_10_Freq12.0to8.0']

thrusparam = sparameters('../../data/deembedsparam/LPSetup_Validation_2portthru_20250707_direct 4.s2p');
outputsparam = sparameters('../../data/deembedsparam/Outputdeem2.s2p');
output_thruloss = 10*log10(abs(permute(outputsparam.Parameters(1,2,:),[3 2 1])));
thruloss = 10*log10(abs(permute(thrusparam.Parameters(1,2,:),[3 2 1])));

DUT2pm_output = -2*output_thruloss(51:1:111);
DUT2pm_input = -2*output_thruloss(51:1:111);
DUTthru = -2*thruloss(101:10:701);
%%
for k = 1 : size(folder,1)
    clear data pna2pm_output pna2pm_input pna2dut_output pna2dut_input
    dname = strcat('../../data/systemvalidation/',folder(k,:));
    
    data = PowerFreqClass(dname)
    
    [pna2pm_input,pna2pm_output] = data.couplingpm2pna_mean;
    hold on 
    data.plotcoupling()
    pna2dut_output = pna2pm_output + DUT2pm_output';
    pna2dut_input = pna2pm_input + DUT2pm_output' + DUTthru';
    pna2pm_input = pna2pm_input';
    pna2pm_output = pna2pm_output';
    pna2dut_input= pna2dut_input';
    pna2dut_output = pna2dut_output';
    mkdir(strcat('..\..\data\deembedatten\',folder(k,:)));
    save(strcat('..\..\data\deembedatten\',folder(k,:),'\pna2pm_input.mat'), 'pna2pm_input'); 
    save(strcat('..\..\data\deembedatten\',folder(k,:),'\pna2pm_output.mat'), 'pna2pm_output');
    save(strcat('..\..\data\deembedatten\',folder(k,:),'\pna2dut_input.mat'), 'pna2dut_input'); 
    save(strcat('..\..\data\deembedatten\',folder(k,:),'\pna2dut_output.mat'), 'pna2dut_output');
    
end