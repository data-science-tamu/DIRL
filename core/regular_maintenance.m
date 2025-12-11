function [reward, opt_interval] = regular_maintenance(param, env, unit, nRepeat, verbose, max_interval)
%     fprintf('Replace Regularly (setting:%s)\n',setting)
%     param = drl_params(time_budget, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, cost_w, lost_demand, demand, inspection_cost, verbose);
    % env = Maintenance_real_reward_no_workload_assignment(param, unit, th, cap_w); %fprintf('Maintenance_real_reward_no_workload_assignment\n');

    if nargin>5
        n_interval = max_interval;
    else
        n_interval=20;
    end
%     min_interval = 1;
    min_interval = 10;

    %Modify the max and min interval---------------------------------------
    th = env.threshold;
    mean_degrad = env.mean_beta ;
    expected_step_before_fail = th/mean_degrad;
    max_interval = round(2.0*expected_step_before_fail);
    min_interval = round(0.5*expected_step_before_fail);
    n_interval = (max_interval-min_interval);
    fprintf('n interval= %d \n', n_interval);
    %END HERE -------------------------------------------------------------

    verbose = true;
    num_fig = 98;
    str_title = '';

    nRepeat_test = 100;
        
    out_rewards = zeros(n_interval, nRepeat_test);
    xs = zeros(n_interval, 1);
    ys = zeros(n_interval, 1);
%     fprintf('|----------|\n|');
    for idx_interval=1:n_interval;
    %     if(verbose);fprintf('interval = %d\n',i);end
    %     if(verbose);
%             if(i>2&& floor((i-1)/n_interval*10)~=floor((i)/n_interval*10)); fprintf('.');end;
    %     end;
        interval = min_interval + idx_interval - 1;
        xs(idx_interval) = interval;
    %     if i>1;verbose=true;else;verbose=false;end
        out_rewards(idx_interval,:) = interval_Repair(env, unit, interval, nRepeat_test, verbose);
        ys(idx_interval) = mean(out_rewards(idx_interval,:));
        if (verbose)
            if(mod(idx_interval, floor((n_interval)/100))==0)
                fprintf('.');
            end
            if(mod(idx_interval, floor((n_interval)/10))==0)
                fprintf('|%d|',floor(idx_interval./floor((n_interval)/10)));
                if(idx_interval == floor((n_interval)/2))
                    fprintf('\n')
                end
            end
        end
    end
%     fprintf('\n');
%     if(verbose)
% %         fprintf('\n');
%         figure(num_fig);clf;
%         plot(xs,ys);
%         title('Interval vs Rewards');
%         xlabel('interval');
%         ylabel('rewards');
%     end

    [val,idx]=max(ys);

    if(idx==numel(xs))
        fprintf('This might not be optimal: Increase the maximum interval\n')
    end
    if(idx==min_interval)
        fprintf('This might not be optimal: Decrease the minimum interval\n')
    end
    opt_interval = xs(idx);
    out = interval_Repair(env, unit, opt_interval, nRepeat, verbose);


    fprintf('> Optimal Reward =%.2f, interval = %d\n', val, xs(idx));
    reward = out;
end

% function outs= interval_Repair(env, unit, interval, nRepeat, verbose)
%     results = zeros(1,nRepeat);
%     actInfo = getActionInfo(env);
% 
%     for repeat = 1:nRepeat
% %         action=[zeros(1, unit), 0];
%         action = zeros(actInfo.Dimension);
%         
%         if(numel(action)>2*unit)
%         % For workload
%             action(unit+2:end) = 1;
%         end
%         env.reset();
%         time = 1;
%         for iter = 1:1000000
%             
%             if(time>=interval)
%                 action(1:unit+1) = 1;
%                 time = 0;
%             else
%                 action(1:unit+1) = 0;
%             end
% %             if(verbose)
% %                 fprintf('[Repair:%d]',action(unit+1));
% %                 fprintf('%d ',action(1:unit));
% %                 fprintf('|');
% %                 fprintf('%d ',action(unit+2:end));
% %                 fprintf('|| ');
% % %                 fprintf('\n');
% %             end
%             [observation, reward, isDone, loggedSignals] = env.step(action);
% %             fprintf('Reward (t=%d): %d\n',time,reward);
%             time = time + 1;
% %             if(verbose);fprintf('r: %d\n',reward);end;
% %             if(verbose);
% %                 fprintf('Obs:');
% %                 fprintf(' %.2f',observation);
% %                 fprintf(' | Reward=%.2f\n',reward);
% %             end;
%             if(isDone)
% %                 results(repeat) = env.totalrewards;
%                 results(repeat) = env.total_reward_actual;
%                 if(verbose);fprintf('R: %d\n',env.total_reward_actual);end;
%                 break;
%             end
%         end
%         results(repeat) = env.total_reward_actual;
%     end
%     % figure(1);clf;plot(results);
%     outs = (results);
% end
