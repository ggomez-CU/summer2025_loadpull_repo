clear all
close all
clc

addpath("C:\Users\grgo8200\LocalOnly\DiscreteIS\SubSixTestHybridBoard\subsixtest\data\simpleloadpull_samplers")
% fname = "2025-04-21_14_22_Freq3.0_Pow-30.0.json" %Bad data, port 2 was cal'ed with low power
% fname = "2025-04-23_17_04_Freq3.0_Pow-20.0.json"
fname = "2025-04-24_12_15_Freq3.0_Pow-20.0.json"

fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = jsondecode(str);

lpidx_list = fieldnames(val);

for i=1:length(lpidx_list)-3
    disp(lpidx_list{end-i})
    temp = val.(lpidx_list{end-i});
    try
        % input_awave(:,i) = temp.wave_data.input_awave.y_real+j*temp.wave_data.input_awave.y_imag;
        % input_bwave(:,i) = temp.wave_data.input_bwave.y_real+j*temp.wave_data.input_bwave.y_imag;
        % output_awave(:,i) = temp.wave_data.output_awave.y_real+j*temp.wave_data.output_awave.y_imag;
        % output_bwave(:,i) = temp.wave_data.output_bwave.y_real+j*temp.wave_data.output_bwave.y_imag;
        % output_awave_mag(:,i) = temp.wave_data.output_awave.mag
        % output_awave_phs(:,i) = temp.wave_data.output_awave.phase
        % output_bwave_mag(:,i) = temp.wave_data.output_bwave.mag
        % output_bwave_phs(:,i) = temp.wave_data.output_bwave.phase
        angle_deg(:,i) = temp.wave_data.output_impedance.phase;
        output_impedance(:,i) = temp.wave_data.output_impedance.mag.*exp(j*temp.wave_data.output_impedance.phase/180*pi);
        output_impedance_mean(:,i) = mean(temp.wave_data.output_impedance.mag).*exp(j*mean(temp.wave_data.output_impedance.phase));
        gammamag(:,i) = temp.wave_data.output_impedance.mag;
        sampler_2(:,i) = (temp.Sampler2);
        sampler_1(:,i) = (temp.Sampler1);
        mixer(:,i) = (temp.Mixer);
    catch
    end
end

plot_title = sprintf('Sampler Voltage outputs at %d dBm input power, %d GHz', (val.(lpidx_list{2}).InputPower_dBm_) , (val.(lpidx_list{2}).Frequency));

%%
close all
hold on
plot(sampler_1')
plot(sampler_2')
plot(mixer')
legend("sampler 1","sampler 2", "mixer")
xlabel("Load Point index (high to low gamma)")
ylabel("DC sampler voltage (V)")
title(plot_title)

%%
% close all
figure
polarplot(output_impedance,'o')

