classdef LoadPullData

    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        input_awave
        input_bwave
        output_awave
        output_bwave
        input_awave_dBm
        input_bwave_dBm
        output_awave_dBm
        output_bwave_dBm
        sampler_1
        sampler_2
        mixer
        freq
    end

    methods
        function obj = LoadPullData(dname)
            obj = obj.loadpull_load(dname);
        end
        function obj = loadpull_load(obj, dname)
            disp("Loading data")
            fid = fopen(dname); 
            raw = fread(fid,inf); 
            str = char(raw'); 
            fclose(fid); 
            try
                val(freq_idx) = jsondecode(str);
                lpidx_list = fieldnames(val(freq_idx));
        
                powernames = {};
                for power_idx=0:(length(lpidx_list))
                    powernames = cat(1,powernames,lpidx_list{end-power_idx});
                    temp = val(freq_idx).(lpidx_list{end-power_idx});
                    obj.freq(freq_idx) =  temp.wave_data.input_awave.x;
                    try
                        obj.input_awave(:,lp_idx)) = temp.wave_data.input_awave.mag.*(j*temp.wave_data.input_awave.phase/180*pi);
                        obj.input_bwave(:,lp_idx) = temp.wave_data.input_bwave.mag.*(j*temp.wave_data.input_bwave.phase/180*pi);
                        obj.output_awave(:,lp_idx) = temp.wave_data.output_awave.mag.*(j*temp.wave_data.output_awave.phase/180*pi);
                        obj.output_bwave(:,lp_idx) = temp.wave_data.output_bwave.mag.*(j*temp.wave_data.output_bwave.phase/180*pi);
        
                        obj.sampler_1(:,lp_idx) = temp.DCVoltages.Sampler1;
                        obj.sampler_2(:,lp_idx) = temp.DCVoltages.Sampler1;
                        obj.mixer(:,lp_idx) = temp.DCVoltages.Mixer;
        
                        obj.input_awave_dBm(:,lp_idx) =  temp.wave_data.input_awave.dBm_mag;
                        obj.input_bwave_dBm(:,lp_idx) =  temp.wave_data.input_bwave.dBm_mag;
                        obj.output_awave_dBm(:,lp_idx) =  temp.wave_data.output_awave.dBm_mag;
                        obj.output_bwave_dBm(:,lp_idx) =  temp.wave_data.output_bwave.dBm_mag;
                    catch
                        disp("sm up")
                        disp(lpidx_list{end-power_idx})
                    end
                end
            catch
            end
            end
        function plot_wave_dBm(obj)
            figure
            plot(permute(mean(obj.input_awave_dBm),[2,3,1]),permute(mean(obj.output_awave_dBm),[2,3,1]))
            hold on
            plot(permute(mean(obj.input_awave_dBm),[2,3,1]),permute(mean(obj.output_bwave_dBm),[2,3,1]))
            plot(permute(mean(obj.input_awave_dBm),[2,3,1]),permute(mean(obj.input_bwave_dBm),[2,3,1]))
            xlabel("Input power (dBm) - input a wave")
            ylabel("Power (dBm)")
            legend("Output reflected - output a wave","Through power - input b wave","Input reflected - input b wave")
        end
        function [sampler_1_mean,sampler_2_mean,mixer_mean] = sampler_range(obj)
            figure
            sampler_1_mean = permute(mean(obj.sampler_1),[2,3,1]);
            sampler_2_mean = permute(mean(obj.sampler_1),[2,3,1]);
            mixer_mean = permute(mean(obj.sampler_1),[2,3,1]);

            plot(permute(mean(obj.input_awave_dBm),[2,3,1]),sampler_1_mean,'Marker', '*')
            hold on
            plot(permute(mean(obj.input_awave_dBm),[2,3,1]),mixer_mean,'Marker','+')
            plot(permute(mean(obj.input_awave_dBm),[2,3,1]),sampler_2_mean,'Marker','.')
            xlabel("Input power (dBm) - input a wave")
            ylabel("Power (dBm)")
            legend("Output reflected - output a wave","Through power - input b wave","Input reflected - input b wave")
        end
    end
end