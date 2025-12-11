classdef AgentOptionGenerater
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        discountFactor = .99
        learning_rate
        set_learning_rate = false;
    end
    
    methods 
        function this = AgentOptionGenerater(discountFactor, learning_rate)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            this.discountFactor= discountFactor;
            if(nargin>1)
                this.set_learning_rate = true;
                this.learning_rate = learning_rate;
            else
                this.set_learning_rate = false;
            end
        end
        
    function out = getAgentOption(this, method)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            switch method
                case 'SAC'
                    out = rlSACAgentOptions('DiscountFactor',this.discountFactor);
%                     out.EntropyWeightOptions.OptimizerParameters.GradientDecayFactor = .99;
%                     out.DiscountFactor = 0.99;


%                     %% HERE ARE THE PARAMETERS IN SAC PAPER
%                     this.learning_rate = 3e-4;
                    if(this.set_learning_rate)
                        out.ActorOptimizerOptions.LearnRate = this.learning_rate;
                        out.CriticOptimizerOptions(1).LearnRate = this.learning_rate;
                        out.CriticOptimizerOptions(2).LearnRate = this.learning_rate;
                    end
%                     out.ExperienceBufferLength = 1e6;
%                     out.MiniBatchSize = 256;
%                     out.TargetSmoothFactor = 0.005;
%                     out.TargetUpdateFrequency = 1;
                    
                otherwise
%                     out = rlSACAgentOptions('DiscountFactor',discountFactor)
                    error('ERROR: UNKNOWN Method')
            end
            
        end
    end
end

