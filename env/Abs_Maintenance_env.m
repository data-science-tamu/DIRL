classdef Abs_Maintenance_env< matlab.mixin.Copyable
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        num_training
        num_test 
        cnt_episode 
        all_rewards 
        all_rewards_real 
        training_rewards 
        training_rewards_real 
        test_rewards 
        test_rewards_real 
    end
    
    methods
%         function this = Abs_Maintenance_env(inputArg1,inputArg2)
%             %UNTITLED Construct an instance of this class
%             %   Detailed explanation goes here
%             this.Property1 = inputArg1 + inputArg2;
%         end
%         
%         function outputArg = method1(obj,inputArg)
%             %METHOD1 Summary of this method goes here
%             %   Detailed explanation goes here
%             outputArg = obj.Property1 + inputArg;
%         end
    end
end

