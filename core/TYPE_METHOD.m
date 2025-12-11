classdef TYPE_METHOD
    %TYPE_METHOD Summary of this class goes here
    %   Detailed explanation goes here
    enumeration
        SAC_GRP
        SAC_GRP_LOOKAHEAD
        SAC_NOGRP
        SAC_NOGRP_LOOKAHEAD
        QLEARNING
        SALSA
        DDPG
        DQN
        DDQN
        PERIODICAL
        THRESHOLD
        THRESHOLD_2TH
        TRPO_CACT_CSTA
        TRPO_DACT_CSTA
        TRPO_CACT_DSTA
        TRPO_DACT_DSTA
        TRPO_CACT_CSTA_SAC_ACTOR
        TRPO_GRP_CACT_CSTA
        PPO_CACT
        PPO_DACT
        AC_CACT
        AC_DACT
        PG_CACT
        PG_DACT
        TD3
        MBPO_DQN
        MBPO_DDPG
        MBPO_TD3
        MBPO_SAC
        PPO_CACT_SAC_ACTOR
        AC_CACT_SAC_ACTOR
        DO_NOTHING
        MAINTAIN_EVERYTIME
    end
    
%     properties
%         Property1
%     end
    
    methods (Static)
%         function obj = TYPE_METHOD(inputArg1,inputArg2)
%             %TYPE_METHOD Construct an instance of this class
%             %   Detailed explanation goes here
%             obj.Property1 = inputArg1 + inputArg2;
%         end
        
%         function out = getAllMethods()
%             out = {
%                 TYPE_METHOD.SAC_GRP, ...
%                 TYPE_METHOD.DQN ,...
%                 TYPE_METHOD.QLEARNING ,...
%                 TYPE_METHOD.SALSA ,...
%                 TYPE_METHOD.THRESHOLD ,...
%                 TYPE_METHOD.PERIODICAL ,...
%                 TYPE_METHOD.SAC_NOGRP, ...
%                 };
% %             %METHOD1 Summary of this method goes here
% %             %   Detailed explanation goes here
% %             outputArg = obj.Property1 + inputArg;  
%         end
%         
%         function out = getMethod(idx)
%             switch idx
%                 case 1
%                     out = TYPE_METHOD.SAC_GRP;
%                 case 2
%                     out = TYPE_METHOD.DQN;                    
%                 case 3
%                     out = TYPE_METHOD.QLEARNING;
%                 case 4
%                     out = TYPE_METHOD.SALSA;
%                 case 5
%                     out = TYPE_METHOD.THRESHOLD;
%                 case 6
%                     out = TYPE_METHOD.PERIODICAL;
%                 case 7
%                     out = TYPE_METHOD.SAC_NOGRP;
%                 otherwise
%                     disp('NOT ASSIGNED');
%             end
%         end
        
        function out = areStatesContinuous(method)
            switch method
                case TYPE_METHOD.SAC_GRP
                    out = true;
                case TYPE_METHOD.SAC_GRP_LOOKAHEAD
                    out = true;
                case TYPE_METHOD.SAC_NOGRP
                    out = true;
                case TYPE_METHOD.SAC_NOGRP_LOOKAHEAD
                    out = true;
        %             disp(method)
                case TYPE_METHOD.DDPG
                    out = true;
        %             disp(method)
                case TYPE_METHOD.TD3
                    out = true;
                case TYPE_METHOD.DQN
                    out = true;
                case TYPE_METHOD.DDQN
                    out = true;
                case TYPE_METHOD.QLEARNING
                    out = false;
                case TYPE_METHOD.SALSA
                    out = false;
                case TYPE_METHOD.PERIODICAL
                    out = true;
                case TYPE_METHOD.THRESHOLD
                    out = true;
                case TYPE_METHOD.THRESHOLD_2TH
                    out = true;
                case TYPE_METHOD.PPO_CACT
                    out = true;
                case TYPE_METHOD.PPO_DACT
                    out = true;
                case TYPE_METHOD.AC_CACT
                    out = true;
                case TYPE_METHOD.AC_DACT
                    out = true;
                case TYPE_METHOD.PG_CACT
                    out = true;
                case TYPE_METHOD.PG_DACT
                    out = true;
                case TYPE_METHOD.TRPO_CACT_DSTA
                    out = false;
                case TYPE_METHOD.TRPO_DACT_DSTA
                    out = false;
                case TYPE_METHOD.TRPO_CACT_CSTA
                    out = true;
                case TYPE_METHOD.TRPO_GRP_CACT_CSTA
                    out = true;
                case TYPE_METHOD.TRPO_DACT_CSTA
                    out = true;
                case TYPE_METHOD.MBPO_DQN
			        out=true;
                case TYPE_METHOD.MBPO_DDPG
			        out=true;
                case TYPE_METHOD.MBPO_TD3
			        out=true;
                case TYPE_METHOD.MBPO_SAC		
			        out=true;
                case TYPE_METHOD.PPO_CACT_SAC_ACTOR
                    out = true;
                case TYPE_METHOD.AC_CACT_SAC_ACTOR
                    out = true;
                case TYPE_METHOD.TRPO_CACT_CSTA_SAC_ACTOR
                    out = true;
                case TYPE_METHOD.DO_NOTHING
                    out = true;
                case TYPE_METHOD.MAINTAIN_EVERYTIME
                    out = true;
                otherwise
                    fprintf('[WARNING] Unsupported method:%s\n',method)
        %             
            end            
        end
                
        function out = hasContinuousActionSpace(method)
            switch method
                case TYPE_METHOD.SAC_GRP
                    out = true;
                case TYPE_METHOD.SAC_NOGRP
                    out = true;
        %             disp(method)
                case TYPE_METHOD.SAC_GRP_LOOKAHEAD
                    out = true;
                case TYPE_METHOD.SAC_NOGRP_LOOKAHEAD
                    out = true;
                case TYPE_METHOD.DDPG
                    out = true;
        %             disp(method)
                case TYPE_METHOD.TD3
                    out = true;
                case TYPE_METHOD.DQN
                    out = false;
                case TYPE_METHOD.DDQN
                    out = false;
                case TYPE_METHOD.QLEARNING
                    out = false;
                case TYPE_METHOD.SALSA
                    out = false;
                case TYPE_METHOD.PERIODICAL
                    out = true;
                case TYPE_METHOD.THRESHOLD
                    out = true;
                case TYPE_METHOD.THRESHOLD_2TH
                    out = true;
                case TYPE_METHOD.PPO_CACT
                    out = true;
                case TYPE_METHOD.PPO_DACT
                    out = false;
                case TYPE_METHOD.AC_CACT
                    out = true;
                case TYPE_METHOD.AC_DACT
                    out = false;
                case TYPE_METHOD.PG_CACT
                    out = true;
                case TYPE_METHOD.PG_DACT
                    out = false;
                case TYPE_METHOD.TRPO_CACT_DSTA
                    out = true;
                case TYPE_METHOD.TRPO_DACT_DSTA
                    out = false;
                case TYPE_METHOD.TRPO_CACT_CSTA
                    out = true;
                case TYPE_METHOD.TRPO_GRP_CACT_CSTA
                    out = true;
                case TYPE_METHOD.TRPO_DACT_CSTA
                    out = false;
                case TYPE_METHOD.MBPO_DQN
			        out=false;
                case TYPE_METHOD.MBPO_DDPG
			        out=true;
                case TYPE_METHOD.MBPO_TD3
			        out=true;
                case TYPE_METHOD.MBPO_SAC		
			        out=true;			                    
                case TYPE_METHOD.AC_CACT_SAC_ACTOR
                    out = true;
                case TYPE_METHOD.PPO_CACT_SAC_ACTOR
                    out = true;
                case TYPE_METHOD.TRPO_CACT_CSTA_SAC_ACTOR
                    out = true;
                case TYPE_METHOD.DO_NOTHING
                    out = true;
                case TYPE_METHOD.MAINTAIN_EVERYTIME
                    out = true;
                otherwise
                    fprintf('[WARNING] Unsupported method:%s\n',method)
        %             
            end            
        end
        
        %         function out=method()
%             switch method
%                 case TYPE_METHOD.SAC_GRP
%         %             disp(method)
%                 case TYPE_METHOD.DDPG
%         %             disp(method)
%                 case TYPE_METHOD.DQN
%                 case TYPE_METHOD.QLEARNING
%                 case TYPE_METHOD.SALSA
%                 case TYPE_METHOD.PERIODICAL
%                 case TYPE_METHOD.THRESHOLD
%                 otherwise
%                     fprintf('[WARNING] Unsupported method:%s\n',method)
%         %             
%             end            
%         end
%         
%         function out = nMethods()
%             out = 6;
%         end
    end
end

