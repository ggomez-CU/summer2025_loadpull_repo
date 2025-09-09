classdef LoadPullClass2
    %POWERCALCLASS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        comments
        complex_load
        LUT%freq,power,load
        input_awave_dBm
        input_bwave_dBm
        output_awave_dBm
        output_bwave_dBm
        freq
        samplerbiaslist
        freq_point
        powermeter
        SetPower
        PNApower
        PAE
        Pdc
        gain
        drainI
        drainV
        gammamaglist
        gammaphslist
        powerlist
        gateI
        gateV
        sampler1
        sampler2
        DUT_output_dBm
        DUT_input_dBm
        cal
        folder
        scale1
        scale3
        scale5

        colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79";
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];
    end

    methods
        function obj = LoadPullClass2(folder)
            obj.LUT = LUTClass('/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/LUT');
            
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
            % obj = obj.resortpower();
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
                obj.gammaphslist = temp.Configuration.GammaPhaseList;
                obj.samplerbiaslist = temp.Configuration.Samplers.Bias;
                try
                    obj.powerlist = temp.Configuration.SetPower_dBm_;
                catch
                    obj.powerlist = temp.Configuration.InputPower_dBm_;
                end
                for lp_idx=1:(length(fn))
                    try
                        if size(obj.samplerbiaslist,1) > 1 && size(obj.freq,1) == 1
                            startPat = 'PNAPower_';
                            endPat = '_0';
                            [~,power_idx] = find((obj.powerlist)' == str2double(replace(extractBetween(fn{lp_idx},startPat,endPat),'_','.')));
                            phs_idx = str2num(fn{lp_idx}(end))+1;
                            [~,mag_idx] = find(obj.samplerbiaslist' == str2double(replace((fn{lp_idx}(end-3:end-1)),'_','.')));
                            
                        else
                            startPat = 'LoadPoint_';
                            endPat = '_0';
                            [~,power_idx] = find((obj.powerlist)' == str2double(replace(extractBetween(fn{lp_idx},startPat,endPat),'_','.')));
                            try
                                [~,mag_idx] = find(obj.gammamaglist' == round(abs(temp.(fn{lp_idx}).load_gamma.real+(j*temp.(fn{lp_idx}).load_gamma.imag)),3));
                                [~,phs_idx] = find(obj.gammaphslist' == round(180/pi*angle(temp.(fn{lp_idx}).load_gamma.real+(j*temp.(fn{lp_idx}).load_gamma.imag))));
                            catch
                                mag_idx = 1;
                                phs_idx = 1;
                            end
                        end
                        obj.powermeter(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).PowerMeter;
                        try
                            obj.SetPower(mag_idx,phs_idx, power_idx,freq_idx) = str2double(replace(extractBetween(fn{lp_idx},startPat,endPat),'_','.'));
                            obj.complex_load(mag_idx,phs_idx,power_idx,freq_idx) = obj.LUT.tuner2s11(temp.(fn{lp_idx}).load_gamma.real+(j*temp.(fn{lp_idx}).load_gamma.imag),obj.freq(freq_idx));
                        catch
                        end
                        obj.input_awave_dBm(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.input_awave.dBm_mag;
                        obj.input_bwave_dBm(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.input_bwave.dBm_mag;
                        obj.output_awave_dBm(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.output_awave.dBm_mag;
                        obj.output_bwave_dBm(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.output_bwave.dBm_mag;
                        try
                            obj.PAE(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).PAPerformance.PAE;
                            obj.Pdc(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).PAPerformance.DCPower;
                            obj.gain(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).PAPerformance.Gain;
                        catch
                        end
                        obj.sampler1(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.x1;
                        obj.sampler2(mag_idx,phs_idx, power_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.x2;

                        obj.PNApower(mag_idx,phs_idx, power_idx,freq_idx) = temp.(fn{lp_idx}).InputPower;
                        obj.freq_point(mag_idx,phs_idx,power_idx,freq_idx) = obj.freq(freq_idx);
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
            sizing = [size(obj.gammaphslist,1),size(obj.gammamaglist,1),size(obj.freq,2)];
            [obj.freq, idx] = sort(obj.freq);
            obj.freq_point = reshape(obj.freq_point(:,:,idx), sizing(1), sizing(2),[], sizing(3) );
            obj.input_awave_dBm = reshape(obj.input_awave_dBm(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.input_bwave_dBm = reshape(obj.input_bwave_dBm(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.output_awave_dBm = reshape(obj.output_awave_dBm(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.output_bwave_dBm = reshape(obj.output_bwave_dBm(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.complex_load = reshape(obj.complex_load(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.powermeter = reshape(obj.powermeter(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.PNApower = reshape(obj.PNApower(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.PAE = reshape(obj.PAE(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.Pdc = reshape(obj.Pdc(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.gain = reshape(obj.gain(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.sampler1 = reshape(obj.sampler1(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.sampler2 = reshape(obj.sampler2(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.DUT_input_dBm = reshape(obj.DUT_input_dBm(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
            obj.DUT_output_dBm = reshape(obj.DUT_output_dBm(:,:,idx), sizing(1), sizing(2),[],  sizing(3));
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
            ppt = Presentation(strcat('reports/',filename,'.pptx'));

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
            plot1 = Picture('png/ls_temp.png');
            replace(largesignalSlide,'Title','Large Signal Performance');
            replace(largesignalSlide,'Picture',plot1);

            for i = 1:size(obj.freq,2)

                obj.samplerspng(i)
                largesignalSlide = add(ppt,'Title and Picture');
                plot1 = Picture(strcat('png/samp_temp',num2str(i),'.png'));
                replace(largesignalSlide,'Title',strcat('Raw Sampler Performance at ', num2str(obj.freq(i)),' GHz'));
                replace(largesignalSlide,'Picture',plot1);
            end

            close(ppt);
            rptview(ppt);
        end

        function add2report_freq(obj, ppt,idx,title)
            import mlreportgen.ppt.*
            obj.largesignaladdpng(idx)
            largesignalSlide = add(ppt,'Title and Picture');
            plot1 = Picture(strcat('png/ls_temp',idx,'.png'));
            replace(largesignalSlide,'Title',strcat('Large Signal Performance ->',' ',title));
            replace(largesignalSlide,'Picture',plot1);

        end

        function coupledline_samplerchar(obj)
            temp = mean(permute(obj.sampler1(:,:,:),[2 1 3]));
            s1 = permute(temp,[3 2 1]);
            temp = mean(permute(obj.sampler2(:,:,:),[2 1 3]));
            s2 = permute(temp,[3 2 1]);
            temp = mean(permute(obj.DUT_input_dBm(:,:,:),[2 1 3]));
            pin = permute(temp,[3 2 1]);
            semilogy(mean(pin'),s1(1,:)-s1)
            hold on
            set(gca,'ColorOrderIndex',1)
            semilogy(mean(pin'),s2(1,:)-s2)
            xlabel("DUT Input Power (dBm)")
            ylabel("Sampler Output Voltage")
            legend(arrayfun(@num2str, obj.samplerbiaslist, 'UniformOutput', 0))
        end

        function obj = add2report_samp(obj, ppt,samp1,samp2,gamma,idx,title)
            import mlreportgen.ppt.*
            colororder(obj.colors)
            for plotidx = 1:size(gamma,2)
                [~, phsidx] = sort(angle(gamma(:,plotidx)));
                gamma(:,plotidx) = gamma(phsidx,plotidx);
                samp1(:,plotidx) = samp1(phsidx,plotidx);
                samp2(:,plotidx) = samp2(phsidx,plotidx);
            end
            obj.scale1(:,idx) = obj.addsamplerspng(samp1,samp2,gamma);
            saveas(gcf,strcat('png/samp1_temp',num2str(idx),'.png'));
            close all
            content = {'Sampler Av ', {sprintf('Sampler 1: %.3f', obj.scale1(2,idx)), sprintf('Sampler 2: %.3f', obj.scale1(3,idx)) },...
                'Sampler Offset (rather than -1)', {num2str(obj.scale1(4,idx))},...
                'Goodness Of fit ', {num2str(obj.scale1(5,idx))}};
            largesignalSlide = add(ppt,'Two Content');
            plot1 = Picture(strcat('png/samp1_temp',num2str(idx),'.png'));
            replace(largesignalSlide,'Title',strcat('Sampler Performance',' ',title));
            replace(largesignalSlide.Children(2),plot1);
            replace(largesignalSlide.Children(3),content);

            obj.scale3(:,idx) = obj.addsamplers3png(samp1,samp2,gamma);
            saveas(gcf,strcat('png/samp3_temp',num2str(idx),'.png'));
            close all
            content = {'Sampler Av ', {sprintf('Sampler 1: %d',obj.scale3(2,idx)), sprintf('Sampler 2: %.3f', obj.scale3(3,idx)) },...
                'Sampler Av3 ', {sprintf('Sampler 1: %.3f', obj.scale3(4,idx)), sprintf('Sampler 2: %.3f', obj.scale3(5,idx)) },...
                'Sampler Offset (rather than -1)', {num2str(obj.scale3(6,idx))},...
                'Goodness Of fit ', {num2str(obj.scale3(7,idx))}};
            largesignalSlide = add(ppt,'Two Content');
            plot1 = Picture(strcat('png/samp3_temp',num2str(idx),'.png'));
            replace(largesignalSlide,'Title',strcat('Sampler Performance x^3',' ',title));
            replace(largesignalSlide.Children(2),plot1);
            replace(largesignalSlide.Children(3),content);

            % obj.scale5(:,idx) = obj.addsamplers5png(samp1,samp2,gamma);
            % saveas(gcf,strcat('samp5_temp',num2str(idx),'.png'));
            % close all
            % content = {'Sampler Av ', {sprintf('Sampler 1: %.3f', obj.scale5(2,idx)), sprintf('Sampler 2: %.3f', obj.scale5(3,idx)) },...
            %     'Sampler Av3 ', {sprintf('Sampler 1: %.3f', obj.scale5(4,idx)), sprintf('Sampler 2: %.3f', obj.scale5(5,idx)) },...
            %     'Sampler Av2 ', {sprintf('Sampler 1: %.3f', obj.scale5(6,idx)), sprintf('Sampler 2: %.3f', obj.scale5(7,idx)) },...
            %     'Sampler Offset (rather than -1)', {num2str(obj.scale5(8,idx))},...
            %     'Goodness Of fit ', {num2str(obj.scale5(9,idx))}};
            % largesignalSlide = add(ppt,'Two Content');
            % plot1 = Picture(strcat('samp5_temp',num2str(idx),'.png'));
            % replace(largesignalSlide,'Title',strcat('Sampler Performance x^2 x^3',' ',title));
            % replace(largesignalSlide.Children(2),plot1);
            % replace(largesignalSlide.Children(3),content);
        end

        function ppt = init_report_freq(obj, filename)
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
            ppt = Presentation(strcat('reports/',filename,'_freq.pptx'));

            titleSlide = add(ppt,'Title Slide');
            replace(titleSlide,'Title','Simple Load Pull Report');
            replace(titleSlide,'Subtitle',temp.Comments);
            
            configSlide = add(ppt,'Title and Content');
            replace(configSlide,'Title','Test Configuration');
            content = {'Frequencies: (GHz)', {regexprep(num2str(config.Frequency'),'\s+',', ')},...
            'Input Powers: (dBm)', {regexprep(num2str(config.(fn{3})'),'\s+',', ')},...
            'Load Impedances: ',{'Gamma Magnitude: ', {regexprep(num2str(config.GammaMagnitudeList'),'\s+',', ')}, ...
            'Gamma Phase',{regexprep(num2str(config.GammaPhaseList'),'\s+',', ') } },...
            'Comments',{temp.Comments},...
            sprintf('Data and Time: %s',temp.DateAndTime)} ;
            replace(configSlide,'Content',content);
        end

        function largesignalpng(obj)
            figure()
            title("Large Signal Drive Up at Gamma 0.1")
            subplot(1,2,1) %over frequency
            yyaxis left
            scatter(obj.freq_point(:),obj.PAE(:),'filled');
            ylabel('PAE (%)')
            xlabel('Frequency (GHz)')
            yyaxis right
            scatter(obj.freq_point(:),obj.gain(:),'filled');
            ylabel('Gain')
            subplot(1,2,2)
            yyaxis left
            scatter(obj.DUT_output_dBm(:),obj.PAE(:),'filled');
            ylabel('PAE (%)')
            yyaxis right
            scatter(obj.DUT_output_dBm(:),obj.gain(:),'filled');
            ylabel('Gain')
            xlabel('DUT Output power (dBm)')
            saveas(gcf,'png/ls_temp.png');
            close all
        end
        function largesignaladdpng(obj,idx)
            figure()
            title("Large Signal Drive Up at Gamma 0.1")
            subplot(1,2,1) %over frequency
            yyaxis left
            scatter(obj.freq_point(:),obj.PAE(:),'filled');
            ylabel('PAE (%)')
            xlabel('Frequency (GHz)')
            yyaxis right
            scatter(obj.freq_point(:),obj.gain(:),'filled');
            ylabel('Gain')
            subplot(1,2,2)
            yyaxis left
            try
                plot(permute(obj.DUT_output_dBm,[3 4 1 2]),permute(obj.PAE,[3 4 1 2]));
                ylabel('PAE (%)')
                yyaxis right
                plot(permute(obj.DUT_output_dBm,[3 4 1 2]),permute(obj.gain,[3 4 1 2]));
            catch
                for i = 1:size(obj.DUT_output_dBm,4)
                    hold on
                    x = obj.DUT_output_dBm(:,:,:,i);
                    y1 = obj.PAE(:,:,:,i);
                    y2 = obj.gain(:,:,:,i);
                    for j = 1:size(obj.DUT_output_dBm,3) 
                        plot(x(:,:,j),y1(:,:,j),'Color',obj.colors(i));
                        ylabel('PAE (%)')
                        yyaxis right
                        plot(x(:,:,j),y2(:,:,j),'Color',obj.colors(i));
                    end
                end
            end
            ylabel('Gain')
            xlabel('DUT Output power (dBm)')
            saveas(gcf,strcat('png/ls_temp',idx,'.png'));
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
        end

        function scale = addsamplerspng(obj,samp1raw,samp2raw,gamma)
            scale = obj.fitdirectgamma(gamma,samp1raw,samp2raw);
            figure()
            subplot(3,3,1)   %over frequency
            title("Raw")
            hold on

            [s1,samp1idx] = max(samp1raw(:));
            [s2,samp2idx] = min(samp2raw(:));
            g = gamma(:);
            arrow1 = obj.get_arrow([angle(g(samp1idx)),s1*1000]);
            arrow2 = obj.get_arrow([angle(g(samp2idx)),s2*1000]);
            quiver(arrow1(1),arrow1(2),arrow1(3),arrow1(4),"black",'LineWidth',2)
            text(arrow1(1)-arrow1(3)*.5,arrow1(2)-arrow1(4)*.5,'Sampler 1')
            quiver(arrow2(1),arrow2(2),arrow2(3),arrow2(4),"black",'LineWidth',2)
            text(arrow2(1)-arrow2(3)*.5,arrow2(2)-arrow2(4)*.5,'Sampler 2')
            
            ylabel('Sampler (mV)')
            xlabel('data sampler')
            set(gca,'ColorOrderIndex',1)
            plot(angle(gamma),samp1raw*1000); 
            set(gca,'ColorOrderIndex',1)
            plot(angle(gamma),samp2raw*1000,'--'); 

            subplot(3,3,4)
            set(gca,'ColorOrderIndex',1)
            scatter(abs(gamma),abs(sqrt(scale(2)*samp1raw+scale(3)*samp2raw +...
                 scale(4))));
            ylabel('Calculated Output')
            xlabel('Magnitude Gamma')
            
            subplot(3,3,7)
            samp_phs = obj.fitdirectphs(gamma,samp1raw,samp2raw,[scale(2), scale(3)]);

            subplot(3,3,[2 3 5 6 8 9])  
            set(gca,'ColorOrderIndex',1)
            smithplot(sqrt(scale(2)*samp1raw+scale(3)*samp2raw +...
                scale(4)).*exp(j*angle(gamma)));
            hold on
            smithplot(1*exp(j*samp_phs(1)*2),'Marker','square','Color',[0 0 0],'ClipData',0)
            smithplot(1*exp(j*samp_phs(4)*2),'Marker','square','Color',[0 0 0],'ClipData',0)
            text(real(1.2*exp(j*samp_phs(1)*2)),imag(1.2*exp(j*samp_phs(1)*2)),'Sampler 1','HorizontalAlignment','center')
            text(real(1.2*exp(j*samp_phs(4)*2)),imag(1.2*exp(j*samp_phs(4)*2)),'Sampler 2','HorizontalAlignment','center')

            set(gca,'ColorOrderIndex',1)
            for plotidx = 1:size(gamma,2)
                smithplot(gamma(:,plotidx),'.','LineStyle', 'none' )
            end
            rmserr = rmse(abs(gamma),abs(sqrt(scale(2)*samp1raw+scale(3)*samp2raw +...
                 scale(4))));
            scale = [scale, samp_phs, rmserr];
        end

        function arrow = get_arrow(obj, arrow_point)
            XL = get(gca, 'XLim');
            YL = get(gca, 'YLim');
            Xran = XL(2)-XL(1);
            Yran = YL(2)-YL(1);
            arrow_length = sqrt((0.15*Yran)^2+(0.15*Xran)^2);
            switch true
                case arrow_point(1) < (Xran/2+XL(1)) && arrow_point(2) < (Yran/2+YL(1))
                    x_sign = 0.15;
                    y_sign = 0.15;
                    az = 45;
                case arrow_point(1) < (Xran/2+XL(1)) && arrow_point(2) > (Yran/2+YL(1))
                    x_sign = 0.15;
                    y_sign = -0.15;
                    az = 135;
                case arrow_point(1) > (Xran/2+XL(1)) && arrow_point(2) < (Yran/2+YL(1))
                    x_sign = -0.15;
                    y_sign = 0.15;
                    az = -45;
                case arrow_point(1) > (Xran/2+XL(1)) && arrow_point(2) > (Yran/2+YL(1))
                    x_sign = -0.15;
                    y_sign = -0.15;
                    az = -135;
                otherwise 
                    return 
            end

            updated_point = [arrow_point(1)-x_sign*Xran, arrow_point(2)-y_sign*Yran];
            arrow = [updated_point, x_sign*Xran, y_sign*Yran];
        end

        function scale = addsamplers3png(obj,samp1raw,samp2raw,gamma)
            scale = obj.fitdirectgamma3(gamma,samp1raw,samp2raw);
            figure()
            subplot(3,3,1)   %over frequency
            title("Raw")
            hold on

            [s1,samp1idx] = max(samp1raw(:));
            [s2,samp2idx] = min(samp2raw(:));
            g = gamma(:);
            arrow1 = obj.get_arrow([angle(g(samp1idx)),s1*1000]);
            arrow2 = obj.get_arrow([angle(g(samp2idx)),s2*1000]);
            quiver(arrow1(1),arrow1(2),arrow1(3),arrow1(4),"black",'LineWidth',2)
            text(arrow1(1)-arrow1(3)*.5,arrow1(2)-arrow1(4)*.5,'Sampler 1')
            quiver(arrow2(1),arrow2(2),arrow2(3),arrow2(4),"black",'LineWidth',2)
            text(arrow2(1)-arrow2(3)*.5,arrow2(2)-arrow2(4)*.5,'Sampler 2')
            
            ylabel('Sampler (mV)')
            xlabel('Angle Gamma Load (rad)')
            set(gca,'ColorOrderIndex',1)
            plot(angle(gamma),samp1raw*1000); 
            set(gca,'ColorOrderIndex',1)
            plot(angle(gamma),samp2raw*1000,'--'); 

            subplot(3,3,4)
            set(gca,'ColorOrderIndex',1)
            scatter(abs(gamma),sqrt(scale(2)*samp1raw+scale(3)*samp2raw +...
                (scale(4)*samp1raw).^3+(scale(5)*samp2raw).^3 + scale(6)))
            ylabel('Calculated Output')
            xlabel('Magnitude Gamma')

            subplot(3,3,7)
            samp_phs = obj.fitdirectphs3(gamma,samp1raw,samp2raw,[scale(2),scale(4), scale(3), scale(5)]);
            title('Data fit sampler voltage')
            ylabel('|Gamma|^2')
            xlabel('Angle Gamma Load (rad)')
            subplot(3,3,[2 3 5 6 8 9])  
            set(gca,'ColorOrderIndex',1)
            smithplot(sqrt(scale(2)*samp1raw+scale(3)*samp2raw +...
                (scale(4)*samp1raw).^3+(scale(5)*samp2raw).^3 + scale(6)).*exp(j*angle(gamma)));
            hold on
            smithplot(1*exp(j*samp_phs(1)*2),'Marker','square','Color',[0 0 0],'ClipData',0)
            smithplot(1*exp(j*samp_phs(4)*2),'Marker','square','Color',[0 0 0],'ClipData',0)
            text(real(1.2*exp(j*samp_phs(1)*2)),imag(1.2*exp(j*samp_phs(1)*2)),'Sampler 1','HorizontalAlignment','center')
            text(real(1.2*exp(j*samp_phs(4)*2)),imag(1.2*exp(j*samp_phs(4)*2)),'Sampler 2','HorizontalAlignment','center')

            set(gca,'ColorOrderIndex',1)
            for plotidx = 1:size(gamma,2)
                smithplot(gamma(:,plotidx),'.','LineStyle', 'none' )
            end
            rmserr = rmse(abs(gamma),sqrt(scale(2)*samp1raw+scale(3)*samp2raw +...
                (scale(4)*samp1raw).^3+(scale(5)*samp2raw).^3 + scale(6)));
            scale = [scale, samp_phs, rmserr];
        end
        
        function scale = addsamplers5png(obj,samp1raw,samp2raw,gamma)
            scale = obj.fitdirectgamma5(gamma,samp1raw,samp2raw)
            figure()
            subplot(1,2,1) %over frequency
            title("Raw")
            plot(angle(gamma),samp1raw*1000); hold on
            ylabel('Sampler (mV)')
            xlabel('data sampler')
            set(gca,'ColorOrderIndex',1)
            plot(angle(gamma),samp2raw*1000,'--');
            subplot(1,2,2)  
            polar(angle(gamma),sqrt(scale(2)*samp1raw+scale(3)*samp2raw +...
                (scale(4)*samp1raw).^3+(scale(5)*samp2raw).^3 +...
                (scale(6)*samp1raw).^2+(scale(7)*samp2raw).^2+scale(8)));
            hold on
            set(gca,'ColorOrderIndex',1)
            scatter(real(gamma),imag(gamma),'.')

        end

        function [scale] = fitdirectphs(obj,x,v1,v2,calscale)
            fun1 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                (calscale(1)*2*v1+variable(2));
            fun2 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                (calscale(2)*2*v2+variable(2));
            ub = [pi,40];
            lb = [-pi,-400];
            x1 = [pi/2,min(min(v1))*calscale(1)];
            [vars1, res1] = lsqnonlin(fun1,x1,lb,ub);
            [vars2, res2] = lsqnonlin(fun2,x1,lb,ub);
            if any(vars1 == ub) || any(vars1 == lb) || any(vars2 == ub) || any(vars2 == lb)
                disp(vars)
            end

            set(gca,'ColorOrderIndex',1)
            plot(angle(x),abs(x*exp(-j*vars1(1))+exp(j*vars1(1))).^2);
            hold on
            set(gca,'ColorOrderIndex',1)
            scatter(angle(x),calscale(1)*2*v1+vars1(2),'x');
            set(gca,'ColorOrderIndex',1)
            plot(angle(x),abs(x*exp(-j*vars2(1))+exp(j*vars2(1))).^2,'--');
            hold on
            set(gca,'ColorOrderIndex',1)
            scatter(angle(x),calscale(2)*2*v2+vars2(2),'.');
            scale = [vars1, res1, vars2, res2]; %6
        end

        function [scale] = fitdirectphs3(obj,x,v1,v2,calscale)
            fun1 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                abs(calscale(1)*2*v1+2*(calscale(2)*v1).^3+variable(2));
            fun2 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                abs(calscale(3)*2*v2+2*(calscale(4)*v2).^3+variable(2));

            ub = [pi,40];
            lb = [-pi,-400];
            x1 = [pi/2,-min(min(v1))*calscale(1)];

            opts = optimoptions('lsqnonlin','FunctionTolerance',1e-15);
            [vars1, res1] = lsqnonlin(fun1,x1,lb,ub,opts);
            [vars2, res2] = lsqnonlin(fun2,x1,lb,ub,opts);
            if any(vars1 == ub) || any(vars1 == lb) || any(vars2 == ub) || any(vars2 == lb)
                disp(vars)
            end

            set(gca,'ColorOrderIndex',1)
            plot(angle(x),abs(x*exp(-j*vars1(1))+exp(j*vars1(1))).^2);
            hold on
            set(gca,'ColorOrderIndex',1)
            scatter(angle(x),calscale(1)*2*v1+2*(calscale(2)*v1).^3+vars1(2),'x');
            set(gca,'ColorOrderIndex',1)
            plot(angle(x),abs(x*exp(-j*vars2(1))+exp(j*vars2(1))).^2,'--');
            hold on
            set(gca,'ColorOrderIndex',1)
            scatter(angle(x),calscale(3)*2*v2+2*(calscale(4)*v2).^3+vars2(2),'.');
            scale = [vars1, res1, vars2, res2];
        end

        function [scale] = fitdirectgamma(obj,x,v1,v2)
            fun1 = @(variable) abs(x*exp(j*variable(1))).^2 ...
                - (variable(2)*v1+variable(3)*v2+variable(4));
            ub = [pi,300,300,40];
            lb = [-pi,0,0,-400];
            x1 = [0,0,0,-2];
            [vars, res] = lsqnonlin(fun1,x1,lb,ub);
            plot(angle(x),abs(x*exp(j*vars(1))));
            hold on
            plot(angle(x),sqrt(vars(2)*v1+vars(3)*v2+vars(4)))
            close all
            if any(vars == ub) || any(vars == lb)
                disp(vars)
            end
            scale = [vars, res];
        end

        function [scale] = fitdirectgamma3(obj,x,v1,v2)
            fun1 = @(variable) abs(x*exp(j*variable(1))).^2 ...
                - (variable(2)*v1+variable(3)*v2+(variable(4)*v1).^3+(variable(5)*v2).^3+variable(6));
            ub = [pi,300,300,300,300,40];
            lb = [-pi,0,0,-100,-100,-400];
            x1 = [0,30,30,-1,-1,-2];
            opts = optimoptions('lsqnonlin','MaxFunctionEvaluations',1e4);
            [vars, res] = lsqnonlin(fun1,x1,lb,ub,opts);
            % plot(angle(x),abs(x*exp(j*vars(1))));
            % hold on
            % plot(angle(x),sqrt(vars(2)*v1+vars(3)*v2+(vars(4)*v1).^3+(vars(5)*v2).^3+vars(6)),'--')
            % % close all
            if any(vars == ub) || any(vars == lb)
                disp(vars)
            end
            scale = [vars, res];
        end

        function [scale] = fitdirectgamma5(obj,x,v1,v2)
            fun1 = @(variable) abs(x*exp(j*variable(1))).^2 ...
                - (variable(2)*v1+variable(3)*v2+(variable(4)*v1).^3+(variable(5)*v2).^3+(variable(6)*v1).^2+(variable(7)*v2).^2+variable(8));
            ub = [pi,300,300,300,300,300,300,40];
            lb = [-pi,0,0,-100,-100,-100,-100,-400];
            x1 = [0,30,30,-1,-1,-1,-1,-2];
            opts = optimoptions('lsqnonlin','MaxFunctionEvaluations',8e3,'MaxIterations',4e3);
            [vars, res] = lsqnonlin(fun1,x1,lb,ub,opts);
            % plot(angle(x),abs(x*exp(j*vars(1))));
            % hold on
            % plot(angle(x),sqrt(vars(2)*v1+vars(3)*v2+(vars(4)*v1).^3+(vars(5)*v2).^3+(vars(6)*v1).^2+(vars(7)*v2).^2+vars(8)))
            % close all
            scale = [vars, res];
        end
    
        function obj = generate_scale_factors(obj)
            for freq_idx = 1:size(obj.sampler1,4)
                for pow_idx = 1:size(obj.sampler1,3)
                    samp1 = permute(obj.sampler1(:,:,pow_idx,freq_idx),[2 1 3 4]);
                    samp2 = permute(obj.sampler2(:,:,pow_idx,freq_idx),[2 1 3 4]);
                    gamma = permute(obj.complex_load(:,:,pow_idx,freq_idx),[2 1 3 4]);
                    for plotidx = 1:size(gamma,2)
                        [~, phsidx] = sort(angle(gamma(:,plotidx)));
                        gamma(:,plotidx) = gamma(phsidx,plotidx);
                        samp1(:,plotidx) = samp1(phsidx,plotidx);
                        samp2(:,plotidx) = samp2(phsidx,plotidx);
                    end
                    obj.scale1(:,pow_idx,freq_idx) = obj.addsamplerspng(samp1,samp2,gamma);
                    obj.scale3(:,pow_idx,freq_idx) = obj.addsamplers3png(samp1,samp2,gamma);
                end
            end
        end

    end
end

