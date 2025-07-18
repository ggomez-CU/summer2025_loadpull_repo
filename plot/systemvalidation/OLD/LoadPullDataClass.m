classdef LoadPullDataClass

    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        gammaload
        loadpoint
        s11
        frequency
    end

    methods
        function obj = LoadPullDataClass(dname)
            obj = obj.loadpull_load(dname);
        end
        function obj = loadpull_load(obj, file)
            disp("Loading data")
            fid = fopen(file); 
            raw = fread(fid,inf); 
            str = char(raw'); 
            fclose(fid); 
            temp = jsondecode(str);
            fn = fieldnames(temp);
            obj.frequency = temp.Configuration.Frequency;
            for lp_idx=3:(length(fn))
                temp.(fn{lp_idx})
                disp(lp_idx)
                try
                    obj.loadpoint(:,lp_idx) = temp.(fn{lp_idx}).load_gamma.real+j*temp.(fn{lp_idx}).load_gamma.imag;
                    obj.s11(:,lp_idx) = temp.(fn{lp_idx}).PNAS11.real+j*temp.(fn{lp_idx}).PNAS11.imag;
                    obj.gammaload(:,lp_idx) = temp.(fn{lp_idx}).PNAGammaLoad.real+j*temp.(fn{lp_idx}).PNAGammaLoad.imag;                catch
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