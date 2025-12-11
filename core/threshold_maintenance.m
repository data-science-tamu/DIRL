function [rewards, opt_th] = threshold_maintenance(param, env, unit, nRepeat, verbose, n_grid)
%     param = drl_params(time_budget, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, var_wl, lost_demand, demand, inspection_cost, verbose);
%     env = Maintenance_real_reward_no_workload_assignment(param, unit, th); %fprintf('Maintenance_real_reward_no_workload_assignment\n');
%         nRepeat = 10;
    if nargin>5
%         n_grid = n_grid;
    else
        n_grid=100;
    end
    num_fig=99; verbose = true;
    

    is_optimal_search = true; %true; %false;
    increments =  0.25;
    n_repeat_for_optimum_search = 10;

    % Extract info
    n_discrete_state = env.num_discretized_states;
    th = env.threshold(1);

    if is_optimal_search
        n_grid = (th/2)/increments ;
        fprintf('n grid with optimal threshold= %d \n', n_grid);
        out_rewards = zeros(n_grid, n_repeat_for_optimum_search);
        xs = zeros(n_grid, 1);
        ys = zeros(n_grid, 1);
        for idx_grid = 1:n_grid
            th_repair = (th/2) + idx_grid*increments;
            xs(idx_grid) = th_repair ;
            out_rewards(idx_grid,:) = th_Repair(env, unit, th_repair, n_repeat_for_optimum_search, false);
            ys(idx_grid) = mean(out_rewards(idx_grid,:));
    
            if(verbose)
                if(mod(idx_grid, floor((n_grid)/100))==0)
                    fprintf('.');
                end
                if(mod(idx_grid, floor((n_grid)/10))==0)
                    fprintf('|%d|',floor(idx_grid./floor((n_grid)/10)));
                    if(idx_grid == floor((n_grid)/2))
                        fprintf('\n')
                    end
                end
            end
            
        end
    else
        n_grid = n_discrete_state ;
        fprintf('n grid with discrete threshold= %d \n', n_grid);
        out_rewards = zeros(n_grid, n_repeat_for_optimum_search);
        xs = zeros(n_grid, 1);
        ys = zeros(n_grid, 1);
        for idx_grid = 1:n_grid
            th_repair = (th/n_discrete_state) * idx_grid;
            xs(idx_grid) = th_repair ;
            out_rewards(idx_grid,:) = th_Repair(env, unit, th_repair, n_repeat_for_optimum_search, false);
            ys(idx_grid) = mean(out_rewards(idx_grid,:));
    
            if(verbose)
                if(mod(idx_grid, floor((n_grid)/100))==0)
                    fprintf('.');
                end
                if(mod(idx_grid, floor((n_grid)/10))==0)
                    fprintf('|%d|',floor(idx_grid./floor((n_grid)/10)));
                    if(idx_grid == floor((n_grid)/2))
                        fprintf('\n')
                    end
                end
            end
            
        end
    end
    

    %END HERE -------------------------------------------------------------


% 
% 
%     out_rewards = zeros(n_grid, n_repeat_for_optimum_search);
%     xs = zeros(n_grid, 1);
%     ys = zeros(n_grid, 1);
%     % fprintf('Start RL: %s\n', str_title);
% %     n_grid = 100;
% %     th_repair = .7;i=1;
%     for idx_grid=1:n_grid;
% % 
%         th_repair = idx_grid/n_grid.*th;
% % %         fprintf('threshold = %f\n',th_repair)
%         xs(idx_grid) = th_repair ;
%         out_rewards(idx_grid,:) = th_Repair(env, unit, th_repair, n_repeat_for_optimum_search, false);
%         ys(idx_grid) = mean(out_rewards(idx_grid,:));
% 
%         if(verbose)
%             if(mod(idx_grid, floor((n_grid)/100))==0)
%                 fprintf('.');
%             end
%             if(mod(idx_grid, floor((n_grid)/10))==0)
%                 fprintf('|%d|',floor(idx_grid./floor((n_grid)/10)));
%                 if(idx_grid == floor((n_grid)/2))
%                     fprintf('\n')
%                 end
%             end
%         end
% 
%     end
%     if(verbose)
%         fprintf('\n');
%         figure(num_fig);clf;
%         plot(xs,ys);
%         title('Threshold vs Rewards');
%         xlabel('threshold');
%         ylabel('rewards');
%     end
    [val,idx]=max(ys);
    if(idx==1 || idx==n_grid)
        fprintf('[WARNING] threshold_matineance.m: The result may not be optimal.:th=%.2g\n', xs(idx));
    end
    opt_th = xs(idx);
    verbose_test =false;
    rewards = th_Repair(env, unit, opt_th, nRepeat, verbose_test);
    
%     val
%     xs(idx)
    fprintf('\n > Optimal Reward =%.2f, threshold = %.2f\n', val, xs(idx));
%     out = out_rewards(idx,:);
end

% 
% function out= th_Repair(env, unit, th_repair, nRepeat)
%     results = zeros(1,nRepeat);
%     for repeat = 1:nRepeat
%         action=[zeros(1, unit+1)];
%         env.reset();
%         for iter = 1:10000
%             [observation, reward, isDone, loggedSignals] = env.step(action);
%             repair = observation(1:unit)>th_repair;
%             action(1:unit) = repair;
%             action(unit+1)=sum(repair)>0;
% %             %--------------------------------------------
% % %             if(verbose)
% %                 fprintf('Obs:');
% %                 fprintf(' %.2f',observation);
% %                 fprintf('|| ');
% %                 
% %                 fprintf('[Repair:%d]',action(unit+1));
% %                 fprintf('%d ',action(1:unit));
% %                 fprintf('|');
% %                 fprintf('%d ',action(unit+2:end));
% %                 fprintf(' | Reward=%.2f\n',reward);
% % %                 fprintf('\n');
% % %             end
% % %             fprintf('Reward (t=%d): %d\n',env.time,reward);
% % %             if(verbose);fprintf('r: %d\n',reward);end;
% % %             if(verbose);
% % %             end;
% % 
% %             %--------------------------------------------
% 
%             if(isDone)
%                 results(repeat) = env.total_reward_actual;
%                 break;
%             end
%         end
%     end
%     % figure(1);clf;plot(results);
% %     out = mean(results);
%     out = results;
% end
% isDone
% getObservationInfo(env)
% getActionInfo(env)
