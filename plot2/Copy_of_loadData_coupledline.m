
clear all
close all
clc

addpath('/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/plot2/Classes')
addpath('/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/plot2/functions')

files = [{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-21_19_33_Freq11.4to10.5/samplerbias_1.5V'}; ...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-21_14_35_Freq11.4to10.5/samplerbias_1.25V'}; ...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-21_10_06_Freq11.4to10.6/samplerbias_1.0V'};...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-22_00_31_Freq11.4to10.5/samplerbias_1.75V'};...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-22_05_30_Freq11.4to10.5/samplerbias_2.0V'}];

LUTfolder = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/LUT1';
gainfolder = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/GainTable2';

coupledline_data = DataTableClass(files(1),LUTfolder,gainfolder);

for i = 1:size(files,1)
    coupledline_data = coupledline_data.add_data(files(i));
end

coupledline_data = coupledline_data.freqpowerbias_bL2dependent;

%%
scatter(coupledline_data.freqpowerbiasbL2table.frequency,coupledline_data.freqpowerbiasbL2table.RMSError)
scatter(coupledline_data.freqpowerbiasbL2table.SamplerV_Mean,coupledline_data.freqpowerbiasbL2table.RMSError)
scatter(coupledline_data.freqpowerbiasbL2table.DUT_output_dBm_Mean,coupledline_data.freqpowerbiasbL2table.RMSError)
scatter(coupledline_data.freqpowerbiasbL2table.SamplerV_Mean,coupledline_data.freqpowerbiasbL2table.ScaleFactorKappa1)
scatter(coupledline_data.freqpowerbiasbL2table.SamplerV_Mean,coupledline_data.freqpowerbiasbL2table.ScaleFactorKappa2)