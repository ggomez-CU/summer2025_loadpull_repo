classdef CalibrationClass
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pna2pm_input
        pna2pm_output
        pna2dut_input
        pna2dut_output

        pna2pm_freq
        pna2dut_freq
    end
    
    methods
        function obj = CalibrationClass(pna2DUT_folder)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.pna2pm_input = load(strcat(pna2DUT_folder,'/pna2pm_input.mat')).pna2pm_input;
            obj.pna2pm_output = load(strcat(pna2DUT_folder,'/pna2pm_output.mat')).pna2pm_output;
	        obj.pna2dut_output = load(strcat(pna2DUT_folder,'/pna2dut_output.mat')).pna2dut_output;
            obj.pna2dut_input = load(strcat(pna2DUT_folder,'/pna2dut_input.mat')).pna2dut_input;

            obj.pna2dut_freq = [8:.1:12];
        end

        function [input_power, output_power] = power_correction(obj, input_awave, output_bwave,freq)
            % where waves are specified in dBm
            [input_coupling, output_coupling] = obj.get_power_freq(freq);
            input_power = input_awave + input_coupling;
            output_power = output_bwave + output_coupling;
        end
        
        function [input_coupling, output_coupling] = get_power_freq(obj,freq)
            idx = find(obj.pna2dut_freq()==freq);
            input_coupling = obj.pna2dut_input(idx);
            output_coupling = obj.pna2dut_output(idx);
        end
    end
end

