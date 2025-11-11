classdef LoadFreqRawClass
    %POWERCALCLASS Summary of this class goes here
    %   By raw i mean no cal for a and b. there was a cal for s11
    properties
        freq
        s11
        tunerload
        thruphase
        thrufreq

        input_awave
        input_bwave
        output_awave
        output_bwave
    end

    methods
        function obj = LoadFreqRawClass(folder)
            obj = obj.loaddata(folder);
            obj = obj.thruset()
        end
        function obj = loaddata(obj, folder)
            Files = dir(fullfile(folder,"*.json"));
            startPat = '_' + wildcardPattern + '_' + wildcardPattern + '_';
            endPat = 'GHz';
            for file_idx= 1:size(Files(:),1)
            % for file_idx= 1:10
                try
                    freq(file_idx) = str2double(extractBetween(Files(file_idx).name,startPat,endPat)) ;
                catch
                end
            end
            
            [obj.freq, idx] = sort(freq);
                
            for k= 1:size(Files(:),1)
                try
                    obj = obj.freq2table(k,strcat(folder, '/', Files(idx(k)).name));
                catch
                end
            end
        end

        function obj = freq2table(obj, freq_idx, filename)
                fid = fopen(filename); 
                raw = fread(fid,inf); 
                str = char(raw'); 
                fclose(fid); 
                temp = jsondecode(str);
                fn = fieldnames(temp);
                data_idx = 1;
                for lp_idx=3:(length(fn))
                    try
                        obj.s11(data_idx, freq_idx) = temp.(fn{lp_idx}).s11.real+(j*temp.(fn{lp_idx}).s11.imag);
                        obj.tunerload(data_idx, freq_idx) = temp.(fn{lp_idx}).load_gamma.real+(j*temp.(fn{lp_idx}).load_gamma.imag);
                        
                        obj.input_awave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.input_awave.y_real+(j*temp.(fn{lp_idx}).waveData.input_awave.y_imag);
                        obj.input_bwave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.input_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.input_bwave.y_imag);
                        obj.output_awave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.output_awave.y_real+(j*temp.(fn{lp_idx}).waveData.output_awave.y_imag);
                        obj.output_bwave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.output_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.output_bwave.y_imag);
        
                        data_idx = data_idx+1;
                    catch
                        disp(fn{lp_idx})
                    end
               end
        end

        function obj = resortpower(obj, sampleidx)
            sizing = [sampleidx,size(obj.inputpower,2)/sampleidx,size(obj.inputpower,3)];
            [obj.freq, idx] = sort(obj.freq);
            obj.tunerload = reshape(obj.tunerload(:,:,idx), sizing);
            obj.s11 = reshape(obj.s11(:,:,idx), sizing);
           
        end

        function obj = thruset(obj)
            % thrusparam = sparameters('../../data/deembedsparam/LPSetup_Validation_2portthru_20250707_direct 4.s2p');
            thrusparam = sparameters('/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/deembedsparam0710/LPSetup_Validation_2portthru_20250707_direct 4.s2p')
            obj.thruphase = (angle(permute(thrusparam.Parameters(1,2,:),[3 2 1])))/pi*180;
            obj.thrufreq = thrusparam.Frequencies./1e9;
        end

        function theta = thruphase_freq(obj,freq_GHz)
            idx = find(obj.thrufreq()==freq_GHz);
            theta = obj.thruphase(idx);
        end

        function plot_data(obj)
            obj = obj.thruset()
            colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"];
            num_panels = size(obj.freq,2);
            sides = 1:floor(num_panels/2);
            area = sides.*(num_panels - 2*sides)/2;
            [~, x] = max(area);
            y = ceil(num_panels/x);
            % figure
            for freq_idx =1:size(obj.freq,2)
                subplot(x,y,freq_idx)
                polar(0,0)
                hold on
                scatter(real(obj.s11(:,freq_idx)),imag(obj.s11(:,freq_idx)),"filled",'Color',colors(1))
                scatter(real(obj.tunerload(:,freq_idx)),imag(obj.tunerload(:,freq_idx)),"filled",'Color',colors(2))
                s11_phscorrection = abs(obj.s11(:,freq_idx)).*exp(j*(angle(obj.s11(:,freq_idx))+obj.thruphase_freq(obj.freq(freq_idx))));
                scatter(real(s11_phscorrection),imag(s11_phscorrection),"filled",'Color',colors(3))
            end
            legend("n/a","S11","setload","Shifted")
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

