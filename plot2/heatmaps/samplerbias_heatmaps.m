
files = [{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-21_19_33_Freq11.4to10.5/samplerbias_1.5V'}; ...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-21_14_35_Freq11.4to10.5/samplerbias_1.25V'}; ...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-21_10_06_Freq11.4to10.6/samplerbias_1.0V'};...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-22_00_31_Freq11.4to10.5/samplerbias_1.75V'};...
{'/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-22_05_30_Freq11.4to10.5/samplerbias_2.0V'}]

%%
for i = 1:size(files,1)
    temp = temp.add_data(string(files(i,:)))
end
%%
[temp.data.XVar_Discrete,bins] = discretize(temp.data.GateV,5);
 h = heatmap(temp.data, 'frequency', 'XVar_Discrete', ...
                'ColorVariable', 'Sampler1_V', 'ColorMethod', 'mean');
 %%
[temp.freqpowerbiastable.XVar_Discrete,bins] = discretize(temp.freqpowerbiastable.SamplerV_Mean,5);
heatmap(temp.freqpowerbiastable,'SetPower','XVar_Discrete','ColorVariable','RMSError')

%% for this file the gateV is actually the SamplerV. I flipped the channels so it saved the data differently. I promise this is correct