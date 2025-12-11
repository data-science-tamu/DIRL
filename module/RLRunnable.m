classdef RLRunnable < AbsRunnable
    %RLRUNNABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = RLRunnable(inputArg1,inputArg2)
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function result = run(obj, setting, method, logger)
            
            result = obj.Property1 + inputArg;
        end
    end
end

