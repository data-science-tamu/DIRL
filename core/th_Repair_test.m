function [out, obs]= th_Repair_test(env, unit, th_repair, nRepeat, verbose)
% th_Repair_test(env, unit, opt_th, num_test, false);
%     env.event_record ={};
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
            if repeat == 1
                obs{iter} = observation;
            end
            repair = observation(1:unit)>th_repair;
            action(1:unit) = repair;
            action(unit+1)=sum(repair)>0;
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