clear all
close all
clc

driveup_Z0 = DriveUpData('../../../data/driveup/2025-04-24_15_26_Freq2.0to4.0_Pow-50.0to-20.0/')
%%
close all
for plot_idx = 1:size(driveup_Z0.freq,2)
    figure(plot_idx)
    xlabel("Input Voltage (V)")
    ylabel("Sampler Voltage (V)")
    title(strcat("Sampler Gain for ",num2str(driveup_Z0.freq(plot_idx)/10^9)," GHz"))
    hold on
    vrms = sqrt(mean(abs(10.^(driveup_Z0.input_awave_dBm(:,:,plot_idx)/10))*0.001)/50);
    plot(vrms,mean(driveup_Z0.sampler_1(:,:,plot_idx)),'LineWidth',2)
    plot(vrms,mean(driveup_Z0.sampler_2(:,:,plot_idx)))
    plot(vrms,mean(driveup_Z0.mixer(:,:,plot_idx)))
    legend("Sampler 1", "Sampler 2", "Mixer")
    yyaxis right
    
    plot(vrms,mean(driveup_Z0.sampler_1(:,:,plot_idx))./(vrms.^2),'LineWidth',2)
    plot(vrms,mean(driveup_Z0.sampler_2(:,:,plot_idx))./(vrms.^2))
    plot(vrms,mean(driveup_Z0.mixer(:,:,plot_idx))./(vrms.^2))
end

sampler_gain_3GHz = mean(driveup_Z0.sampler_1(:,:,3))./(vrms.^2)
mixer_gain_3GHz = mean(driveup_Z0.mixer(:,:,3))./(vrms.^2)
sampler_vrms_3GHz = sqrt(mean(abs(10.^(driveup_Z0.input_awave_dBm(:,:,3)/10))*0.001)/50)