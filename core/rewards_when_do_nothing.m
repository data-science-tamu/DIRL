function out = rewards_when_do_nothing(env, nRepeat, show_progress_arg)
    results = zeros(1,nRepeat);
    for repeat = 1:nRepeat
        action=[zeros(env.getActionInfo.Dimension)];
        if(~env.noworkload)
%             action=[zeros(1, 2*unit)];
            action(end-env.unit+1:end) = 1./env.demand;
        end
        env.reset();
        for iter = 1:10000
            [observation, reward, isDone, loggedSignals] = env.step(action);
%             %--------------------------------------------
% %             if(verbose)
%                 fprintf('Obs:');
%                 fprintf(' %.2f',observation);
%                 fprintf('|| ');
%                 
%                 fprintf('[Repair:%d]',action(unit+1));
%                 fprintf('%d ',action(1:unit));
%                 fprintf('|');
%                 fprintf('%d ',action(unit+2:end));
%                 fprintf(' | Reward=%.2f\n',reward);
% %                 fprintf('\n');
% %             end
% %             fprintf('Reward (t=%d): %d\n',env.time,reward);
% %             if(verbose);fprintf('r: %d\n',reward);end;
% %             if(verbose);
% %             end;
% 
%             %--------------------------------------------

            if(isDone)
                results(repeat) = env.total_reward_actual;
                break;
            end
        end
%         env.init_rewards();
    end
    % figure(1);clf;plot(results);
%     out = mean(results);
    out = results;