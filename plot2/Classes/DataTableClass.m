classdef DataTableClass
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        freq_list
        sampler_bias_list
        power_list

        folder
        comments
        dateandtime
        config

        LUT
        LUTfolder
        cal
        gaintable
        diodeDCIV
        gaintablefolder

        data
        samplercouplingtable
        samplercouplingfreqtable
        freqpowerbiastable
        freqpowerbiasbL2table

        colors = [ ...
                    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", ...
                    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", ...
                    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", ...
                    "#c49c94", "#f7b6d2", "#c7c7c7", "#dbdb8d", "#9edae5", ...
                    "#393b79";
                ];
    end
    
    methods
        function obj = DataTableClass(folder,LUTfolder,gaintablefolder)
            %CoupledLineData Construct an instance of this class
            %   Detailed explanation goes here
            obj.folder = folder;
            obj.LUT = LUTClass(LUTfolder);
            obj.LUTfolder = LUTfolder;
            obj.diodeDCIV = obj.loadDCIVtable();
            try
                obj.gaintable = GainTableClass(gaintablefolder);
                obj.gaintablefolder = gaintablefolder;
            catch
            end
            obj = obj.loadfolder(string(folder));
        end

        function DCIVtable = loadDCIVtable(obj)
            temp = readmatrix('C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\DCIV\2024-07-19_1123i_v_gan_onediode.csv');
            Current = temp(:,3);
            Voltage = temp(:,4);
            DCIVtable = table(Voltage,Current);
        end
        
        function obj = add_data(obj,folder)
            if ~ismember(obj.folder,folder)
                obj.folder = [obj.folder; folder];
                obj = obj.loadfolder(string(folder)); 
            end
        end

        function obj = loadfolder(obj, folder)
            %loadfolder Summary of this method goes here
            %   Detailed explanation goes here
            Files = dir(fullfile(folder,"*.json"));
            startPat = '_' + wildcardPattern + '_' + wildcardPattern + '_';
            endPat = 'GHz';
            for k = 1 : length(Files)
                try
                    obj.freq_list(k) = str2double(extractBetween(Files(k).name,startPat,endPat)) ;
                    if iscell(folder)
                        obj = obj.loaddata(strcat(folder(1), '/', Files(k).name), obj.freq_list(k));
                    else
                        obj = obj.loaddata(strcat(folder, '/', Files(k).name), obj.freq_list(k));
                    end
                catch
                end
            end
            % obj = obj.resortpower();
        end
        
        function obj = loaddata(obj,filename, frequency)
            %loaddata Summary of this method goes here
            %   Detailed explanation goes here
            json_txt = obj.loadjson(filename);
            fn = fieldnames(json_txt);
            
            for lp_idx=1:size(fn,1)
                disp(fn{lp_idx})
                if fn{lp_idx} == "Comments"
                    obj.comments = [obj.comments, {json_txt.(fn{lp_idx})}];
                elseif fn{lp_idx} == "DateAndTime"
                    obj.dateandtime = [obj.dateandtime, {json_txt.(fn{lp_idx})}];
                elseif fn{lp_idx} == "Configuration"
                    obj.config = [obj.config, {json_txt.(fn{lp_idx})}];
                    [folder2, ~, ~] = fileparts(json_txt.(fn{lp_idx}).Files.OutputCoupling_dB_);
                    if string(java.net.InetAddress.getLocalHost().getHostName()) ==     "ECEE-D0M5QR3"
                        obj.cal = CalibrationClass(replace(folder2,'C:/Users/grgo8200/Documents/GitHub','C:/Users/grgo8200/repos'));
                    else
                        obj.cal = CalibrationClass(replace(folder2,'C:/Users/grgo8200/Documents/GitHub','/Users/gracegomez/Documents/Research Code Python'));
                    end
                else
                    try
                        obj.data = [obj.data; obj.datapointtable(json_txt.(fn{lp_idx}),frequency,obj.get_setpower(fn{lp_idx}))];
                    catch
                    end
                end
            end
        end

        function [samp1, samp2, gamma] = get_singlesweep(obj, frequency, power, bias_bin)
            rf = rowfilter(obj.data);
            T = obj.data((rf.frequency == frequency & rf.SetPower == power & rf.GateV > bias_bin(1) & rf.GateV < bias_bin(2)) ,:);
            gamma_list = unique(round(abs(T.SetGammaMag),2))';
            if isempty(gamma_list)
                gamma = nan; samp1 = nan; samp2 = nan;
            end
            for gamma_idx = 1:size(gamma_list,2)
                rf = rowfilter(T);
                temp = T(rf.SetGammaMag == gamma_list(gamma_idx),:);
                [~, phsidx] = sort(angle(temp.GammaLoad));
                if exist('samp1') & length(phsidx) > size(samp1,1)
                    for idxfull = 1:size(samp1,2)
                        gammatemp(:,idxfull) = [gamma(:,idxfull); ones(length(phsidx) - size(samp1,1),1)*nan]; 
                        samp1temp(:,idxfull) = [samp1(:,idxfull); ones(length(phsidx) - size(samp1,1),1)*nan]; 
                        samp2temp(:,idxfull) = [samp2(:,idxfull); ones(length(phsidx) - size(samp1,1),1)*nan]; 
                    end
                    samp1 = samp1temp;
                    samp2 = samp2temp;
                    gamma = gammatemp;
                end
                if ~isempty(phsidx)
                    if exist('samp1') & length(phsidx) < size(samp1,1)
                        gamma(:,gamma_idx) = [temp.GammaLoad(phsidx); ones(size(samp1,1)-length(phsidx),1)*nan]; 
                        samp1(:,gamma_idx) = [temp.Sampler1_V(phsidx); ones(size(samp1,1)-length(phsidx),1)*nan]; 
                        samp2(:,gamma_idx) = [temp.Sampler2_V(phsidx); ones(size(samp1,1)-length(phsidx),1)*nan]; 
                    else
                        gamma(:,gamma_idx) = temp.GammaLoad(phsidx)';
                        samp1(:,gamma_idx) = temp.Sampler1_V(phsidx)';
                        samp2(:,gamma_idx) = temp.Sampler2_V(phsidx)';
                    end
                end
            end     
        end

        function obj = samplercoupling(obj)
            [~,bins] = discretize(obj.data.GateV,length(obj.folder));
            obj.power_list = unique(obj.data.SetPower)';
            obj.freq_list = unique(obj.data.frequency)';
            obj.sampler_bias_list = bins;
            for bias = 1:size(bins,2)-1
                rf = rowfilter(obj.data);
                T = obj.data(rf.GateV > bins(bias) & rf.GateV < bins(bias+1) ,:);
                Sampler1_min = min(T.Sampler1_V);
                Sampler2_min = min(T.Sampler2_V);
                Sampler1_max = max(T.Sampler1_V);
                Sampler2_max = max(T.Sampler2_V);
                SamplerV_Mean = mean(T.GateV);
                SamplerI_Mean = mean(T.GateI);
                if ~isempty(Sampler1_min)
                    obj.samplercouplingtable = [obj.samplercouplingtable; table(SamplerI_Mean,...
                            SamplerV_Mean,Sampler2_max,...
                            Sampler1_max, Sampler2_min, ...
                            Sampler1_min)];
            
                end
            end
        end

        function obj = samplercouplingfreq(obj)
            [~,bins] = discretize(obj.data.GateV,length(obj.folder));
            obj.power_list = unique(obj.data.SetPower)';
            obj.freq_list = unique(obj.data.frequency)';
            obj.sampler_bias_list = bins;
            for bias = 1:size(bins,2)-1
                for frequency = unique(obj.data.frequency)'
                    rf = rowfilter(obj.data);
                    T = obj.data((rf.frequency == frequency & rf.GateV > bins(bias) & rf.GateV < bins(bias+1)) ,:);
                    Sampler1_min = min(T.Sampler1_V);
                    Sampler2_min = min(T.Sampler2_V);
                    Sampler1_max = max(T.Sampler1_V);
                    Sampler2_max = max(T.Sampler2_V);
                    SamplerV_Mean = mean(T.GateV);
                    SamplerI_Mean = mean(T.GateI);
                    Sampler1_Range = max(T.Sampler1_V)-min(T.Sampler1_V);
                    Sampler2_Range = max(T.Sampler2_V)-min(T.Sampler2_V);
                        
                    if ~isempty(Sampler1_min)
                        obj.samplercouplingfreqtable = [obj.samplercouplingfreqtable; table(SamplerI_Mean,...
                                SamplerV_Mean,Sampler2_max,...
                                Sampler1_max, Sampler2_min, ...
                                Sampler1_min, frequency, ...
                                Sampler1_Range, Sampler2_Range)];
                    end
                end
            end
        end

        function obj = freqpowerbias(obj)
            [~,bins] = discretize(obj.data.GateV,length(unique(round(obj.data.GateV,2))));
            nonNanIdx = ~isnan(obj.data.SetPower);
            nonNanElements = obj.data.SetPower(nonNanIdx);
            obj.power_list = unique(nonNanElements)';
            nonNanIdx = ~isnan(obj.data.frequency);
            nonNanElements = obj.data.frequency(nonNanIdx);
            obj.freq_list = unique(nonNanElements)';
            obj.sampler_bias_list = bins;
            for frequency = obj.freq_list
                for SetPower = obj.power_list
                    for bias = 1:size(bins,2)-1
                        rf = rowfilter(obj.data);
                        T = obj.data((rf.frequency == frequency & rf.SetPower == SetPower & rf.GateV > bins(bias) & rf.GateV < bins(bias+1)) ,:);
                        Sampler1_Range = max(T.Sampler1_V)-min(T.Sampler1_V);
                        Sampler2_Range = max(T.Sampler2_V)-min(T.Sampler2_V);
                        if isempty(Sampler1_Range); Sampler1_Range = nan; end
                        if isempty(Sampler2_Range); Sampler2_Range = nan; end
                        SamplerV_Mean = mean(T.GateV);
                        DUT_input_dBm_Mean = mean(T.DUT_input_dBm);
                        DUT_output_dBm_Mean = mean(T.DUT_output_dBm);
                        if ~isnan(Sampler2_Range)
                            [ScaleFactorOffset,...
                            ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                            RMSError, GoodnessOfFit, Sampler1_phase, Sampler2_phase, GoodnessOfFitPhase] = ...
                            obj.samplerfitting(T.GammaLoad,T.Sampler1_V,T.Sampler2_V); 
                            obj.freqpowerbiastable = [obj.freqpowerbiastable; table(ScaleFactorOffset,...
                                    ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                                    RMSError, GoodnessOfFit, Sampler1_phase, Sampler2_phase, GoodnessOfFitPhase, ...
                                    Sampler1_Range,Sampler2_Range,SamplerV_Mean,DUT_output_dBm_Mean,DUT_input_dBm_Mean,SetPower,frequency)];
                        end
                    end
                end
            end
        end

        function obj = freqpowerbias_bL2dependent(obj)
            [~,bins] = discretize(obj.data.GateV,length(unique(round(obj.data.GateV,2))));
            nonNanIdx = ~isnan(obj.data.SetPower);
            nonNanElements = obj.data.SetPower(nonNanIdx);
            obj.power_list = unique(nonNanElements)';
            nonNanIdx = ~isnan(obj.data.frequency);
            nonNanElements = obj.data.frequency(nonNanIdx);
            obj.freq_list = unique(nonNanElements)';
            obj.sampler_bias_list = bins;
            for frequency = obj.freq_list
                for SetPower = obj.power_list
                    for bias = 1:size(bins,2)-1
                        rf = rowfilter(obj.data);
                        T = obj.data((rf.frequency == frequency & rf.SetPower == SetPower & rf.GateV > bins(bias) & rf.GateV < bins(bias+1)) ,:);
                        Sampler1_Range = max(T.Sampler1_V)-min(T.Sampler1_V);
                        Sampler2_Range = max(T.Sampler2_V)-min(T.Sampler2_V);
                        if isempty(Sampler1_Range); Sampler1_Range = nan; end
                        if isempty(Sampler2_Range); Sampler2_Range = nan; end
                        SamplerV_Mean = mean(T.GateV);
                        DUT_input_dBm_Mean = mean(T.DUT_input_dBm);
                        DUT_output_dBm_Mean = mean(T.DUT_output_dBm);
                        if ~isnan(Sampler2_Range)
                            [bL2,ScaleFactorKappa1,ScaleFactorKappa2,...
                            ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                            RMSError, MaxError, GoodnessOfFit] = ...
                            obj.samplerfittingpower(T.GammaLoad,T.Sampler1_V,T.Sampler2_V,max(T.DUT_output_dBm)); 
                            obj.freqpowerbiasbL2table = [obj.freqpowerbiasbL2table; table(bL2,ScaleFactorKappa1,ScaleFactorKappa2,...
                                    ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                                    RMSError, MaxError, GoodnessOfFit, ...
                                    Sampler1_Range,Sampler2_Range,SamplerV_Mean,DUT_output_dBm_Mean,DUT_input_dBm_Mean,SetPower,frequency)];
                        end
                    end
                end
            end
            obj.freqpowerbiasbL2table = sortrows(obj.freqpowerbiasbL2table,'SetPower');
            obj.freqpowerbiasbL2table = sortrows(obj.freqpowerbiasbL2table,'SamplerV_Mean');
        end

        function fpb_row = get_freqpowerbiasrow(obj, frequency, power, bias_bin)
            rf = rowfilter(obj.freqpowerbiastable);
            fpb_row = obj.freqpowerbiastable((rf.frequency == frequency & rf.SetPower == power & rf.SamplerV_Mean > bias_bin(1) & rf.SamplerV_Mean < bias_bin(2)) ,:);
        end

        function fpb_row = get_freqpowerbiasbL2row(obj, frequency, power, bias_bin)
            rf = rowfilter(obj.freqpowerbiasbL2table);
            fpb_row = obj.freqpowerbiasbL2table((rf.frequency == frequency & rf.SetPower == power & rf.SamplerV_Mean > bias_bin(1) & rf.SamplerV_Mean < bias_bin(2)) ,:);
        end

        function obj = freqpowerbias3(obj)
            [~,bins] = discretize(obj.data.GateV,length(obj.folder));
            obj.power_list = unique(obj.data.SetPower)';
            obj.freq_list = unique(obj.data.frequency)';
            obj.sampler_bias_list = bins;
            for frequency = unique(obj.data.frequency)'
                for SetPower = unique(obj.data.SetPower)'
                    for bias = 1:size(bins,2)-1
                        rf = rowfilter(obj.data);
                        T = obj.data((rf.frequency == frequency & rf.SetPower == SetPower & rf.GateV > bins(bias) & rf.GateV < bins(bias+1)) ,:);
                        Sampler1_Range = max(T.Sampler1_V)-min(T.Sampler1_V);
                        Sampler2_Range = max(T.Sampler2_V)-min(T.Sampler2_V);
                        if isempty(Sampler1_Range); Sampler1_Range = nan; end
                        if isempty(Sampler2_Range); Sampler2_Range = nan; end
                        SamplerV_Mean = mean(T.GateV);
                        DUT_input_dBm_Mean = mean(T.DUT_input_dBm);
                        DUT_output_dBm_Mean = mean(T.DUT_output_dBm);
                        if ~isnan(Sampler2_Range)
                            [ScaleFactorOffset,...
                            ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                            RMSError, GoodnessOfFit, Sampler1_phase, Sampler2_phase, GoodnessOfFitPhase] = ...
                            obj.samplerfitting3(T.GammaLoad,T.Sampler1_V,T.Sampler2_V,DUT_output_dBm_Mean); 
                            obj.freqpowerbiastable3 = [obj.freqpowerbiastable3; table(ScaleFactorOffset,...
                                    ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                                    ScaleFactorSampler1_Av2,ScaleFactorSampler2_Av2,...
                                    RMSError, GoodnessOfFit, Sampler1_phase, Sampler2_phase, GoodnessOfFitPhase, ...
                                    Sampler1_Range,Sampler2_Range,SamplerV_Mean,DUT_output_dBm_Mean,DUT_input_dBm_Mean,SetPower,frequency)];
                        end
                    end
                end
            end
        end

        function T = freqpower(obj,biasbin)
            rf = rowfilter(obj.freqpowerbiastable);
            T = obj.freqpowerbiastable((rf.SamplerBiasMeanbin == biasbin),:);
        end

        function json_txt = loadjson(obj, filename)
            [fid, msg] = fopen(filename); 
            raw = fread(fid,inf); 
            str = char(raw'); 
            fclose(fid); 
            json_txt = jsondecode(str);
        end

        function tableoutput = datapointtable(obj,json_txt, frequency,SetPower)
            try
                if isfield(json_txt,'Samplers')
                    if isfield(json_txt.Samplers,'x1'); Sampler1_V = json_txt.Samplers.x1; else; Sampler1_V = nan; end;
                    if isfield(json_txt.Samplers,'x2'); Sampler2_V = json_txt.Samplers.x2; else; Sampler2_V = nan; end;
                    if isfield(json_txt.Samplers,'Bias'); SamplerV = json_txt.Samplers.Bias; else; SamplerV = nan; end;
                    if isfield(json_txt.Samplers,'BiasCurrent'); SamplerI = json_txt.Samplers.BiasCurrent; else; SamplerI = nan; end;
                else
                    Sampler1_V = nan; Sampler2_V = nan; SamplerV = nan;SamplerI = nan; 
                end
                
                if isfield(json_txt,'DCParameters')
                    if isfield(json_txt.DCParameters,'gateCurrent'); GateI = json_txt.DCParameters.gateCurrent; else; GateI = nan; end;
                    if isfield(json_txt.DCParameters,'gateVoltage'); GateV = json_txt.DCParameters.gateVoltage; else; GateV = nan; end;
                    if isfield(json_txt.DCParameters,'drainCurrent'); DrainI = json_txt.DCParameters.drainCurrent; else; DrainI = nan; end;
                    if isfield(json_txt.DCParameters,'drainVoltage'); DrainV = json_txt.DCParameters.drainVoltage; else; DrainV = nan; end;
                else
                    GateI = nan; GateV = nan; DrainI = nan;DrainV = nan; 
                end

                if isfield(json_txt,'InputPower'); PNAPower = json_txt.InputPower; else; PNAPower = nan; end;
                if isfield(json_txt,'PowerMeter'); PowerMeter = json_txt.PowerMeter; else; PowerMeter = nan; end;

                if isfield(json_txt,'waveData')
                    %b2
                    if isfield(json_txt.waveData,'output_bwave')
                        OutputbWave_dBm = json_txt.waveData.output_bwave.dBm_mag;
                        OutputbWave_complex =  json_txt.waveData.output_bwave.y_real+j*json_txt.waveData.output_bwave.y_imag;
                    else
                        OutputbWave_dBm = nan;
                        OutputbWave_complex =  nan;
                    end
                    %a2
                    if isfield(json_txt.waveData,'output_awave')
                        OutputaWave_dBm = json_txt.waveData.output_awave.dBm_mag;
                        OutputaWave_complex =  json_txt.waveData.output_awave.y_real+j*json_txt.waveData.output_awave.y_imag;
                    else
                        OutputaWave_dBm = nan;
                        OutputaWave_complex =  nan;
                    end
                    %b1
                    if isfield(json_txt.waveData,'input_bwave')
                        InputbWave_dBm = json_txt.waveData.input_bwave.dBm_mag;
                        InputbWave_complex =  json_txt.waveData.input_bwave.y_real+j*json_txt.waveData.input_bwave.y_imag;
                    else
                        InputbWave_dBm = nan;
                        InputbWave_complex =  nan;
                    end
                    %a1
                    if isfield(json_txt.waveData,'input_awave')
                        InputaWave_dBm = json_txt.waveData.input_awave.dBm_mag;
                        InputaWave_complex =  json_txt.waveData.input_awave.y_real+j*json_txt.waveData.input_awave.y_imag;
                    else
                        InputaWave_dBm = nan;
                        InputaWave_complex =  nan;
                    end
                else
                    OutputbWave_dBm = nan; OutputbWave_complex = nan; OutputaWave_dBm = nan; OutputaWave_complex = nan;
                    InputbWave_dBm = nan; InputbWave_complex = nan; InputaWave_dBm = nan;InputaWave_complex = nan ;
                end

                if isfield(json_txt,'load_gamma')
                    SetGammaLoad =  json_txt.load_gamma.real+j*json_txt.load_gamma.imag;
                    GammaLoad = obj.LUT.tuner2s11(SetGammaLoad,frequency);
                    SetGammaMag = round(abs(SetGammaLoad),2);
                    SetGammaPhs = angle(SetGammaLoad);
                else
                    SetGammaLoad = nan;
                    GammaLoad = nan;
                end

                if any(InputaWave_dBm) && any(OutputbWave_dBm)
                    [DUT_input_dBm,DUT_output_dBm] = obj.cal.power_correction(InputaWave_dBm, OutputbWave_dBm,frequency);
                else
                    DUT_input_dBm  = nan; DUT_output_dBm = nan;
                end

                if isfield(json_txt,'PAPerformance')
                    if isfield(json_txt.PAPerformance,'PAE'); PAE = json_txt.PAPerformance.PAE; else; PAE = nan; end;
                    if isfield(json_txt.PAPerformance,'Gain'); Gain = json_txt.PAPerformance.Gain; else; Gain = nan; end;
                    if isfield(json_txt.PAPerformance,'DCPower'); DCPower = json_txt.PAPerformance.DCPower; else; DCPower = nan; end;
                else
                    PAE = nan; Gain = nan; DCPower = nan;
                end

                tableoutput = table(frequency,Sampler1_V,Sampler2_V,SamplerI,SamplerV,...
                    GateI,GateV,DrainI,DrainV,...
                    SetPower,PNAPower,PowerMeter,...
                    OutputbWave_dBm,OutputbWave_complex,...
                    OutputaWave_dBm,OutputaWave_complex,...
                    InputbWave_dBm,InputbWave_complex,...
                    InputaWave_dBm,InputaWave_complex,...
                    SetGammaLoad,GammaLoad,SetGammaMag,SetGammaPhs,...
                    PAE,Gain,DCPower,...
                    DUT_input_dBm,DUT_output_dBm);
            catch
            end
        end

        function [ScaleFactorOffset,...
                ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                RMSError, GoodnessOfFit, Sampler1_phase, Sampler2_phase, GoodnessOfFitPhase]  = samplerfitting(obj,x,v1,v2)

            fun1 = @(variable) abs(x*exp(j*variable(1))).^2 ...
                - (variable(2)*v1+variable(3)*v2+variable(4));
            ub = [pi,300,300,40];
            lb = [-pi,0,0,-400];
            x1 = [0,30,30,-2];
            opts = optimoptions('lsqnonlin','MaxFunctionEvaluations',1e4, ...
                'FunctionTolerance',1.000000e-12,...
                'OptimalityTolerance', 1.000000e-12, ...
                'StepTolerance', 1.000000e-12);
            [ScaleFactor, GoodnessOfFit] = lsqnonlin(fun1,x1,lb,ub,opts);

            fun1 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                (ScaleFactor(2)*2*v1+variable(2));
            fun2 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                (ScaleFactor(3)*2*v2+variable(2));
            ub = [pi,40];
            lb = [-pi,-400];
            x1 = [pi/2,min(min(v1))*ScaleFactor(1)];
            [vars1, res1] = lsqnonlin(fun1,x1,lb,ub);
            [vars2, res2] = lsqnonlin(fun2,x1,lb,ub);
            Sampler1_phase = vars1(1);
            Sampler2_phase = vars2(1);
            GoodnessOfFitPhase = res1+res2;

            ScaleFactorOffset = ScaleFactor(4);
            ScaleFactorSampler1_Av = ScaleFactor(2);
            ScaleFactorSampler2_Av = ScaleFactor(3);
            RMSError = rmse(abs(x),sqrt(ScaleFactor(2)*v1+ScaleFactor(3)*v2 +...
                 ScaleFactor(4)))
        end

        function [bL2, ScaleFactorKappa1,ScaleFactorKappa2,...
                ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,...
                RMSError, MaxError, GoodnessOfFit]  = samplerfittingpower(obj,x,v1,v2,power)

            bL2 = 10^((power-30)/10);
            fun1 = @(variable) abs(x*exp(j*variable(1))).^2 ...
                - (   1/(2*bL2*variable(2))*(v1-variable(4))+...
                1/(2*bL2*variable(3))*(v2-variable(5)) - 1);
            ub = [pi,5,5,2,2];
            lb = [-pi,0,0,0,0];
            x1 = [0,.5,.5,.1,.1];
            opts = optimoptions('lsqnonlin','MaxFunctionEvaluations',1e4, ...
                'FunctionTolerance',1.000000e-20,...
                'OptimalityTolerance', 1.000000e-12, ...
                'StepTolerance', 1.000000e-12);
            [ScaleFactor, GoodnessOfFit] = lsqnonlin(fun1,x1,lb,ub,opts);

            ScaleFactorSampler1_Av = ScaleFactor(2);
            ScaleFactorSampler2_Av = ScaleFactor(3);
            ScaleFactorKappa1 = ScaleFactor(4);
            ScaleFactorKappa2 = ScaleFactor(5);

            RMSError = rmse(abs(x),sqrt( 1/(2*bL2*ScaleFactorSampler1_Av)*(v1-ScaleFactorKappa1)+...
                1/(2*bL2*ScaleFactorSampler2_Av)*(v2-ScaleFactorKappa2) - 1));
            MaxError = max(max(abs(x)-abs(sqrt( 1/(2*bL2*ScaleFactorSampler1_Av)*(v1-ScaleFactorKappa1)+...
                1/(2*bL2*ScaleFactorSampler2_Av)*(v2-ScaleFactorKappa2) - 1))))
        end

        function [ScaleFactorOffset,...
                ScaleFactorSampler1_Av,ScaleFactorSampler2_Av, ...
                ScaleFactorSampler1_Av2,ScaleFactorSampler2_Av2,...
                RMSError, GoodnessOfFit, Sampler1_phase, Sampler2_phase, GoodnessOfFitPhase]  = samplerfitting3(obj,x,v1,v2)

            fun1 = @(variable) abs(x*exp(j*variable(1))).^2 ...
                - (variable(2)*v1+variable(3)*v2+ ...
                (variable(2)*v1)^2+(variable(3)*v2)^2+variable(4));
            ub = [pi,300,300,300,300,40];
            lb = [-pi,0,0,-100,-100,-400];
            x1 = [0,30,30,-1,-1,-2];
            opts = optimoptions('lsqnonlin','MaxFunctionEvaluations',1e4);
            [ScaleFactor, GoodnessOfFit] = lsqnonlin(fun1,x1,lb,ub,opts);

            fun1 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                (ScaleFactor(2)*2*v1+(ScaleFactor(4)*v1)^2+variable(2));
            fun2 = @(variable) abs(x*exp(-j*variable(1))+exp(j*variable(1))).^2-...
                (ScaleFactor(3)*2*v2+(ScaleFactor(5)*v1)^2+variable(2));
            ub = [pi,40];
            lb = [-pi,-400];
            x1 = [pi/2,min(min(v1))*ScaleFactor(1)];
            [vars1, res1] = lsqnonlin(fun1,x1,lb,ub);
            [vars2, res2] = lsqnonlin(fun2,x1,lb,ub);
            Sampler1_phase = vars1(1);
            Sampler2_phase = vars2(1);
            GoodnessOfFitPhase = res1+res2;

            ScaleFactorOffset = ScaleFactor(4);
            ScaleFactorSampler1_Av = ScaleFactor(2);
            ScaleFactorSampler2_Av = ScaleFactor(3);
            ScaleFactorSampler1_Av2 = ScaleFactor(4);
            ScaleFactorSampler2_Av2 = ScaleFactor(5);
            RMSError = rmse(abs(x),sqrt(ScaleFactor(2)*v1+ScaleFactor(3)*v2 +...
                (ScaleFactor(4)*v1)^2+(ScaleFactor(5)*v2)^2+...
                 ScaleFactor(6)))
        end
        
        function freqpowerbias_loadplot(obj,freq,pow,bias)
            


            ScaleFactorOffset = ScaleFactor(4);
            ScaleFactorSampler1_Av = ScaleFactor(2);
            ScaleFactorSampler2_Av = ScaleFactor(3);
            RMSError = rmse(abs(x),sqrt(ScaleFactor(2)*v1+ScaleFactor(3)*v2 +...
                 ScaleFactor(4)));
        end

        function setpower = get_setpower(obj,fname)
            try
                startPat = 'LoadPoint_';
                endPat = '_0';
                setpower = str2double(replace(extractBetween(fname,startPat,endPat),'_','.'));
            catch
                startPat = 'PNAPower_';
                endPat = '_0';
                setpower = str2double(replace(extractBetween(fname,startPat,endPat),'_','.'));
            end
        end
    
        function T = Avaveragefreq(obj,power,bias_bin)
            rf = rowfilter(obj.freqpowerbiastable);
            pb_row = obj.freqpowerbiastable(rf.SetPower == power & rf.SamplerV_Mean > bias_bin(1) & rf.SamplerV_Mean < bias_bin(2) ,:);
            ScaleFactorSampler1_Av = mean(pb_row.ScaleFactorSampler1_Av); 
            ScaleFactorSampler2_Av = mean(pb_row.ScaleFactorSampler2_Av); 
            ScaleFactorOffset = mean(pb_row.ScaleFactorOffset); 
            SamplerV_Mean = mean(pb_row.SamplerV_Mean);
            T = table(ScaleFactorSampler1_Av,ScaleFactorSampler2_Av,ScaleFactorOffset,SamplerV_Mean);
        end
    end
end

