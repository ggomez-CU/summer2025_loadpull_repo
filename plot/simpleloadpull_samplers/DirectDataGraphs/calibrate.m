clear all
close all
clc

assumed_Z1 = 18.884*exp(j*-89.426/180*pi);
assumed_Z2 = 9.442*exp(j*-89.426/180*pi);


%% Sampler Gain Interpolation
load("sampler_gain_3GHz.mat")
load("mixer_gain_3GHz.mat")
load("sampler_vrms_3GHz.mat")

interpolated_vrms = linspace(min(sampler_vrms_3GHz),max(sampler_vrms_3GHz),1000);
interpolated_sampler_Av = interp1(sampler_vrms_3GHz,(sampler_gain_3GHz),interpolated_vrms);
interpolated_mixer_Av = interp1(sampler_vrms_3GHz,(mixer_gain_3GHz),interpolated_vrms);

%% Visualization Sampler gain interpolation
figure(1)
close all
hold on
plot(interpolated_vrms,interpolated_sampler_Av)
plot(interpolated_vrms,interpolated_mixer_Av)
scatter(sampler_vrms_3GHz,sampler_gain_3GHz)
scatter(sampler_vrms_3GHz,mixer_gain_3GHz)

%% Z1 drive up file

addpath("../../driveup_freq_samplers/DirectDataGraphs/")

driveup_50Ohm = DriveUpData("../../../data/driveup/2025-04-24_15_26_Freq2.0to4.0_Pow-50.0to-20.0");
driveup_Z1 = DriveUpData("../../../data/driveup/2025-04-24_15_54_Freq2.0to4.0_Pow-50.0to-20.0");
driveup_Z1.sampler_range()

figure(1)
vrms_input = sqrt((permute(10.^(mean(driveup_Z1.input_bwave_dBm-driveup_Z1.input_awave_dBm)/10),[2,3,1])*0.001)/50);
[~, idx ] = min(abs(interpolated_vrms'-vrms_input(:,3)'));
plot(interpolated_vrms(idx),interpolated_sampler_Av(idx),'*')
Av_sampler = interpolated_sampler_Av(idx);
Av_mixer = interpolated_mixer_Av(idx);

%% Calibration Z1

sampler_1 = permute(mean(driveup_Z1.sampler_1),[2,3,1]);
sampler_2 = permute(mean(driveup_Z1.sampler_2),[2,3,1]);
mixer = permute(mean(driveup_Z1.mixer),[2,3,1]);
numerator_cal_z1 = 4*Av_sampler'./Av_mixer'.*mixer - sampler_1 - sampler_2;
denominator_cal_z1 = 2*sqrt(   sampler_1 .*   sampler_2 );
k1 = (sampler_1./sampler_2).*exp(j*numerator_cal_z1 ./ denominator_cal_z1);

%% Z2 drive up file

loadpull_Z2 = LoadPullData("../../../data/simpleloadpull_samplers/2025-04-25_12_09_Freq3.0_Pow-25.0.json");

%% Calibration Z2

% Because I was dumb in my testing all I have it one point (power 10 dB and
% freq whatever the file is. See the Readme for more info

idx_z2 = 15;

sampler_1 = permute(mean(loadpull_Z2.sampler_1),[2,3,1]);
sampler_2 = permute(mean(loadpull_Z2.sampler_2),[2,3,1]);
mixer = permute(mean(loadpull_Z2.mixer),[2,3,1]);

sampler_1 = sampler_1(3:5);
sampler_2 = sampler_2(3:5);
mixer = mixer(3:5);

numerator_cal_z2 = 4*Av_sampler(idx_z2)./Av_mixer(idx_z2).*mixer - sampler_1 - sampler_2;
denominator_cal_z2 = 2*sqrt(   sampler_1 .*   sampler_2 );
k2 = (sampler_1./sampler_2).*exp(j*numerator_cal_z2 ./ denominator_cal_z2);

%% The calcs

k1small = k1(15,3); %power, freq
Zind = (k2-k1small).*assumed_Z1*assumed_Z2/(assumed_Z1-assumed_Z2);


