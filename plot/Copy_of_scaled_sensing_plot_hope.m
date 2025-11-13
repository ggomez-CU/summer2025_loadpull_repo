clear all
close all
clc

filename = '/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/PA_Spring2023/LoadPullBiasing2025-08-11_10_30_Freq8.9to11.9/draincurrent_12.364mA';
temp = LoadPullClass2(filename);

save data_08-11_10_30
%% Direct Scaling

%%
load data_08-11_10_30

freq_idx = 1


sampler1_raw = permute(temp.sampler1(:,:,1,freq_idx),[2 1 3 4]);
sampler2_raw = permute(temp.sampler2(:,:,1,freq_idx),[2 1 3 4]);
loadG = permute(temp.complex_load(:,:,1,freq_idx),[2 1 3 4]);
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