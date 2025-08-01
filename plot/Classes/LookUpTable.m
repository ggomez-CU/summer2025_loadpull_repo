classdef LookUpTable
    %LOOKUPTABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        freq
        meas_gamma
        set_gamma
    end
    
    methods
        function obj = LookUpTable(filename, folder=[])
            if isfile(filename)
                obj = LookUpTable_read(filename);
            else
                obj = LookUpTable_generate(filename,folder);
            end
        end
        
        function obj =  LookUpTable_generate(filename,folder)

        end

        function obj =  LookUpTable_read(filename)

        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

