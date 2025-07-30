classdef PowerFreqClass
    %POWERCALCLASS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        gammaload %freq,power,load
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
        tab
        inputpower
    end

    methods
        function obj = PowerFreqClass(folder)
            obj = obj.loadpull_load(folder);
        end
        function obj = loadpull_load(obj, folder)
            Files = dir(fullfile(folder,"*.json"));
            startPat = '_' + wildcardPattern + '_' + wildcardPattern + '_';
            endPat = 'GHz';
    
            for k = 1 : length(Files)
                try
                    obj.freq(k) = str2double(extractBetween(Files(k).name,startPat,endPat)) ;
                    obj = obj.freq2table(k,strcat(folder, '/', Files(k).name));
                catch
                end
            end
            obj = obj.resortpower(5);
        end

        function obj = freq2table(obj, freq_idx, filename)
                fid = fopen(filename); 
                raw = fread(fid,inf); 
                str = char(raw'); 
                fclose(fid); 
                temp = jsondecode(str);
                fn = fieldnames(temp);
                for lp_idx=3:(length(fn))
                    try
                        % obj.freq =  str2double(extractBetween(file,startPat,endPat));
                        obj.input_awave(:,lp_idx-3, freq_idx) = temp.(fn{lp_idx}).waveData.input_awave.y_real+(j*temp.(fn{lp_idx}).waveData.input_awave.y_imag);
                        obj.input_bwave(:,lp_idx-3, freq_idx) = temp.(fn{lp_idx}).waveData.input_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.input_bwave.y_imag);
                        obj.output_awave(:,lp_idx-3, freq_idx) = temp.(fn{lp_idx}).waveData.output_awave.y_real+(j*temp.(fn{lp_idx}).waveData.output_awave.y_imag);
                        obj.output_bwave(:,lp_idx-3, freq_idx) = temp.(fn{lp_idx}).waveData.output_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.output_bwave.y_imag);
        
                        obj.powermeter(:,lp_idx-3, freq_idx) =  temp.(fn{lp_idx}).PowerMeter;
        
                        obj.input_awave_dBm(:,lp_idx-3, freq_idx) =  temp.(fn{lp_idx}).waveData.input_awave.dBm_mag;
                        obj.input_bwave_dBm(:,lp_idx-3, freq_idx) =  temp.(fn{lp_idx}).waveData.input_bwave.dBm_mag;
                        obj.output_awave_dBm(:,lp_idx-3, freq_idx) =  temp.(fn{lp_idx}).waveData.output_awave.dBm_mag;
                        obj.output_bwave_dBm(:,lp_idx-3, freq_idx) =  temp.(fn{lp_idx}).waveData.output_bwave.dBm_mag;

                        obj.inputpower(:,lp_idx-3, freq_idx) = temp.(fn{lp_idx}).InputPower;
                    catch
                        disp("sm up")
                        disp(fn{lp_idx})
                    end
               end
        end

        function obj = resortpower(obj, sampleidx)
            sizing = [sampleidx,size(obj.inputpower,2)/sampleidx,size(obj.inputpower,3)];
            [obj.freq, idx] = sort(obj.freq);
            obj.input_awave_dBm = reshape(obj.input_awave_dBm(:,:,idx), sizing);
            obj.input_bwave_dBm = reshape(obj.input_bwave_dBm(:,:,idx), sizing);
            obj.output_awave_dBm = reshape(obj.output_awave_dBm(:,:,idx), sizing);
            obj.output_bwave_dBm = reshape(obj.output_bwave_dBm(:,:,idx), sizing);

            obj.powermeter = reshape(obj.powermeter(:,:,idx), sizing);
            obj.inputpower = reshape(obj.inputpower(:,:,idx), sizing);

            obj.input_awave = reshape(obj.input_awave(:,:,idx), sizing);
            obj.input_bwave = reshape(obj.input_bwave(:,:,idx), sizing);
            obj.output_awave = reshape(obj.output_awave(:,:,idx), sizing);
            obj.output_bwave = reshape(obj.output_bwave(:,:,idx), sizing);
        end
        
        function [inputpm2pna, outputpm2pna] = couplingpm2pna_3d(obj)
            inputpm2pna = -obj.input_awave_dBm + obj.powermeter;
            outputpm2pna = -obj.output_bwave_dBm + obj.powermeter;
        end
        
        function plotcoupling(obj)
            [inputpm2pna, outputpm2pna] = obj.couplingpm2pna_3d()
            plot(permute(mean(inputpm2pna),[3 2 1]))
            hold on
            plot(permute(mean(outputpm2pna),[3 2 1]))
        end

        function [inputpm2pna, outputpm2pna] = couplingpm2pna_mean(obj)
            [inputpm2pna, outputpm2pna] = obj.couplingpm2pna_3d();
            inputpm2pna = mean(permute(mean(inputpm2pna),[2 3 1]));
            outputpm2pna = mean(permute(mean(outputpm2pna),[2 3 1]));
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

