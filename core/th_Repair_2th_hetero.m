function out= th_Repair_2th_hetero(env, unit, opt_lower_th1 , opt_upper_th1, opt_lower_th2 , opt_upper_th2, nRepeat, verbose)
    results = zeros(1,nRepeat);
    for repeat = 1:nRepeat
%         action=[zeros(1, unit+1)];
        action=[zeros(1, unit)];
        if(~env.noworkload)
            action=[zeros(1, 2*unit)];
            action(end-unit+1:end) = 1./env.demand;
        end
        env.reset();
        
        stop_iteration = 100000;

        for iter = 1:stop_iteration
            [observation, reward, isDone, loggedSignals] = env.step(action);
            upper_th_repair1 = observation(1)>opt_upper_th1;
            upper_th_repair2 = observation(2)>opt_upper_th2;
            repair_decision1 =sum(upper_th_repair1)>0;
            repair_decision2 =sum(upper_th_repair2)>0;
            if repair_decision1 || repair_decision2
                if observation(1) >opt_lower_th1
                    action(1) = 1;
                end
                if observation(2) >opt_lower_th2
                    action(2) = 1;
                end
            else
                action(1:2) = 0;
            end

%             repair = observation(1:unit)>th_repair;
%             action(1:unit) = repair;
%             action(unit+1)=sum(repair)>0;
%             %--------------------------------------------
            if(verbose)
                fprintf('Obs:');
                fprintf(' %.2f',observation);
                fprintf('|| ');
                
                fprintf('[Repair:%d]',action(unit+1));
                fprintf('%d ',action(1:unit));
                fprintf('|');
                fprintf('%d ',action(unit+2:end));
                fprintf(' | Reward=%.2f\n',reward);
                fprintf('\n');
            end
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
            if iter == stop_iteration
                fprintf('The testing evaluation is done before the environment is stopped. Stop_iteration need to be modified \n');
            end
        end
        env.init_rewards();
    end
    % figure(1);clf;plot(results);
%     out = mean(results);
    out = results;
end