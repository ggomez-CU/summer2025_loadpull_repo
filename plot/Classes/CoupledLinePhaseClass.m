classdef CoupledLinePhaseClass
    %POWERCALCLASS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        datafit1
        datafit2

        range1
        range2

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
        phs1
        phs2
            
        powermeter
        inputpower

        freq
        bias
        sampler1
        sampler2

        sampler1normalized
        sampler2normalized

        complex_load

        reshapesize

        LUT
    end

    methods
        function obj = CoupledLinePhaseClass(folder)
            obj.LUT = LUTClass('/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/LUT');
            obj = obj.loaddata(folder);
           
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
                        
            obj = obj.resortshape(obj.reshapesize);
            obj = obj.normalizesamplers();
        end

        function obj = freq2table(obj, freq_idx, filename)
                fid = fopen(filename); 
                raw = fread(fid,inf); 
                str = char(raw'); 
                fclose(fid); 
                temp = jsondecode(str);
                obj.reshapesize = (size(temp.Configuration.GammaMagnitudeList,1)*size(temp.Configuration.GammaPhaseList,1));

                %get cal
                % temp.Config
                [folder2, ~, ~] = fileparts(temp.Configuration.Files.OutputCoupling_dB_);
                obj.cal = CalibrationClass(replace(folder2,'C:/Users/grgo8200/Documents/GitHub','/Users/gracegomez/Documents/Research Code Python'));
                data_idx = 1;
                fn = fieldnames(temp);
                for lp_idx=1:(length(fn))
                    try
                        obj.input_awave(:,data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.input_awave.y_real+(j*temp.(fn{lp_idx}).waveData.input_awave.y_imag);
                        obj.input_bwave(:,data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.input_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.input_bwave.y_imag);
                        obj.output_awave(:,data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.output_awave.y_real+(j*temp.(fn{lp_idx}).waveData.output_awave.y_imag);
                        obj.output_bwave(:,data_idx,freq_idx) = temp.(fn{lp_idx}).waveData.output_bwave.y_real+(j*temp.(fn{lp_idx}).waveData.output_bwave.y_imag);
                        
                        obj.complex_load(:,data_idx,freq_idx) = obj.LUT.tuner2s11(temp.(fn{lp_idx}).load_gamma.real+(j*temp.(fn{lp_idx}).load_gamma.imag),obj.freq(freq_idx));
        
                        obj.powermeter(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).PowerMeter;
        
                        obj.input_awave_dBm(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.input_awave.dBm_mag;
                        obj.input_bwave_dBm(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.input_bwave.dBm_mag;
                        obj.output_awave_dBm(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.output_awave.dBm_mag;
                        obj.output_bwave_dBm(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).waveData.output_bwave.dBm_mag;
                        
                        obj.sampler1(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.x1;
                        obj.sampler2(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.x2;
                        obj.bias(:,data_idx,freq_idx) =  temp.(fn{lp_idx}).Samplers.Bias;

                        obj.inputpower(:,data_idx,freq_idx) = temp.(fn{lp_idx}).InputPower;

                        data_idx = data_idx+1;
                    catch
                        disp("sm up")
                        disp(fn{lp_idx})
                    end
                end
                [obj.DUT_input_dBm(:,:,freq_idx),obj.DUT_output_dBm(:,:,freq_idx)] = ...
                            obj.cal.power_correction(obj.input_awave_dBm(:,:,freq_idx), obj.output_bwave_dBm(:,:,freq_idx),obj.freq(freq_idx));
        end

        function obj = normalizesamplers(obj)
            obj.sampler1normalized = permute(mean(obj.sampler1,1),[2 3 1]);
            obj.sampler2normalized = permute(mean(obj.sampler2,1),[2 3 1]);
           for freq_idx =1:size(obj.freq,2)
                obj.sampler1normalized(:,freq_idx) = rescale(obj.sampler1normalized(:,freq_idx),-1,1);
                obj.sampler2normalized(:,freq_idx) = rescale(obj.sampler2normalized(:,freq_idx),-1,1);
           end
        end

        function plotloglog(obj)
            plot(obj.input_awave_dBm,log10(obj.sampler2(1,:)-obj.sampler2))
        end

        function plotlog(obj)
            plot(obj.input_awave_dBm,(obj.sampler2(1,:)-obj.sampler2))
        end

        function obj = resortshape(obj, sampleidx)
            % sizing = [size(obj.input_awave_dBm,2)/sampleidx, sampleidx,size(obj.freq,2)];
            sizing = [obj.reshapesize,size(obj.freq,2)];
            % [~, idx] = sort(obj.bias);
            obj.input_awave_dBm = reshape(obj.input_awave_dBm, [],sizing(1),sizing(2));
            obj.input_bwave_dBm = reshape(obj.input_bwave_dBm, [],sizing(1),sizing(2));
            obj.output_awave_dBm = reshape(obj.output_awave_dBm, [],sizing(1),sizing(2));
            obj.output_bwave_dBm = reshape(obj.output_bwave_dBm, [],sizing(1),sizing(2));

            obj.powermeter = reshape(obj.powermeter, [],sizing(1),sizing(2));
            obj.inputpower = reshape(obj.inputpower, [],sizing(1),sizing(2));

            obj.input_awave = reshape(obj.input_awave, [],sizing(1),sizing(2));
            obj.input_bwave = reshape(obj.input_bwave, [],sizing(1),sizing(2));
            obj.output_awave = reshape(obj.output_awave, [],sizing(1),sizing(2));
            obj.output_bwave = reshape(obj.output_bwave, [],sizing(1),sizing(2));

            obj.bias = reshape(obj.bias, [],sizing(1),sizing(2));
            obj.sampler2 = reshape(obj.sampler2, [],sizing(1),sizing(2));
            obj.sampler1 = reshape(obj.sampler1, [],sizing(1),sizing(2));

            obj.complex_load = reshape(obj.complex_load, [],sizing(1),sizing(2));

            obj.DUT_input_dBm = reshape(obj.DUT_input_dBm, [],sizing(1),sizing(2));
            obj.DUT_output_dBm = reshape(obj.DUT_output_dBm, [],sizing(1),sizing(2));
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

        function plot_diff_normalized(obj)
            colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79", ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];

            for freq_idx =1:size(obj.freq,2)
                hold on

                plot(obj.freq(freq_idx)',max(obj.sampler1normalized(:,freq_idx)'+obj.sampler2normalized(:,freq_idx)'),'o','Color',colors(freq_idx))
            end
        end
        
        function obj = plot_data_fit(obj)
            colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79", ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];
            loadangle = permute(mean(angle(obj.complex_load),1),[2 3 1]);

            for freq_idx =1:size(obj.freq,2)
                disp(obj.freq(freq_idx))
                % scatter(loadangle(:,freq_idx),obj.sampler1normalized(:,freq_idx),'s','filled','Color',colors(freq_idx))
                hold on
                % scatter(loadangle(:,freq_idx),obj.sampler2normalized(:,freq_idx),'o','filled','Color',colors(freq_idx))
                obj.datafit1(:,freq_idx) = obj.fitdata(loadangle(:,freq_idx),obj.sampler1normalized(:,freq_idx));
                obj.datafit2(:,freq_idx) = obj.fitdata(loadangle(:,freq_idx),obj.sampler2normalized(:,freq_idx));
                hold off
            end
        end

        function obj = plot_data_fit2(obj,z0)
            colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79", ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];
            loadangle = permute(mean((obj.complex_load),1),[2 3 1]);
            obj.phs1 = [];
            obj.phs2 = [];

            for freq_idx =1:size(obj.freq,2)
                obj = obj.fitdirectphs(loadangle(:,freq_idx),permute(mean(obj.sampler1(:,:,freq_idx),1),[2 3 1]),permute(mean(obj.sampler2(:,:,freq_idx),1),[2 3 1]),z0);
            end
        end
    
        function [data] = fitdata(obj,x,y)
            %This is enforcing no dc offset and an amplitude of 1
            X = [x(:);x(:)+2*pi;x(:)+4*pi;x(:)+6*pi;x(:)+8*pi];
            Y = [y(:);y(:);y(:);y(:);y(:)];
            mdl =fittype('a*cos(x+c)','indep','x');
            options = fitoptions('Method','NonlinearLeastSquares',...
               'StartPoint',[1, pi],'lower',[0.9 0],'upper',[1.5,2*pi]);
            fitteddata = fit(X(:),Y(:),mdl,options);
            data = [fitteddata.a, fitteddata.c]';
            plot(fitteddata)
            scatter(X,Y)
        end

        function freqsurf(obj)
            loadangle = permute(mean((obj.complex_load),1),[2 3 1]);
            for freq_idx =1:size(obj.freq,2)
                x1 = loadangle(:,freq_idx);
                v1 = permute(mean(obj.sampler1(:,:,freq_idx),1),[2 3 1]);
                v2 = permute(mean(obj.sampler2(:,:,freq_idx),1),[2 3 1]);
                fun1 = @(x,y,z) sqrt(mean(abs(x1*exp(-j*x)+exp(j*x)).^2-(y*v1+z))^2);
                fun2 = @(x,y,z) sqrt(mean(abs(x1*exp(-j*x)+exp(j*x)).^2-(y*v2+z))^2);
                x=linspace(-pi,pi,101);
                y=linspace(10,100,101);
                z=linspace(-4,4,101);
                figure(1)
                % subplot(mod(size(obj.freq,2),7),mod(size(obj.freq,2),7)+1,freq_idx)
                score=fun1(x,y,z);
                surf(x,y,z,score);
                figure(2)
                % subplot(mod(size(obj.freq,2),7),mod(size(obj.freq,2),7)+1,freq_idx)
                score=fun2(x,y,z);
                surf(x,y,z,score);
            end
        end

        function obj = fitdirectphs(obj,x,v1,v2,z0)
            %This is enforcing no dc offset and an amplitude of 1
            % z0=54

            % zl = 50*(x+1)./(1-x);
            % x = (50*(x+1)./(1-x)-variable(4))./(50*(x+1)./(1-x)+variable(4));
            fun1 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-(variable(2)*v1+variable(3));
            fun2 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-(variable(2)*v2+variable(3));
            ub = [pi,300,40];
            lb = [0,10,-40];
            x1 = [pi/2,70,min(v1)*100];
            [vars1, res1] = lsqnonlin(fun1,x1,lb,ub);
            [vars2, res2] = lsqnonlin(fun2,x1,lb,ub);
            plot(angle(x),abs(x*exp(-j*vars1(1))+exp(j*vars1(1))).^2);
            hold on
            plot(angle(x),vars1(2)*v1+vars1(3));
            plot(angle(x),abs(x*exp(-j*vars2(1))+exp(j*vars2(1))).^2);
            plot(angle(x),vars2(2)*v2+vars2(3));
            1+1;
            
            close all
            obj.phs1 = [obj.phs1; vars1, res1];
            obj.phs2 = [obj.phs2; vars2, res2];
        end

        function obj = plot_data_fit3(obj,z0)
            colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79", ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];
            loadangle = permute(mean((obj.complex_load),1),[2 3 1]);
            obj.phs1 = [];
            obj.phs2 = [];

            for freq_idx =1:size(obj.freq,2)
                obj = obj.fc(loadangle(:,freq_idx),permute(mean(obj.sampler1(:,:,freq_idx),1),[2 3 1]),permute(mean(obj.sampler2(:,:,freq_idx),1),[2 3 1]),z0);
            end
        end

        function obj = fc(obj,x,v1,v2,z0)
            %This is enforcing no dc offset and an amplitude of 1
            zl = 50*(x+1)./(1-x);
            x1 = (zl-z0)./(zl+z0);
            fun1 = @(variable) abs(x1*exp(-j*variable(1))+exp(j*variable(1))).^2-(variable(2)*v1+variable(3));
            fun2 = @(variable) abs(x1*exp(-j*variable(1))+exp(j*variable(1))).^2-(variable(2)*v2+variable(3));
            ub = [pi,300,40];
            lb = [-pi,10,-40];
            x0 = [pi/2,80,min(v1)*100];
            A = [];
            b = [];
            Aeq = [];
            beq = [];
            [vars1, res1] = fmincon(fun1,x0,A,b,Aeq,beq,lb,ub);
            [vars2, res2] = fmincon(fun2,x0,A,b,Aeq,beq,lb,ub);
            plot(angle(x),abs(x*exp(-j*vars1(1))+exp(j*vars1(1))).^2);
            hold on
            plot(angle(x),vars1(2)*v1+vars1(3));
            plot(angle(x),abs(x*exp(-j*vars2(1))+exp(j*vars2(1))).^2);
            plot(angle(x),vars2(2)*v2+vars2(3));
            1+1;
            close all

            obj.phs1 = [obj.phs1; vars1, res1];
            obj.phs2 = [obj.phs2; vars2, res2];
        end
          

        function plot_data_normalized(obj)
            colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79", ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];
            loadangle = permute(mean(angle(obj.complex_load),1),[2 3 1]);

            for freq_idx =1:size(obj.freq,2)
                hold on
                [~, min1_idx] = min(obj.sampler1normalized(:,freq_idx));
                [~, min2_idx] = min(obj.sampler2normalized(:,freq_idx));
                yyaxis left
                plot(loadangle(:,freq_idx)',obj.sampler1normalized(:,freq_idx)', 'Color',colors(freq_idx), 'Marker', 'none')
                scatter(loadangle(min1_idx,freq_idx),obj.sampler1normalized(min1_idx(1),freq_idx), 'Marker', 'o','MarkerFaceColor',colors(freq_idx))
                yyaxis right
                scatter(loadangle(min2_idx,freq_idx),-obj.sampler2normalized(min2_idx(1),freq_idx), 'Marker', 'o','MarkerFaceColor',colors(freq_idx))
        
                plot(loadangle(:,freq_idx)',-obj.sampler2normalized(:,freq_idx)','--','Color',colors(freq_idx), 'Marker', 'none')
            end
        end

        function plot_data(obj)
            colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79", ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];

            loadangle = permute(mean(angle(obj.complex_load),1),[2 3 1]);
            for freq_idx =1:size(obj.freq,2)
                hold on
                [~, min1_idx] = min(obj.sampler1(:,:,freq_idx)');
                [~, min2_idx] = min(obj.sampler2(:,:,freq_idx)');
                yyaxis left
                plot(angle(obj.complex_load(:,:,freq_idx))',obj.sampler1(:,:,freq_idx)', 'Color',colors(freq_idx), 'Marker', 'none')
                scatter(angle(obj.complex_load(:,min1_idx(1),freq_idx)),(obj.sampler1(:,min1_idx(1),freq_idx)')', 'Marker', 'o','MarkerFaceColor',colors(freq_idx))
                yyaxis right
                plot(angle(obj.complex_load(:,:,freq_idx))',obj.sampler2(:,:,freq_idx)', '--','Color',colors(freq_idx), 'Marker', 'none')
                scatter(angle(obj.complex_load(:,min2_idx(1),freq_idx)),(obj.sampler2(:,min2_idx(1),freq_idx)')', 'Marker', 'o','MarkerFaceColor',colors(freq_idx))
            end
        end

        function plot_raw_phasealignmin(obj)
             for freq_idx =1:size(obj.freq,2)
                [~, min1_idx] = min(obj.sampler1(:,:,freq_idx)');
                [~, min2_idx] = min(obj.sampler2(:,:,freq_idx)');
                phasedelta(:,freq_idx) = (angle(obj.complex_load(min1_idx(1),freq_idx))'-angle(obj.complex_load(:,min2_idx(1),freq_idx))');
             end
             plot(obj.freq,phasedelta)
        end

        function plot_phase_circle(obj)
                        colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79", ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79" ...
                ];

            for freq_idx =1:size(obj.freq,2)
                hold on
                loadangle = permute(mean(angle(obj.complex_load),1),[2 3 1]);
                plot(obj.sampler1normalized(:,freq_idx)',obj.sampler2normalized(:,freq_idx)', 'Color',colors(freq_idx));
            end
        end

        function obj = scaling_samplers_cal(obj)
            for freq_idx =1:size(obj.freq,2)
                obj.range1(:,freq_idx) = range(obj.sampler1(:,:,freq_idx)');
                obj.range2(:,freq_idx) = range(obj.sampler2(:,:,freq_idx)');
            end
        end

        function plot_raw_phasealignmax(obj)
            for freq_idx =1:size(obj.freq,2)
                [~, max1_idx] = max(obj.sampler1(:,:,freq_idx)');
                [~, max2_idx] = max(obj.sampler2(:,:,freq_idx)');
                phasedelta(:,freq_idx) = (angle(obj.complex_load(:,max1_idx(1),freq_idx))'-angle(obj.complex_load(:,max2_idx(1),freq_idx))');
            end
            plot(obj.freq,phasedelta)
        end
    end
end

