classdef LoadPullClass
    %POWERCALCLASS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        comments
        gammaload %freq,power,load
        input_awave_dBm
        input_bwave_dBm
        output_awave_dBm
        output_bwave_dBm
        freq
        freq_point
        powermeter
        PNApower
        PAE
        Pdc
        gain
        drainI
        drainV
        gammamaglist
        gateI
        gateV
        sampler1
        sampler2
        DUT_output_dBm
        DUT_input_dBm
        cal
        folder
    end

    methods
        function obj = LoadPullClass(folder)
            obj = obj.loadpull_load(folder);
            obj.folder = folder;
        end
        function obj = loadpull_load(obj, folder)
            % dimensions [power, freq, load]
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
            obj = obj.resortpower();
        end

        function obj = freq2table(obj, freq_idx, filename)
                fid = fopen(filename); 
                raw = fread(fid,inf); 
                str = char(raw'); 
                fclose(fid); 
                temp = jsondecode(str);
                [folder2, ~, ~] = fileparts(temp.Configuration.Files.OutputCoupling_dB_);
                obj.cal = CalibrationClass(replace(folder2,'C:/Users/grgo8200/Documents/GitHub','/Users/gracegomez/Documents/Research Code Python'));
                fn = fieldnames(temp);
                dataidx = 1;
                obj.gammamaglist = temp.Configuration.GammaMagnitudeList;
                for lp_idx=1:(length(fn))
                    try
                        obj.gammaload(:,dataidx, freq_idx) = temp.(fn{lp_idx}).load_gamma.real+(j*temp.(fn{lp_idx}).load_gamma.imag);
                        obj.powermeter(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).PowerMeter;
        
                        obj.input_awave_dBm(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).waveData.input_awave.dBm_mag;
                        obj.input_bwave_dBm(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).waveData.input_bwave.dBm_mag;
                        obj.output_awave_dBm(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).waveData.output_awave.dBm_mag;
                        obj.output_bwave_dBm(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).waveData.output_bwave.dBm_mag;

                        obj.PAE(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).PAPerformance.PAE;
                        obj.Pdc(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).PAPerformance.DCPower;
                        obj.gain(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).PAPerformance.Gain;
                        obj.sampler1(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).Samplers.x1;
                        obj.sampler2(:,dataidx, freq_idx) =  temp.(fn{lp_idx}).Samplers.x2;

                        obj.PNApower(:,dataidx, freq_idx) = temp.(fn{lp_idx}).InputPower;
                        obj.freq_point(:,dataidx,freq_idx) = obj.freq(freq_idx);
                        dataidx = dataidx + 1;
                    catch
                        disp("sm up")
                        disp(fn{lp_idx})
                    end
                    if (fn{lp_idx}) == "Comments"
                        obj.comments = temp.(fn{lp_idx});
                    end
    
                end
                [obj.DUT_input_dBm,obj.DUT_output_dBm] = ...
                            obj.cal.power_correction(obj.input_awave_dBm, obj.output_bwave_dBm,obj.freq(freq_idx));
        end

        function obj = resortpower(obj)
            sizing = [size(obj.input_awave_dBm,2)/size(obj.gammamaglist,1),size(obj.gammamaglist,1),size(obj.freq,2)];
            [obj.freq, idx] = sort(obj.freq);
            
            obj.input_awave_dBm = reshape(obj.input_awave_dBm(:,:,idx), sizing);
            obj.input_bwave_dBm = reshape(obj.input_bwave_dBm(:,:,idx), sizing);
            obj.output_awave_dBm = reshape(obj.output_awave_dBm(:,:,idx), sizing);
            obj.output_bwave_dBm = reshape(obj.output_bwave_dBm(:,:,idx), sizing);
            obj.gammaload = reshape(obj.gammaload(:,:,idx), sizing);
            obj.powermeter = reshape(obj.powermeter(:,:,idx), sizing);
            obj.PNApower = reshape(obj.PNApower(:,:,idx), sizing);
            obj.PAE = reshape(obj.PAE(:,:,idx), sizing);
            obj.Pdc = reshape(obj.Pdc(:,:,idx), sizing);
            obj.gain = reshape(obj.gain(:,:,idx), sizing);
            obj.sampler1 = reshape(obj.sampler1(:,:,idx), sizing);
            obj.sampler2 = reshape(obj.sampler2(:,:,idx), sizing);
            obj.DUT_input_dBm = reshape(obj.DUT_input_dBm(:,:,idx), sizing);
            obj.DUT_output_dBm = reshape(obj.DUT_output_dBm(:,:,idx), sizing);
        end
        function generate_report(obj, filename)
            files = dir(fullfile(obj.folder,"*.json"));
            file = strcat(obj.folder, '/', files(1).name);
            fid = fopen(file); 
            raw = fread(fid,inf); 
            str = char(raw'); 
            fclose(fid); 
            temp = jsondecode(str);
            fn = fieldnames(temp);
            config = temp.Configuration;
            fn = fieldnames(config);
            import mlreportgen.ppt.*
            ppt = Presentation(strcat(filename,'.pptx'));

            titleSlide = add(ppt,'Title Slide');
            replace(titleSlide,'Title','Simple Load Pull Report');
            replace(titleSlide,'Subtitle',temp.Comments);
            
            configSlide = add(ppt,'Title and Content');
            replace(configSlide,'Title','Test Configuration');
            content = {'Frequencies: (GHz)', {regexprep(num2str(config.Frequency'),'\s+',', ')},...
            'Input Powers: (dBm)', {regexprep(num2str(config.(fn{3})'),'\s+',', ')},...
            'Load Impedances: ',{'Gamma Magnitude: ', {regexprep(num2str(config.GammaMagnitudeList'),'\s+',', ')}, ...
            'Gamma Phase',{regexprep(num2str(config.GammaPhaseList'),'\s+',', ') } } };
            replace(configSlide,'Content',content);

            obj.largesignalpng()
            largesignalSlide = add(ppt,'Title and Picture');
            plot1 = Picture('ls_temp.png');
            replace(largesignalSlide,'Title','Large Signal Performance');
            replace(largesignalSlide,'Picture',plot1);

            for i = 1:size(obj.freq,2)

                obj.samplerspng(i)
                largesignalSlide = add(ppt,'Title and Picture');
                plot1 = Picture(strcat('samp_temp',num2str(i),'.png'));
                replace(largesignalSlide,'Title',strcat('Raw Sampler Performance at ', num2str(obj.freq(i)),' GHz'));
                replace(largesignalSlide,'Picture',plot1);
            end

            close(ppt);
            rptview(ppt);
        end
        function largesignalpng(obj)
            figure()
            title("Large Signal Drive Up at Gamma 0.1")
            subplot(1,2,1) %over frequency
            yyaxis left
            scatter(obj.freq,permute(obj.PAE(:,1,:),[3 1 2]));
            ylabel('PAE (%)')
            xlabel('Frequency (GHz)')
            yyaxis right
            scatter(obj.freq,permute(obj.gain(:,1,:),[3 1 2]));
            ylabel('Gain')
            subplot(1,2,2)
            yyaxis left
            scatter(permute(obj.DUT_output_dBm(:,1,:),[3 1 2]),permute(obj.PAE(:,1,:),[3 1 2]));
            ylabel('PAE (%)')
            yyaxis right
            scatter(permute(obj.DUT_output_dBm(:,1,:),[3 1 2]),permute(obj.gain(:,1,:),[3 1 2]));
            ylabel('Gain')
            xlabel('DUT Output power (dBm)')
            saveas(gcf,'ls_temp.png');
            close all
        end
        function samplerspng(obj,idx)
            figure()
            title("Samplers at 'ideal' operating frequency")
            subplot(1,2,1) %over frequency
            title("Raw")
            plot(permute(obj.sampler1(:,:,idx)*1000,[1 2 3]));
            ylabel('Sampler 1 (mV)')
            xlabel('data sampler')
            yyaxis right
            plot(permute(obj.sampler2(:,:,idx)*1000,[1 2 3]));
            ylabel('Sampler 2 (mV)')
            subplot(1,2,2)  
            scatter(permute(abs(obj.gammaload(:,:,idx)),[1 2 3]),permute((obj.sampler2(:,:,idx)+obj.sampler1(:,:,3))*1000,[1 2 3]));
            xlabel("Magnitude Gamma")
            ylabel("Sampler direct difference")
            saveas(gcf,strcat('samp_temp',num2str(idx),'.png'));
            close all
        end
    end
end

