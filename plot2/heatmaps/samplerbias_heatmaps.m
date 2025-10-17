
files = [{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-21_19_33_Freq11.4to10.5\samplerbias_1.5V'}; ...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-21_14_35_Freq11.4to10.5\samplerbias_1.25V'}; ...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-21_10_06_Freq11.4to10.6\samplerbias_1.0V'};...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-22_00_31_Freq11.4to10.5\samplerbias_1.75V'};...
{'C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\coupledline_samplers\LoadPullBiasing2025-08-22_05_30_Freq11.4to10.5\samplerbias_2.0V'}]

%%
temp = DataTableClass(string(files(1)))
%%
for i = 1:size(files,1)
    temp = temp.add_data(string(files(i,:)))
end
%%
[temp.data.XVar_Discrete,bins] = discretize(temp.data.GateV,5);
 h = heatmap(temp.data, 'frequency', 'XVar_Discrete', ...
                'ColorVariable', 'Sampler1_V', 'ColorMethod', 'mean');
 %%
temp = temp.freqpowerbias;

%%
[temp.freqpowerbiastable.SamplerBiasMeanbin,bins] = discretize(temp.freqpowerbiastable.SamplerV_Mean,5);
heatmap(temp.freqpowerbiastable,'SetPower','SamplerBiasMeanbin','ColorVariable','RMSError')

%% for this file the gateV is actually the SamplerV. I flipped the channels so it saved the data differently. I promise this is correct
[temp.freqpowerbiastable.SamplerBiasMeanbin,bins] = discretize(temp.freqpowerbiastable.SamplerV_Mean,5);
heatmap(temp.freqpowerbiastable,'frequency','SamplerBiasMeanbin','ColorVariable','RMSError')

%%
for i = 1:5
    biasTable = temp.freqpower(i);
    heatmap(biasTable,'frequency','SetPower','ColorVariable','RMSError')
    saveas(gcf,strcat('../png/biasnew',num2str(i),'.png'));
end