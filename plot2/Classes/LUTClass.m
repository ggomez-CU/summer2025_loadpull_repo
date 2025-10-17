classdef LUTClass
    %LUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        freq
        LUT
        thru

        waves
    end
    
    methods
        function obj = LUTClass(folder)
            Files = dir(fullfile(folder,"*.mat"));
            startPat = '_';
            endPat = '_GHz';
            if string(java.net.InetAddress.getLocalHost().getHostName()) ==     "ECEE-D0M5QR3"
                obj.thru = load('/Users/grgo8200/repos/summer2025_loadpull_repo/data/deembedsparam0710/DUTthru.mat').DUTthru;
            else
                obj.thru = load('/Users/grgo8200/Documents/Github/summer2025_loadpull_repo/data/deembedsparam0710/DUTthru.mat').DUTthru;
             end
            % obj.thru = load('/Users/gracegomez/Documents/Research Code Python/summer2025_loadpull_repo/data/deembedsparam0710/DUTthru.mat').DUTthru;
            for k = 1 : length(Files)
                try
                    freq(k) = str2double(extractBetween(Files(k).name,startPat,endPat)) ;
                catch
                end
            end

            [obj.freq, idx] = sort(freq);

            for idx = 1 : length(Files)
                try
                    obj = obj.freq2table(idx,strcat(folder, '/', Files(idx).name));
                catch
                end
            end
        end
        
        function obj = freq2table(obj,k,file)
            LUTtemp = load(file).LUT;
            obj.waves(:,:,k) = load(file).waves;
            obj.LUT(:,:,k) = LUTtemp ;
        end

        function s11 = tuner2s11(obj, tunerload, freq)
            idx = find(obj.freq()==freq);
            LUTfreq = obj.LUT(:,:,idx);
            try
                idxa = find(LUTfreq(:,1)==tunerload);
                s11 = abs(obj.LUT(idxa,2,idx)).*exp(j*(angle(obj.LUT(idxa,2,idx))+angle(obj.thru(idx))*2));
            catch
                disp('No tuner value')
                s11 = [];
            end

            if abs(tunerload) > max(abs(obj.LUT(idxa,1,:)))
                tunerload = 0.8*exp(j*angle(tunerload));
                idxa = find(abs(LUTfreq(:,1)-tunerload)<0.001);
                s11 = abs(obj.LUT(idxa,2,idx)).*exp(j*(angle(obj.LUT(idxa,2,idx))+angle(obj.thru(idx))*2));
            end
        end

        function generate_report(obj, filename)
            import mlreportgen.ppt.*
            ppt = Presentation(strcat(filename,'.pptx'));

            titleSlide = add(ppt,'Title Slide');
            replace(titleSlide,'Title','Load Termination Report');

            for i = 1:size(obj.freq,2)
                obj.deltas11(i)
                largesignalSlide = add(ppt,'Title and Picture');
                plot1 = Picture(strcat('png/LUT',num2str(i),'.png'));
                replace(largesignalSlide,'Title',strcat('Load termination plot at', num2str(obj.freq(i)),'GHz'));
                replace(largesignalSlide,'Picture',plot1);
            end

            close(ppt);
            rptview(ppt);
        end
        function deltas11(obj,i)
            figure()
            init = polar(0,0)
            hold on
            scatter(real(obj.LUT(:,1,i)),imag(obj.LUT(:,1,i)),"filled");
            scatter(real(obj.LUT(:,2,i)),imag(obj.LUT(:,2,i)),"filled");
            s11correctedtemp = abs(obj.LUT(:,2,i)).*exp(j*(angle(obj.LUT(:,2,i))+angle(obj.thru(i))*2))
            % s11correctedtemp = obj.LUT(:,2,i) +exp(-j*angle(obj.thru(i)));
            scatter(real(s11correctedtemp),imag(s11correctedtemp),"filled");
            delete(init)
            legend('User Load','Measured Load','Corrected Load')
            saveas(gcf,strcat('png/LUT',num2str(i),'.png'));
            close all
        end
    end
end

