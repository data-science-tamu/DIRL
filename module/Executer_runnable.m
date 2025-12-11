classdef Executer_runnable
    %EXECUTER_RUNNABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
%         function obj = Executer_runnable(inputArg1,inputArg2)
%             %EXECUTER_RUNNABLE Construct an instance of this class
%             %   Detailed explanation goes here
%             obj.Property1 = inputArg1 + inputArg2;
%         end
        
        function result = run(setting, param, runnable, method, logger);
            if(~isa(setting,'AbsSetting'))
                throw(MException('Wrong class','setting is not AbsSetting.') )
            end
            if(~isa(param,'AbsParam'))
                throw(MException('Wrong class','param is not AbsParam.') )
            end
            if(~isa(method,'AbsMethod'))
                throw(MException('Wrong class','method is not AbsMethod.') )
            end
            if(~isa(logger,'Logger'))
                throw(MException('Wrong class','logger is not Logger.') )
            end
            if(~isa(runnable,'AbsRunnable'))
                throw(MException('Wrong class','runnable is not AbsRunnable.') )
            end
            result = runnable(setting, method, logger);
        end
    end
end

