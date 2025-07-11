classdef PowerCalClass
    %POWERCALCLASS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        gammaload
        input_awave
        input_bwave
        output_awave
        output_bwave
        input_awave_dBm
        input_bwave_dBm
        output_awave_dBm
        output_bwave_dBm
        freq
        powermeter
    end

    methods
        function obj = PowerCalClass(dname)
            obj = obj.loadpull_load(dname);
        end
        function obj = loadpull_load(obj, file)
            % disp("Loading data")
            fid = fopen(file); 
            raw = fread(fid,inf); 
            str = char(raw'); 
            fclose(fid); 
            temp = jsondecode(str);
            fn = fieldnames(temp)
            for lp_idx=3:(length(fn))
                try
                    % obj.freq =  str2double(extractBetween(file,startPat,endPat));
                    obj.input_awave(:,lp_idx-2) = temp.(fn{lp_idx}).waveData.input_awave.y_real+(j*temp.(fn{lp_idx}).waveData.input_awave.y_imag);
                    obj.input_bwave(:,lp_idx-2) = temp.(fn{lp_idx}).waveData.input_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.input_bwave.y_imag);
                    obj.output_awave(:,lp_idx-2) = temp.(fn{lp_idx}).waveData.output_awave.y_real+(j*temp.(fn{lp_idx}).waveData.output_awave.y_imag);
                    obj.output_bwave(:,lp_idx-2) = temp.(fn{lp_idx}).waveData.output_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.output_bwave.y_imag);
    
                    obj.gammaload(:,lp_idx-2) = temp.(fn{lp_idx}).GammaLoad.real+(j*temp.(fn{lp_idx}).GammaLoad.imag);
                    obj.powermeter(:,lp_idx-2) =  temp.(fn{lp_idx}).PowerMeter;
    
                    obj.input_awave_dBm(:,lp_idx-2) =  temp.(fn{lp_idx}).waveData.input_awave.dBm_mag;
                    obj.input_bwave_dBm(:,lp_idx-2) =  temp.(fn{lp_idx}).waveData.input_bwave.dBm_mag;
                    obj.output_awave_dBm(:,lp_idx-2) =  temp.(fn{lp_idx}).waveData.output_awave.dBm_mag;
                    obj.output_bwave_dBm(:,lp_idx-2) =  temp.(fn{lp_idx}).waveData.output_bwave.dBm_mag;
                catch
                    disp("sm up")
                end
            end
        end
        function plot_data(obj)
            % figure
            polar(0,0)
            hold on
            scatter(real(obj.gammaload),imag(obj.gammaload),"filled")
            scatter(real(obj.s11),imag(obj.s11),"filled")
            scatter(real(obj.loadpoint),imag(obj.loadpoint),"filled")
            legend("n/a","Gamma Load","S11","Load point")
        end
        function plot_dB_mag(obj, data)
            plot(10*log10(data))
        end
        function compare_sparameters(obj, data1, data2)
            obj.plot_dB_mag(abs(data1-data2))
        end
        function plot_s11gamma_dB(obj, phs_correction)
            s11_phscorrection = abs(obj.s11).*exp(j*(angle(obj.s11)+phs_correction*2/180*pi));
            % figure
            hold on
            obj.compare_sparameters(obj.s11,obj.gammaload)
            obj.compare_sparameters(s11_phscorrection,obj.gammaload)
            legend("S11 vs Gamma Load uncorrected","S11 vs Gamma Load corrected based on phase of 2port cal")
        end
    end
end

