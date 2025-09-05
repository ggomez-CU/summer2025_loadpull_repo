clear all
close all
clc

filename = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/coupledline_samplers/LoadPullBiasing2025-08-22_05_30_Freq11.4to10.5/samplerbias_2.0V';
temp = LoadPullClass2(filename);

save data_LoadPullBiasing2025-08-22_05_30
%% Direct Scaling

ppt = temp.init_report_freq('loadreport_samplerlocations_LoadPullBiasing2025-08-11_10_30_draincurrent_')
idx = 1
for i = 1:size(temp.sampler1,4)
    for j = 1:size(temp.sampler1,3)
        title = sprintf('  \nFrequency %.2f GHz, Power %d dBm', temp.freq(i),temp.powerlist(j));
        temp = temp.add2report_samp(ppt,permute(temp.sampler1(:,:,j,i),[2 1 3 4]),...
            permute(temp.sampler2(:,:,j,i),[2 1 3 4]),...
            permute(temp.complex_load(:,:,j,i),[2 1 3 4]),idx,...
            title);
        idx = idx + 1;
    end
end

close(ppt);
rptview(ppt);