clear all
close all
clc

filename = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/PA_Spring2023/LoadPullBiasing2025-08-11_10_30_Freq8.9to11.9/draincurrent_28.154mA'
temp = LoadPullClass2(filename);

save data_LoadPullBiasing2025-08-11_10_30_draincurrent_28.154
%% Direct Scaling

%%
load data_08-11_10_30

%%
freq_idx = 1
pow_idx = 3

sampler1_raw = permute(temp.sampler1(:,:,pow_idx,freq_idx),[2 1 3 4]);
sampler2_raw = permute(temp.sampler2(:,:,pow_idx,freq_idx),[2 1 3 4]);
loadG = permute(temp.complex_load(:,:,pow_idx,freq_idx),[2 1 3 4]);
scale = temp.fitdirectphs(loadG,sampler1_raw,sampler2_raw);

%%

sampler1 = sampler1_raw*scale(2)+scale(3);
sampler2 = sampler2_raw*scale(6)+scale(7);


%%
close all
x = loadG(:)
yyaxis left
plot(angle(loadG),sampler1)
hold on
yyaxis right
plot(angle(loadG),sampler2)

%%
polar(angle(loadG),abs(sqrt(.5*sampler1+sampler2*.5-1)))
hold on
polar(angle(loadG)-scale(5),abs(loadG))

%%
plot(angle(loadG),abs(sqrt(.5*sampler1+sampler2*.5-1)))
hold on
plot(angle(loadG)-scale(5),abs(loadG))

%%
plot(angle(loadG),abs(sampler1+sampler2))
yyaxis right
plot(angle(loadG)-2*scale(5),abs(loadG).^2)



%%
freq_idx = 3
pow_idx = 1

sampler1_raw = permute(temp.sampler1(:,:,pow_idx,freq_idx),[2 1 3 4]);
sampler2_raw = permute(temp.sampler2(:,:,pow_idx,freq_idx),[2 1 3 4]);
loadG = permute(temp.complex_load(:,:,pow_idx,freq_idx),[2 1 3 4]);
scale = temp.fitdirectgamma(loadG,sampler1_raw,sampler2_raw)

polar(angle(loadG),sqrt(scale(2)*sampler1_raw+scale(3)*sampler2_raw+scale(4)));
hold on
polar(angle(loadG),abs(loadG))

%%
freq_idx = 1
pow_idx = 3

sampler1_raw = permute(temp.sampler1(:,:,pow_idx,freq_idx),[2 1 3 4]);
sampler2_raw = permute(temp.sampler2(:,:,pow_idx,freq_idx),[2 1 3 4]);
loadG = permute(temp.complex_load(:,:,pow_idx,freq_idx),[2 1 3 4]);
scale = temp.fitdirectgamma5(loadG,sampler1_raw,sampler2_raw)

polar(angle(loadG),sqrt(scale(2)*sampler1_raw+scale(3)*sampler2_raw +...
    (scale(4)*sampler1_raw).^3+(scale(5)*sampler2_raw).^3 +...
    (scale(6)*sampler1_raw).^5+(scale(7)*sampler2_raw).^5+scale(8)));
hold on
polar(angle(loadG),abs(loadG))


%%
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
