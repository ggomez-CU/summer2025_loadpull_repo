classdef GainTableClass
    %GAINTABLECLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        folder

        diodeDCIV

        gaintable
        lineargaintable
    end
    
    methods
        function obj = GainTableClass(gaintablefolder)
            obj.gaintable = load(strcat(gaintablefolder,'\gaintable.mat')).gaintable;
            obj.lineargaintable = load(strcat(gaintablefolder,'\gaintable.mat')).lineargaintable;
            obj.diodeDCIV = readmatrix('C:\Users\grgo8200\repos\summer2025_loadpull_repo\data\DCIV\2024-07-19_1123i_v_gan_onediode.csv');
        end

        function T = get_gain(obj,setfrequency,setpower,setbias)
            rf = rowfilter(obj.gaintable);
            T = obj.gaintable(rf.frequency == setfrequency & ...
            rf.MeanSamplerBias > setbias(1) & rf.MeanSamplerBias < setbias(2)& rf.SetOutputPower == setpower ,:);
        end

        function T = get_lineargain(obj,setfrequency,setbias)
            rf = rowfilter(obj.lineargaintable);
            T = obj.lineargaintable(rf.frequency == setfrequency & ...
            rf.MeanSamplerBias > setbias(1) & rf.MeanSamplerBias < setbias(2) ,:);
        end
    end
end

