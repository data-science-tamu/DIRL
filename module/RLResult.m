classdef RLResult <AbsResultStorage
    %RLRESULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = RLResult(inputArg1,inputArg2)
            %RLRESULT Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = print_str(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = sprintf('\tTest Rewards:%.2f', mean(results(idx_repeat, idx_method, :);
        end
    end
end

