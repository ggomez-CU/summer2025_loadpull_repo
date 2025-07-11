clear all
close all
clc

dname = '../../../data/driveup/2025-04-24_15_26_Freq2.0to4.0_Pow-50.0to-20.0/';

myFiles = dir(fullfile(dname,"*.json"));
freqnames = {};

%%
for freq_idx= 1:size(myFiles,1)
    fid = fopen(strcat(dname, '/', myFiles(freq_idx).name)); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    freqnames = cat(1,freqnames,myFiles(freq_idx).name);
    try
        val(freq_idx) = jsondecode(str);
        lpidx_list = fieldnames(val(freq_idx));

        powernames = {}
        for power_idx=1:length(lpidx_list)
            powernames = cat(1,powernames,lpidx_list{end-power_idx})
            temp = val(freq_idx).(lpidx_list{end-power_idx});
            freq(freq_idx) =  temp.wave_data.input_awave.x;
            disp(freq)
            try
                input_awave(:,power_idx,freq_idx) = temp.wave_data.input_awave.mag.*(j*temp.wave_data.input_awave.phase/180*pi);
                input_bwave(:,power_idx,freq_idx) = temp.wave_data.input_bwave.mag.*(j*temp.wave_data.input_bwave.phase/180*pi);
                output_awave(:,power_idx,freq_idx) = temp.wave_data.output_awave.mag.*(j*temp.wave_data.output_awave.phase/180*pi);
                output_bwave(:,power_idx,freq_idx) = temp.wave_data.output_bwave.mag.*(j*temp.wave_data.output_bwave.phase/180*pi);

                sampler_1(:,power_idx,freq_idx) = temp.DCVoltages.Sampler1
                sampler_2(:,power_idx,freq_idx) = temp.DCVoltages.Sampler1
                mixer(:,power_idx,freq_idx) = temp.DCVoltages.Mixer

                input_awave_dBm(:,power_idx,freq_idx) =  temp.wave_data.input_awave.dBm_mag
                input_bwave_dBm(:,power_idx,freq_idx) =  temp.wave_data.input_bwave.dBm_mag
                output_awave_dBm(:,power_idx,freq_idx) =  temp.wave_data.output_awave.dBm_mag
                output_bwave_dBm(:,power_idx,freq_idx) =  temp.wave_data.output_bwave.dBm_mag
            catch
                disp("sm up")
            end
        end
    catch
    end
end

%%
% returncwd = '../../../plot/driveup_freq_samplers/DirectDataGraphs/'
% cd(returncwd)