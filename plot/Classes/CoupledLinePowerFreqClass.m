classdef CoupledLinePowerFreqClass
    %POWERCALCLASS Summary of this class goes here
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
        
        DUT_input_dBm
        DUT_output_dBm

        cal
            
        powermeter
        inputpower

        freq
        bias
        sampler1
        sampler2
        folder
    end

    methods
        function obj = CoupledLinePowerFreqClass(folder)
            obj = obj.loaddata(folder);
            obj.folder = folder;
           
        end
        function obj = loaddata(obj, folder)
            Files = dir(fullfile(folder,"*.json"));
            startPat = '_' + wildcardPattern + '_' + wildcardPattern + '_';
            endPat = 'GHz';
            for file_idx= 1:size(Files(:),1)
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

                %get cal
                % temp.Config
                [folder2, ~, ~] = fileparts(temp.Configuration.Files.OutputCoupling_dB_);
                obj.cal = CalibrationClass(replace(folder2,'C:/Users/grgo8200/Documents/GitHub','/Users/gracegomez/Documents/Research Code Python'));
                data_idx = 1;
                fn = fieldnames(temp);
                for lp_idx=1:(length(fn))
                    try
                        obj.input_awave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.input_awave.y_real+(j*temp.(fn{lp_idx}).waveData.input_awave.y_imag);
                        obj.input_bwave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.input_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.input_bwave.y_imag);
                        obj.output_awave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.output_awave.y_real+(j*temp.(fn{lp_idx}).waveData.output_awave.y_imag);
                        obj.output_bwave(data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.output_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.output_bwave.y_imag);
        
                        obj.powermeter(data_idx,freq_idx) =  temp.(fn{lp_idx}).PowerMeter;
        
                        obj.input_awave_dBm(data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.input_awave.dBm_mag;
                        obj.input_bwave_dBm(data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.input_bwave.dBm_mag;
                        obj.output_awave_dBm(data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.output_awave.dBm_mag;
                        obj.output_bwave_dBm(data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.output_bwave.dBm_mag;
                        
                        obj.sampler1(data_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.x1;
                        obj.sampler2(data_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.x2;
                        obj.bias(data_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.Bias;

                        obj.inputpower(data_idx,freq_idx) = temp.(fn{lp_idx}).InputPower;

                        data_idx = data_idx+1;
                    catch
                        disp("sm up")
                        disp(fn{lp_idx})
                    end
                end
                [obj.DUT_input_dBm,obj.DUT_output_dBm] = ...
                            obj.cal.power_correction(obj.input_awave_dBm, obj.output_bwave_dBm,obj.freq(freq_idx));
               
        end

        function generate_report(obj, filename)
            files = dir(fullfile(obj.folder,"*.json"));
            file = strcat(obj.folder, '/', files(1).name);
            fid = fopen(file); 
            raw = fread(fid,inf); 
            str = char(raw'); 
            fclose(fid); 
            temp = jsondecode(str);
            config = temp.Configuration;
            fn = fieldnames(config);
            import mlreportgen.ppt.*
            ppt = Presentation(strcat(filename,'pptx'));

            titleSlide = add(ppt,'Title Slide');
            replace(titleSlide,'Title','Sampler Coupling Report');
            replace(titleSlide,'Subtitle',temp.Comments);
            
            configSlide = add(ppt,'Title and Content');
            replace(configSlide,'Title','Test Configuration');
            content = {'Frequencies: (GHz)', {regexprep(num2str(config.Frequency'),'\s+',', ')},...
            'Input Powers: (dBm)', {regexprep(num2str(config.(fn{3})'),'\s+',', ')},...
            'Sampler DC Bias', {regexprep(num2str(config.Samplers.Bias),'\s+',', ')},...
            'Load Impedances: ',{'Gamma Magnitude: ', {regexprep(num2str(config.GammaMagnitudeList'),'\s+',', ')}, ...
            'Gamma Phase',{regexprep(num2str(config.GammaMagnitudeList'),'\s+',', ') } } };
            replace(configSlide,'Content',content);

            obj.samplerspng()
            largesignalSlide = add(ppt,'Title and Picture');
            plot1 = Picture('ls_temp.png');
            replace(largesignalSlide,'Title','Large Signal Performance');
            replace(largesignalSlide,'Picture',plot1);

            close(ppt);
            rptview(ppt);
        end
        function samplerspng(obj)
            figure()
            title("Sampler Performance")
            subplot(2,2,[1 3]) %over frequency
            scatter(obj.freq,obj.sampler1');
            ylabel('Sampler 1')
            xlabel('Frequency (GHz)')
            yyaxis right
            scatter(obj.freq,obj.sampler2');
            ylabel('Sampler 2')
            subplot(2,2,2)
            yyaxis left
            plot(obj.DUT_output_dBm,log10(obj.sampler1-obj.sampler2(1,:)));
            ylabel('log Sampler 1')
            yyaxis right
            plot(obj.DUT_output_dBm,log10(obj.sampler2-obj.sampler2(1,:)));
            ylabel('log Sampler 2')
            xlabel('DUT Output power (dBm)')
            subplot(2,2,4)
            yyaxis left
            plot(obj.DUT_output_dBm,(obj.sampler1));
            ylabel(' Sampler 1')
            yyaxis right
            plot(obj.DUT_output_dBm,(obj.sampler2));
            ylabel(' Sampler 2')
            xlabel('DUT Output power (dBm)')
            saveas(gcf,'ls_temp.png');
            close all
        end

        function plotloglog(obj)
            plot(obj.input_awave_dBm,log10(obj.sampler2(1,:)-obj.sampler2))
        end

        function plotlog(obj)
            plot(obj.input_awave_dBm,(obj.sampler2(1,:)-obj.sampler2))
        end

        function obj = resortshape(obj)
            sizing = [size(obj.input_awave_dBm,2)/size(obj.freq,2), size(obj.freq,2)];
            % [~, idx] = sort(obj.bias);
            obj.input_awave_dBm = reshape(obj.input_awave_dBm, sizing);
            obj.input_bwave_dBm = reshape(obj.input_bwave_dBm, sizing);
            obj.output_awave_dBm = reshape(obj.output_awave_dBm, sizing);
            obj.output_bwave_dBm = reshape(obj.output_bwave_dBm, sizing);

            obj.powermeter = reshape(obj.powermeter, sizing);
            obj.inputpower = reshape(obj.inputpower, sizing);

            obj.input_awave = reshape(obj.input_awave, sizing);
            obj.input_bwave = reshape(obj.input_bwave, sizing);
            obj.output_awave = reshape(obj.output_awave, sizing);
            obj.output_bwave = reshape(obj.output_bwave, sizing);

            obj.bias = reshape(obj.bias, sizing);
            obj.sampler2 = reshape(obj.sampler2, sizing);
            obj.sampler1 = reshape(obj.sampler1, sizing);

            obj.DUT_input_dBm = reshape(obj.DUT_input_dBm, sizing);
            obj.DUT_output_dBm = reshape(obj.DUT_output_dBm, sizing);
        end
        
        function [inputpm2pna, outputpm2pna] = couplingpm2pna_3d(obj)
            inputpm2pna = -obj.input_awave_dBm + obj.powermeter;
            outputpm2pna = -obj.output_bwave_dBm + obj.powermeter;
        end
        
        function plotcoupling(obj)
            [inputpm2pna, outputpm2pna] = obj.couplingpm2pna_3d();
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

