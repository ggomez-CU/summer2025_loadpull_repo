classdef CalibrationClass
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pna2pm_input
        pna2pm_output
        pna2dut_input
        pna2dut_output
        error_directivity
        error_match
        error_tracking
        error_freq
        pna2pm_freq
        pna2dut_freq
    end
    
    methods
        function obj = CalibrationClass(errorfolder,...
                pna2DUT_folder)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.error_match = obj.get_error_mat(strcat(errorfolder,'/ErrorTerm_22_ESrm.csv'));
            obj.error_tracking = obj.get_error_mat(strcat(errorfolder,'/ErrorTerm_22_ERft.csv'));
            obj.error_directivity = obj.get_error_mat(strcat(errorfolder,'/ErrorTerm_22_EDir.csv'));
            obj.error_freq = obj.get_error_freq(strcat(errorfolder,'/ErrorTerm_22_EDir.csv'));
        	obj.pna2pm_input = load(strcat(pna2DUT_folder,'/pna2pm_input.mat')).pna2pm_input;
            obj.pna2pm_output = load(strcat(pna2DUT_folder,'/pna2pm_output.mat')).pna2pm_output;
	        obj.pna2dut_output = load(strcat(pna2DUT_folder,'/pna2dut_output.mat')).pna2dut_output;
            obj.pna2dut_input = load(strcat(pna2DUT_folder,'/pna2dut_input.mat')).pna2dut_input;
        end
        
        function complex_gamma = gamma_calc(obj,output_awave,output_bwave,freq)
            %METHOD1 Summary of this method goes here
            % eq from hackborn. extrapolated equation 
            [directivity, tracking, match] = obj.freq_error(freq);
            complex_gamma = 10^-2*directivity + (tracking*output_awave/output_bwave)/(1-match*output_awave/output_bwave);
        end

        function complex_gamma = gamma_calc_raw(obj,output_awave,output_bwave,freq)
            complex_gamma = output_awave/output_bwave;
        end

        function [directivity, tracking, match] = freq_error(obj,freq)
            idx = find(round(obj.error_freq()/1e9,2)==freq);
            directivity = obj.error_directivity(idx);
            tracking = obj.error_tracking(idx);
            match = obj.error_match(idx);
        end

        function [array] = get_error_mat(obj, file)
		    filedata = readmatrix(file);
		    array = filedata(:,2)+j*filedata(:,3);
        end

    	function array = get_error_freq(obj, file)
		    filedata = readmatrix(file);
		    array = filedata(:,1);
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

