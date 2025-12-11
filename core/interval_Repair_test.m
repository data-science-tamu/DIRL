function [outs, obs] = interval_Repair_test(env, unit, interval, nRepeat, verbose)
    results = zeros(1,nRepeat);
    actInfo = getActionInfo(env);
%     env.event_record ={};
    for repeat = 1:nRepeat
%         action=[zeros(1, unit), 0];
        action = zeros(actInfo.Dimension);

%         
%         if(numel(action)>2*unit)
%         % For workload
%             action(unit+2:end) = 1;
% %             action(end-unit:end) = 1./env.demand;
%         end
        if(~env.noworkload)
%             action=[zeros(1, 2*unit)];
            action(end-unit+1:end) = 1./env.demand;
        end
        env.reset();
        time = 1;
        for iter = 1:1000000
            
            if(time>=interval)
                decision_maintenance = 1;
                time = 0;
            else
                decision_maintenance = 0;
%                 action(1:unit+1) = 0;
            end
            if(env.addGroupVar)
                action(1:unit+1) = decision_maintenance;
            else
                action(1:unit) = decision_maintenance;

            end
%             if(verbose)
%                 fprintf('[Repair:%d]',action(unit+1));
%                 fprintf('%d ',action(1:unit));
%                 fprintf('|');
%                 fprintf('%d ',action(unit+2:end));
%                 fprintf('|| ');
% %                 fprintf('\n');
%             end
            [observation, reward, isDone, loggedSignals] = env.step(action);
            if repeat == 1
                obs{iter} = observation;
            end
%             fprintf('Reward (t=%d): %d\n',time,reward);
            time = time + 1;
%             if(verbose);fprintf('r: %d\n',reward);end;
%             if(verbose);
%                 fprintf('Obs:');
%                 fprintf(' %.2f',observation);
%                 fprintf(' | Reward=%.2f\n',reward);
%             end;
            if(isDone)
%                 results(repeat) = env.totalrewards;
                results(repeat) = env.total_reward_actual;
%                 if(verbose);fprintf('R: %d\n',env.total_reward_actual);end;
                break;
            end
        end
        results(repeat) = env.total_reward_actual;
        env.init_rewards();
    end
    % figure(1);clf;plot(results);
    outs = (results);
end