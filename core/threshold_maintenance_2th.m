function [rewards, opt_lower_th , opt_upper_th] = threshold_maintenance_2th(param, env, unit, nRepeat, verbose, n_grid)
% threshold_maintenance_2th(param, env, unit, nTrainingEpisodes, show_progress_arg, n_grid);
%     param = drl_params(time_budget, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, var_wl, lost_demand, demand, inspection_cost, verbose);
%     env = Maintenance_real_reward_no_workload_assignment(param, unit, th); %fprintf('Maintenance_real_reward_no_workload_assignment\n');
%         nRepeat = 10;
    if nargin>5
%         n_grid = n_grid;
    else
        n_grid=100;
    end
    verbose = true;

    %Define the approaches
    is_optimal_search = true; %true; %false;
    is_hetero_th = false; %false
    %Modify the max and min interval---------------------------------------
    increments = 0.25;
    n_repeat_for_optimum_search = 5;

    % Extract info
    n_discrete_state = env.num_discretized_states;
    highest_th = 1.0* env.threshold(1);
    th =  highest_th;
    lowest_th = highest_th/2;
    %END HERE -------------------------------------------------------------
    if is_optimal_search
        n_grid = (highest_th-lowest_th)/increments ;
        fprintf('n grid with optimal threshold= %d \n', n_grid);
    else
        n_grid = n_discrete_state ;
        fprintf('n grid with discrete threshold= %d \n', n_grid);
    end
    if is_hetero_th && unit == 2
        fprintf('Searching for heterogeous threshold for two components... \n');

        lowest_th_lower = 0 ;
        highest_th_lower = 20 ;
        lowest_th_upper = 10 ;
        highest_th_upper = 20 ;
        n_grid_lower = (highest_th_lower-lowest_th_lower)/increments ;
        n_grid_upper = (highest_th_upper-lowest_th_upper)/increments ;
        fprintf('n grid for lower for heterogeous threshold = %d \n', n_grid_lower);
        fprintf('n grid for upper for heterogeous threshold = %d \n', n_grid_upper);

        %Define storage matrix 
        out_rewards = zeros(n_repeat_for_optimum_search);
        n_iteration = n_grid_lower*n_grid_lower*n_grid_upper*n_grid_upper;
        xs1 = [];
        xs2 = [];
        xs1_upper = [];
        xs2_upper =  [];
        rewards =  [];
        for i = 1:n_grid_lower
            for j = 1:n_grid_upper
                for k = 1:n_grid_lower
                    for l = 1:n_grid_upper
                        th_repair_lower1 = lowest_th_lower + i *increments/n_grid_lower;
                        th_repair_upper1 = lowest_th_upper + j *increments/n_grid_upper;
                        th_repair_lower2 = lowest_th_lower + k *increments/n_grid_lower;
                        th_repair_upper2 = lowest_th_upper + l *increments/n_grid_upper;
                        if th_repair_lower1 < th_repair_upper1 || th_repair_lower2 < th_repair_upper2
                            xs1 = [xs1 , th_repair_lower1];
                            xs2 = [xs2 , th_repair_lower2];
                            xs1_upper = [xs1_upper ,th_repair_upper1];
                            xs2_upper =  [xs2_upper ,th_repair_upper2];
                            rewards_eval = th_Repair_2th_hetero(env, unit, th_repair_lower1,th_repair_upper1 , th_repair_lower2,th_repair_upper2, n_repeat_for_optimum_search, false);
                            rewards = [rewards,mean( rewards_eval)] ;
                        end
                        %Progress update
                        index = (n_grid_lower*n_grid_upper*n_grid_lower*(i-1)) +  (n_grid_lower*n_grid_upper*(j-1)) +(n_grid_lower*(k-1)) + l;
                        if(mod(index, n_grid_lower*n_grid_upper)==0)
                            fprintf('.');
                        end
                        if(mod(index, n_grid_lower*n_grid_upper*n_grid_lower)==0)
                            fprintf(': Progress %.2f %% \n',(index*100/n_iteration));
                        end
                    end          
                end
            end
        end
        [val,idx]=max(rewards);
        opt_lower_th1 = xs1(idx) ;
        opt_upper_th1 = xs1_upper(idx);
        opt_lower_th2 = xs2(idx) ;
        opt_upper_th2 = xs2_upper(idx) ;
        verbose_test =false;
        rewards_eval = th_Repair_2th_hetero(env, unit,  opt_lower_th1,opt_upper_th1 ,  opt_lower_th2,opt_upper_th2, nRepeat, verbose_test); 
        fprintf('> Optimal Reward =%.2f, lower threshold-1 = %.2f\n, upper threshold-1 = %.2f\n, lower threshold-2 = %.2f\n, upper threshold-2 = %.2f\n', rewards_eval, opt_lower_th1,opt_upper_th1 ,  opt_lower_th2,opt_upper_th2);
        opt_lower_th = [ opt_lower_th1,opt_lower_th2];
        opt_upper_th = [ opt_upper_th1,opt_upper_th2];
    else    
        fprintf('Searching for homogenous threshold... \n');
        %Define storage matrix 
        out_rewards = zeros(n_grid, n_repeat_for_optimum_search);
        xs = zeros(n_grid, n_grid);
        ys = zeros(n_grid, n_grid);
        xs_upper = zeros(n_grid, n_grid);

        for idx_grid=1:n_grid
            for idx_grid_upper = 1:n_grid
                if is_optimal_search
                    th_repair_lower = lowest_th + idx_grid * increments ;
                    th_repair_upper = lowest_th + idx_grid_upper*increments;
                else
                    th_repair_lower = (th/n_discrete_state) * idx_grid;
                    th_repair_upper = (th/n_discrete_state) * idx_grid_upper;
                end
                xs(idx_grid,idx_grid_upper) = th_repair_lower  ;
                xs_upper(idx_grid,idx_grid_upper) = th_repair_upper ;
                if th_repair_upper > th_repair_lower 
                    out_rewards(idx_grid,:) = th_Repair_2th(env, unit, th_repair_lower, th_repair_upper, n_repeat_for_optimum_search, false);
                    ys(idx_grid,idx_grid_upper) = mean(out_rewards(idx_grid,:));
                    fprintf('At th_l = %.2f  and th_h = %.2f : reward =  %d\n',  th_repair_lower,th_repair_upper,mean(out_rewards(idx_grid,:)));
                else
                    ys(idx_grid,idx_grid_upper) = -100000000000;
                end
    
                if(verbose)
                    if(mod(idx_grid_upper, floor((n_grid)/100))==0)
                        fprintf('.');
                    end
                    if(mod(idx_grid_upper, floor((n_grid)/10))==0)
                        fprintf('|%d|',floor(idx_grid_upper./floor((n_grid)/10)));
                        if(idx_grid_upper == floor((n_grid)/2))
                            fprintf('\n')
                        end
                    end
                end
    
            end
        end

        [val,idx]=max(ys);
        [val_1,idx_1] = max(val);
        if is_optimal_search    
            opt_lower_th = lowest_th+ idx(idx_1)* increments ;
            opt_upper_th = lowest_th + idx_1* increments;
        else
            opt_lower_th = (th(1)/n_discrete_state) * idx(idx_1);
            opt_upper_th = (th(1)/n_discrete_state) * idx_1;
        end
         
        if(idx_1 ==1 || idx_1==n_grid)
             fprintf('[WARNING] threshold_matineance.m: The result may not be optimal.:th=%.2g\n', xs(idx_1));
        end
        verbose_test =false;
        rewards = th_Repair_2th(env, unit, opt_lower_th,opt_upper_th, nRepeat, verbose_test);
        fprintf('> Optimal Reward =%.2f, lower threshold = %.2f\n, upper threshold = %.2f\n', val_1, opt_lower_th,opt_upper_th);
    end

end

    % % 
%         th_repair = idx_grid/n_grid.*th;
% % %         fprintf('threshold = %f\n',th_repair)
%         xs(idx_grid) = th_repair ;
%         out_rewards(idx_grid,:) = th_Repair_2th(env, unit, th_repair_lower, th_repair_upper, n_repeat_for_optimum_search, false);
% %       out_rewards(idx_grid,:) = th_Repair_2th(env, unit, th_repair, th_repair_upper, n_repeat_for_optimum_search, false);
%         ys(idx_grid) = mean(out_rewards(idx_grid,:));

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
%     end
%     if(verbose)
%         fprintf('\n');
%         figure(num_fig);clf;
%         plot(xs,ys);
%         title('Threshold vs Rewards');
%         xlabel('threshold');
%         ylabel('rewards');
%     end
    % [val,idx]=max(ys);
    % [val_1,idx_1] = max(val);
    %  if searching_method == 0
    %     if is_optimal_search    
    %         opt_lower_th = (th/2) + idx(idx_1)* increments /n_grid;
    %         opt_upper_th = (th/2) + idx_1* increments /n_grid;
    %     else
    %         opt_lower_th = (th/n_discrete_state) * idx(idx_1);
    %         opt_upper_th = (th/n_discrete_state) * idx_1;
    %     end
    %  else
    %     opt_lower_th = (th/2) + idx(idx_1)* increments /n_grid;
    %     opt_upper_th = (th/2) + idx_1* increments /n_grid;
    %  end
    % 

%     if(idx ==1 || idx==n_grid )
%         fprintf('[WARNING] threshold_matineance.m: The result may not be optimal.:th=%.2g\n', xs(idx));
%     end
%     if(idx_1 ==1 || idx_1==n_grid)
%         fprintf('[WARNING] threshold_matineance.m: The result may not be optimal.:th=%.2g\n', xs(idx_1));
%     end
%     verbose_test =false;
%     rewards = th_Repair_2th(env, unit, opt_lower_th,opt_upper_th, nRepeat, verbose_test);
% %     val
% %     xs(idx)
%     fprintf('> Optimal Reward =%.2f, lower threshold = %.2f\n, upper threshold = %.2f\n', val_1, opt_lower_th,opt_upper_th);
% %     out = out_rewards(idx,:);
% end

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
