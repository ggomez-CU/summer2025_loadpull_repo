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
            temp = jsondecode(str);
            fn = fieldnames(temp);
            for lp_idx=0:(length(fn))
                try
                    obj.freq =  temp.(fn{lp_idx}).wave_data.input_awave.x;
                    obj.input_awave(:,lp_idx) = temp.(fn{lp_idx}).wave_data.input_awave.mag.*(j*temp.(fn{lp_idx}).wave_data.input_awave.phase/180*pi);
                    obj.input_bwave(:,lp_idx) = temp.(fn{lp_idx}).wave_data.input_bwave.mag.*(j*temp.(fn{lp_idx}).wave_data.input_bwave.phase/180*pi);
                    obj.output_awave(:,lp_idx) = temp.(fn{lp_idx}).wave_data.output_awave.mag.*(j*temp.(fn{lp_idx}).wave_data.output_awave.phase/180*pi);
                    obj.output_bwave(:,lp_idx) = temp.(fn{lp_idx}).wave_data.output_bwave.mag.*(j*temp.(fn{lp_idx}).wave_data.output_bwave.phase/180*pi);
    
                    obj.sampler_1(:,lp_idx) = temp.(fn{lp_idx}).Sampler1;
                    obj.sampler_2(:,lp_idx) = temp.(fn{lp_idx}).Sampler1;
                    obj.mixer(:,lp_idx) = temp.(fn{lp_idx}).Mixer;
    
                    obj.input_awave_dBm(:,lp_idx) =  temp.(fn{lp_idx}).wave_data.input_awave.dBm_mag;
                    obj.input_bwave_dBm(:,lp_idx) =  temp.(fn{lp_idx}).wave_data.input_bwave.dBm_mag;
                    obj.output_awave_dBm(:,lp_idx) =  temp.(fn{lp_idx}).wave_data.output_awave.dBm_mag;
                    obj.output_bwave_dBm(:,lp_idx) =  temp.(fn{lp_idx}).wave_data.output_bwave.dBm_mag;
                catch
                    disp("sm up")
                end
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