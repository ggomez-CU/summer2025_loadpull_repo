classdef DataPointClass
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        complex_load

        input_awave_dBm
        input_bwave_dBm
        output_awave_dBm
        output_bwave_dBm

        freq
        sampler_bias

        DUT_output_dBm
        DUT_input_dBm

        SetPower

        PAE
        Pdc
        gain
        drain_I
        drain_V
        gate_I
        gate_V

        sampler1_V
        sampler2_V
    end
    
    methods
        function obj = DataPointClass(json_txt)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj.loaddata(json_txt);
        end
        
        function table = loaddata(obj,json_txt)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            fn=fieldnames(json_txt)

        end
    end
end

