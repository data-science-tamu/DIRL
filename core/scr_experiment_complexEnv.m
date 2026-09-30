% nMethods = TYPE_METHOD.nMethods;
nMethods = numel(type_methods);
% logger = Logger();
rewards_test_local_result = zeros(nMethods, num_test);
rewards_training_local_result = zeros(nMethods, num_test);

logger.log(sprintf('RL starts at %s', showPrettyDateTime(now())));
% logger.log(sprintf('# Training= %d, # Testing = %d, # Steps =%d', nTrainingEpisodes, num_test, nSteps));
% logger.log(sprintf('Costs:C(replace)=%.2f, C(setup)=%.2f, C(fail)=%.2f, C(lostDemand)=%.2f', replace_cost, fix_main, failure_cost, lost_demand ));
% logger.log(sprintf('th=%.2f', th ));
% logger.log(sprintf('# Training=\t%d\t# Testing=\t%d\t# Steps=\t%d\tCosts:C(replace)=\t%.2f\tC(setup)=\t%.2f\tC(fail)=\t%.2f\tC(lostDemand)=\t%.2f\tth=\t%.2f\t', nTrainingEpisodes, num_test, nSteps, replace_cost, fix_main, failure_cost, lost_demand, th));
if(use_speicified_env)
    logger.log(sprintf('ENVIRONMENT SPECIFIED: %s', class(specified_env)))
else
    logger.log(sprintf('Costs:C(replace)=\t%.2f\tC(setup)=\t%.2f\tC(fail)=\t%.2f', replace_cost, fix_main, failure_cost));
    logger.log(sprintf('th=\t%.2f\t#unit=%d\t', th, unit));
end
if(exist('learn_rate','var'))
    agentOptionGenerater = AgentOptionGenerater(discountFactor, learn_rate);
    logger.log(sprintf('Used: learn rate:%2.4g',learn_rate));
else
    agentOptionGenerater = AgentOptionGenerater(discountFactor);
end
logger.seperate('START RL');
    tic_rep = tic();
    for idx_method = 1:nMethods
        try
            if isa(type_methods,'cell')
                info_method = type_methods{idx_method};
                method = info_method{1};
                nTrainingEpisodes = info_method{2};
            else
                method = type_methods(idx_method);
            end
            if size(cell_training_rewards{idx_method})==0; 
                training_rewards_each_method = zeros(nRepeats, numel(cost_setups), nTrainingEpisodes);
            else
                training_rewards_each_method = cell_training_rewards{idx_method};
            end
            if size(cell_test_rewards{idx_method})==0; 
                test_rewards_each_method = zeros(nRepeats, numel(cost_setups), num_test);
            else
                test_rewards_each_method = cell_test_rewards{idx_method};
            end
            logger.log(sprintf('# Training=\t%d\t# Testing=\t%d\t# Steps=\t%d', nTrainingEpisodes, num_test, nSteps));
%             param = Params_DRL(nSteps, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, cost_w, lost_demand, demand, inspection_cost, verbose, nTrainingEpisodes, num_test, num_discretized_states, var_meas_err);

            if(use_speicified_env)
            else
                logger.log(sprintf('Model: E[beta]=%.2g, Sd[beta]=%.2g, Sd[err]=%.2g', param.mean_beta, sqrt(param.var_beta),  sqrt(param.var_meas_err) ));
                logger.log(sprintf('Prior: E[mu_beta]=%.2g, Sd[mu_beta]=%.2g', param.mean_unit0, sqrt(param.var_unit0 )));
            end
            
            local_storage = struct();
            cnt_exp = cnt_exp+1;
        %% methods
    %         method = TYPE_METHOD.getMethod(idx_method);
        %     method = TYPE_METHOD.SAC_GRP;
        %     method = TYPE_METHOD.PERIODICAL;
            logger.log(sprintf('Run: [%s] (Rep:%d/%d, Method:%d/%d) (%d/%d)', method, idx_repeat, nRepeats, idx_method, nMethods, cnt_exp, nRepeats*nMethods));
            %% CREATE ENVIRONMENT
            tic_method = tic();
            if TYPE_METHOD.areStatesContinuous(method)
        %         env = Maintenance_real_reward_v3
                if method == TYPE_METHOD.SAC_GRP || method==TYPE_METHOD.SAC_GRP_LOOKAHEAD || method == TYPE_METHOD.TRPO_GRP_CACT_CSTA
                    addGroupVar = true;
                elseif method == TYPE_METHOD.SAC_NOGRP || method==TYPE_METHOD.SAC_NOGRP_LOOKAHEAD
                    addGroupVar = false;
                else
                    addGroupVar = false;
                end
                if method == TYPE_METHOD.DDPG && agentCanUseDiscrete
                    discretize_states = true;
                else
                    discretize_states = false;
                end
        %         env = Maintenance_real_reward_v3(param, unit, th, cap_w, noworkload, unboundedAgent, agentCanUseDiscrete, strictPenalty, addGroupVar, noWorkloadState);
            else
        %         env = Maintenance_real_reward_v3_discretized
        %         env = Maintenance_real_reward_v3_discretized(param, unit, th, cap_w, noworkload, unboundedAgent, agentCanUseDiscrete, strictPenalty, addGroupVar, noWorkloadState, num_states);
                discretize_states = true;
                addGroupVar = false;
            end
    
            isActionDiscrete = ~TYPE_METHOD.hasContinuousActionSpace(method);
    
            if (method == TYPE_METHOD.THRESHOLD || method == TYPE_METHOD.THRESHOLD_2TH ||method == TYPE_METHOD.PERIODICAL)
                show_progress_arg = false;
            else
                show_progress_arg = show_progress;
            end
            if(method==TYPE_METHOD.SAC_GRP_LOOKAHEAD || method==TYPE_METHOD.SAC_NOGRP_LOOKAHEAD)
                lookahead = true;
            else
                lookahead = false;
            end
            if(lookahead)
                logger.log(sprintf('> Lookahead'));
            else
                logger.log(sprintf('> No Lookahead'));
            end
            if(use_speicified_env)
                if(isActionDiscrete && isa(specified_env,'rl.env.CartPoleContinuousAction'))
                    logger.warn('[WARNING] Action space is discrete & Env action is continuous. Converted the env to Discrete Cart Pole.')
                    env = rlPredefinedEnv('CartPole-Discrete');
                elseif(~isActionDiscrete && isa(specified_env,'rl.env.CartPoleDiscreteAction'))
                    logger.warn('[WARNING] Action space is Continuous & Env action is discrete. Converted the env to Continuous Cart Pole.')
                    env = rlPredefinedEnv('CartPole-Continuous');
                else
                    env = specified_env;
                end
                
            else
                if(usegpu)
                    if(noworkload)
                        % env = Maintenance_real_reward_v3_EXPECT_COST_gpu(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg);
                        % env = Maintenance_real_reward_v3_EXPECT_COST_gpu_mod(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg);
                        if (env_type == "Simple")
                            env = Maintenance_real_reward_v3_EXPECT_COST_gpu_mod(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg);
                            if random_init_for_train
                                env.random_init_degrad = true;
                            end
                        elseif (env_type == "Complex-THRPUT")
                            env = Maintenance_real_reward_v3_EXPECT_COST_gpu_complexThrput(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg, cell);
                        elseif (env_type == "Complex-IM")
                            env = Maintenance_real_reward_v3_EXPECT_COST_gpu_complexIP(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg, cell);
                        elseif (env_type == "Complex")
                            env = Maintenance_real_reward_v3_EXPECT_COST_gpu_complex(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg, cell);
                        end
                    else
%                         env = Maintenance_real_reward_v3_EXPECT_COST_workload_gpu(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg);
                        env = Maintenance_real_reward_v3_EXPECT_COST_workload_gpu_mod(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg);
                    end
                else
                    env = Maintenance_real_reward_v3_EXPECT_COST(param, unit, th, cap_w, noworkload, unboundedAgent, isActionDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg);
                end
                if exist('apportion_workload_wrt_demand','var') 
                    env.apportion_workload_wrt_demand = apportion_workload_wrt_demand;
                    if(apportion_workload_wrt_demand)
                        fprintf('apportion_workload_wrt_demand = true\n');
                    else
                        fprintf('apportion_workload_wrt_demand = false\n');
                    end
                end
            end
    
            obsInfo = getObservationInfo(env);
            actInfo = getActionInfo(env);


            local_storage.env =env.copy();
            local_storage.actionInfo = actInfo;
            local_storage.observationInfo = obsInfo;
            local_storage.method = method;
            local_storage.addGroupVar = addGroupVar;
            local_storage.discretize_states = discretize_states;
            local_storage.param = param;
            local_storage.unit = unit;
            local_storage.th = th;
            local_storage.isActionDiscrete = isActionDiscrete;
            local_storage.lookahead = lookahead;
            
    
    %         logger.log(sprintf(' - Method:[%s]', method));
            switch method
                %% REFER TO https://www.mathworks.com/help/reinforcement-learning/ug/create-agents-for-reinforcement-learning.html
                case TYPE_METHOD.SAC_NOGRP
                    %% Soft actor critic without grouping 
                    agent_option = agentOptionGenerater.getAgentOption('SAC');
    %                 agent = rlSACAgent(obsInfo,actInfo, rlSACAgentOptions('DiscountFactor',discountFactor) );
                    agent = rlSACAgent(obsInfo,actInfo, agent_option );
                case TYPE_METHOD.SAC_GRP
                    %% PROPOSED METHOD
                    agent_option = agentOptionGenerater.getAgentOption('SAC');
                    agent = rlSACAgent(obsInfo,actInfo, agent_option );
                    
                case TYPE_METHOD.SAC_GRP_LOOKAHEAD
                    %% SAC without using E[failure]
                    %% AGENT Option - entropy Annealing 
                    agent_option = agentOptionGenerater.getAgentOption('SAC');
                    agent_option.PolicyUpdateFrequency = agent_PolUpdateFreq ; % default = 1
                    agent_option.EntropyWeightOptions.EntropyWeight = entropy_exploration ;
                    % agent_option.TargetUpdateFrequency = 1; % default = 1
%                     agent_option.EntropyWeightOptions.EntropyWeight = 5;  % default = 1
%                     disp(fprintf('EntropyWeight = %d', agent_option.EntropyWeightOptions.EntropyWeight));
                    if SAC_agent_type == 0
                        agent = rlSACAgent(obsInfo,actInfo, agent_option );
                    else
                        if is_monotinicNN
                            if  proportion_LossTPInspection > 0
                                agent = rlSACAgentMonotonicInspection(obsInfo,actInfo, agent_option );
                            else
                                agent = rlSACAgentMonotonic(obsInfo,actInfo, agent_option );
                            end
                        else
                            agent = rlSACAgentNew(obsInfo,actInfo, agent_option );
                        end
                        % set_sac_agent;
                        % agent = rlSACAgentNew(obsInfo,actInfo, agent_option,agentNNOption);
                    end
                case TYPE_METHOD.SAC_NOGRP_LOOKAHEAD
                    %% SAC without using E[failure]
                    agent_option = agentOptionGenerater.getAgentOption('SAC');
                    agent = rlSACAgent(obsInfo,actInfo, agent_option );
                case TYPE_METHOD.DDPG
                    %% Deep Deterministic Policy Gradient (DDPG) Agents
                    option = rlDDPGAgentOptions("DiscountFactor",discountFactor);
                    agent = rlDDPGAgent(obsInfo,actInfo, option);
                case TYPE_METHOD.DQN
                    %% DQN agents support only discrete action specification created using an 'rlFiniteSetSpec' object.
                    option = rlDQNAgentOptions("DiscountFactor",discountFactor,"UseDoubleDQN",false);
                    agent = rlDQNAgent(obsInfo,actInfo, option);
                case TYPE_METHOD.DDQN
                    %% DQN agents support only discrete action specification created using an 'rlFiniteSetSpec' object.
                    option = rlDQNAgentOptions("DiscountFactor",discountFactor,"UseDoubleDQN",true);
                    agent = rlDQNAgent(obsInfo,actInfo, option);
                case TYPE_METHOD.QLEARNING
                    %% Q Learning after discretization
                    qTable = rlTable(obsInfo,actInfo);
                    critic = rlQValueRepresentation(qTable,getObservationInfo(env),getActionInfo(env));
                    opt = rlQAgentOptions;
                    opt.EpsilonGreedyExploration.Epsilon = 0.05;
                    opt.DiscountFactor = discountFactor;
                    agent = rlQAgent(critic,opt);
                case TYPE_METHOD.SALSA
                    %% SALSA
                    qTable = rlTable(obsInfo,actInfo);
                    critic = rlQValueRepresentation(qTable,getObservationInfo(env),getActionInfo(env));
                    agent = rlSARSAAgent(critic,  rlSARSAAgentOptions('DiscountFactor',discountFactor ) );
                case TYPE_METHOD.PERIODICAL
                    % Time(Periodic)-based
                    n_interval = 100; show_only_specific_interval = false; 
                    %% TRAINING 
                    % SET Discount factor
                    tic_train=tic(); % Start Ticking Train
                    [rewards_training, opt_interval] = regular_maintenance(param, env, unit, nTrainingEpisodes, verbose, n_interval);
                    training_rewards_each_method = get_updated_training_rewards_each_methods(training_rewards_each_method, idx_repeat, idx_param, rewards_training);
                    cell_training_rewards{idx_method} = training_rewards_each_method;

                     % Measure Training Time
                    elapsed_time_training=toc(tic_train); % Measure Training Time
                    logger.log(sprintf('Optimal period:%d',opt_interval)); % Log Optimal period
                    logger.log(sprintf('Training Time:%s',showPrettyElapsedTime(elapsed_time_training))); % Log Training Time


                    %% TESTING
                    tic_test=tic(); % Start Ticking Test
                    [rewards_test,obs_periodic] = interval_Repair_test(env, unit, opt_interval, num_test, false);
%                         rewards_all_test(idx_repeat, idx_method, :) = rewards_test;
%                         rewards_test_local_result(idx_method, :) = rewards_test;
                    test_rewards_each_method = get_updated_training_rewards_each_methods(test_rewards_each_method, idx_repeat, idx_param, rewards_test);
                    cell_test_rewards{idx_method} = test_rewards_each_method;

					 % Measure Testing Time
                    elapsed_time_testing=toc(tic_test); % Measure Testing Time
                    logger.log(sprintf('Testing Time:%s',showPrettyElapsedTime(elapsed_time_testing))); % Log Testing Time
                    logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_test)));
                    logger.log(sprintf('\tMedian Test Rewards:%.2f', median(rewards_test)));
                    logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test)));
                    test_reward = squeeze(vertcat(test_rewards_each_method));
                    % record_name = sprintf('./data_csv/TestingReward_%s_%s.csv',prefix_filename, method );
                    record_name = sprintf('./data_csv/TestingReward_%s.csv',prefix_filename);
                    writematrix(test_reward,record_name);

                case TYPE_METHOD.THRESHOLD
                    tic_train=tic(); % Start Ticking Train
                    % Threshold-based
                    n_grid = 100;
                    %% TRAINING 
                    % SET Discount factor
                    if th_policy_isUpLowSpecified
                        opt_th = defined_opt_upper_th ;
                        rewards_training = 0;
                    else
                        [rewards_training, opt_th] = threshold_maintenance(param, env, unit, nTrainingEpisodes, show_progress_arg, n_grid);
                        training_rewards_each_method = get_updated_training_rewards_each_methods(training_rewards_each_method, idx_repeat, idx_param, rewards_training);
                        cell_training_rewards{idx_method} = training_rewards_each_method;
                    end
                     % Measure Training Time
                    elapsed_time_training=toc(tic_train); % Measure Training Time
                    logger.log(sprintf('Optimal threshold:%d',opt_th)); % Log Optimal threshold
                    logger.log(sprintf('Training Time:%s',showPrettyElapsedTime(elapsed_time_training))); % Log Training Time

                    %% TESTING
                    tic_test=tic(); % Start Ticking Test
                    [rewards_test, obs_threshold] = th_Repair_test(env, unit, opt_th, num_test, false);
                    test_rewards_each_method = get_updated_training_rewards_each_methods(test_rewards_each_method, idx_repeat, idx_param, rewards_test);
                    cell_test_rewards{idx_method} = test_rewards_each_method;
					 % Measure Testing Time
                    elapsed_time_testing=toc(tic_test); % Measure Testing Time
                    logger.log(sprintf('Testing Time:%s',showPrettyElapsedTime(elapsed_time_testing))); % Log Testing Time
                    logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_test)));
                    logger.log(sprintf('\tMedian Test Rewards:%.2f', median(rewards_test)));
                    logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test)));
                    test_reward = squeeze(vertcat(test_rewards_each_method));
                    % record_name = sprintf('./data_csv/TestingReward_%s_%s.csv',prefix_filename, method );
                    record_name = sprintf('./data_csv/TestingReward_%s.csv',prefix_filename);
                    writematrix(test_reward,record_name);
                case TYPE_METHOD.THRESHOLD_2TH
                    tic_train=tic(); % Start Ticking Train
                    if th_policy_isUpLowSpecified
                        opt_lower_th = defined_opt_lower_th;
                        opt_upper_th = defined_opt_upper_th ;
                        rewards_training = 0;
                        cell_training_rewards{idx_method} = 0;
                        logger.log(sprintf('Threshold policy with Upper and lower threshold (Predefined)')); 
                        logger.log(sprintf('Optimal Upper threshold:%d',opt_upper_th)); % Log Optimal threshold
                        logger.log(sprintf('Optimal Lower threshold:%d',opt_lower_th)); % Log Optimal threshold
                        elapsed_time_training=toc(tic_train); % Measure Training Time
                    else
                        n_grid = 100;
                        %% TRAINING 
                        % SET Discount factor
                        [rewards_training, opt_lower_th , opt_upper_th] = threshold_maintenance_2th(param, env, unit, nTrainingEpisodes, show_progress_arg, n_grid);
                        training_rewards_each_method = get_updated_training_rewards_each_methods(training_rewards_each_method, idx_repeat, idx_param, rewards_training);
                        cell_training_rewards{idx_method} = training_rewards_each_method;
                        % Measure Training Time
                        elapsed_time_training=toc(tic_train); % Measure Training Time
                        logger.log(sprintf('Optimal Upper threshold:%d',opt_upper_th)); % Log Optimal threshold
                        logger.log(sprintf('Optimal Lower threshold:%d',opt_lower_th)); % Log Optimal threshold
                        logger.log(sprintf('Training Time:%s',showPrettyElapsedTime(elapsed_time_training))); % Log Training Time
                    end
                    %% TESTING
                    tic_test=tic(); % Start Ticking Test
                    [rewards_test, obs_threshold_2th] = th_Repair_2th_test(env, unit, opt_lower_th , opt_upper_th, num_test, false);
                    test_rewards_each_method = get_updated_training_rewards_each_methods(test_rewards_each_method, idx_repeat, idx_param, rewards_test);
                    cell_test_rewards{idx_method} = test_rewards_each_method;
					 % Measure Testing Time
                    elapsed_time_testing=toc(tic_test); % Measure Testing Time
                    logger.log(sprintf('Testing Time:%s',showPrettyElapsedTime(elapsed_time_testing))); % Log Testing Time
                    logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_test)));
                    logger.log(sprintf('\tMedian Test Rewards:%.2f', median(rewards_test)));
                    logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test)));
                    test_reward = squeeze(vertcat(test_rewards_each_method));
                    % record_name = sprintf('./data_csv/TestingReward_%s_%s.csv',prefix_filename, method );
                    record_name = sprintf('./data_csv/TestingReward_%s.csv',prefix_filename);
                    writematrix(test_reward,record_name);
                case TYPE_METHOD.DO_NOTHING
                    %% TRAINING 
                    tic_train=tic(); % Start Ticking Train
                    rewards_training = rewards_when_do_nothing(env,nTrainingEpisodes, show_progress_arg);
                    training_rewards_each_method = get_updated_training_rewards_each_methods(training_rewards_each_method, idx_repeat, idx_param, rewards_training);
                    cell_training_rewards{idx_method} = training_rewards_each_method;
                     % Measure Training Time
                    elapsed_time_training=toc(tic_train); % Measure Training Time
                    logger.log(sprintf('Training Time:%s',showPrettyElapsedTime(elapsed_time_training))); % Log Training Time
                    %% TESTING
                    tic_test=tic(); % Start Ticking Test
                    rewards_test = rewards_when_do_nothing(env,num_test, show_progress_arg);
                    test_rewards_each_method = get_updated_training_rewards_each_methods(test_rewards_each_method, idx_repeat, idx_param, rewards_test);
                    cell_test_rewards{idx_method} = test_rewards_each_method;
					 % Measure Testing Time
                    elapsed_time_testing=toc(tic_test); % Measure Testing Time
                    logger.log(sprintf('Testing Time:%s',showPrettyElapsedTime(elapsed_time_testing))); % Log Testing Time
                     logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_test)));
                    logger.log(sprintf('\tMedian Test Rewards:%.2f', median(rewards_test)));
                    logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test)));
                    test_reward = squeeze(vertcat(test_rewards_each_method));
                    % record_name = sprintf('./data_csv/TestingReward_%s_%s.csv',prefix_filename, method );
                    record_name = sprintf('./data_csv/TestingReward_%s.csv',prefix_filename);
                    writematrix(test_reward,record_name);
                case TYPE_METHOD.MAINTAIN_EVERYTIME
                    %% TRAINING 
                    tic_train=tic(); % Start Ticking Train
                    rewards_training = rewards_when_maintain_everytime(env,nTrainingEpisodes, show_progress_arg);
                    training_rewards_each_method = get_updated_training_rewards_each_methods(training_rewards_each_method, idx_repeat, idx_param, rewards_training);
                    cell_training_rewards{idx_method} = training_rewards_each_method;
					 % Measure Training Time
                    elapsed_time_training=toc(tic_train); % Measure Training Time
                    logger.log(sprintf('Training Time:%s',showPrettyElapsedTime(elapsed_time_training))); % Log Training Time

                    %% TESTING
                    tic_test=tic(); % Start Ticking Test
                    rewards_test = rewards_when_maintain_everytime(env,num_test, show_progress_arg);
                    test_rewards_each_method = get_updated_training_rewards_each_methods(test_rewards_each_method, idx_repeat, idx_param, rewards_test);
                    cell_test_rewards{idx_method} = test_rewards_each_method;
					 % Measure Testing Time
                    elapsed_time_testing=toc(tic_test); % Measure Testing Time
                    logger.log(sprintf('Testing Time:%s',showPrettyElapsedTime(elapsed_time_testing))); % Log Testing Time
                     logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_test)));
                    logger.log(sprintf('\tMedian Test Rewards:%.2f', median(rewards_test)));
                    logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test)));
                    test_reward = squeeze(vertcat(test_rewards_each_method));
                    % record_name = sprintf('./data_csv/TestingReward_%s_%s.csv',prefix_filename, method );
                    record_name = sprintf('./data_csv/TestingReward_%s.csv',prefix_filename);
                    writematrix(test_reward,record_name);

                %% == NEWLY ADDED ====================================
                case TYPE_METHOD.PPO_CACT
			        option = rlPPOAgentOptions("DiscountFactor",discountFactor); % Action <0 
			        agent = rlPPOAgent(obsInfo, actInfo, option);
                    %
                case TYPE_METHOD.PPO_DACT
			        option = rlPPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlPPOAgent(obsInfo, actInfo, option);
                    %
                case TYPE_METHOD.PPO_CACT_SAC_ACTOR
			        option = rlPPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlPPOAgent(obsInfo, actInfo, option);
    
                    sac_agent = rlSACAgent(obsInfo,actInfo, agentOptionGenerater.getAgentOption('SAC') );
                    agent.setActor(sac_agent.getActor());
                case TYPE_METHOD.AC_CACT_SAC_ACTOR
			        option = rlACAgentOptions("DiscountFactor",discountFactor); % Action <0 
			        agent = rlACAgent(obsInfo, actInfo, option);
    
                    sac_agent = rlSACAgent(obsInfo,actInfo, agentOptionGenerater.getAgentOption('SAC') );
                    agent.setActor(sac_agent.getActor());
                case TYPE_METHOD.AC_CACT
			        option = rlACAgentOptions("DiscountFactor",discountFactor); % Action <0 
			        agent = rlACAgent(obsInfo, actInfo, option);
                case TYPE_METHOD.AC_DACT
			        option = rlACAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlACAgent(obsInfo, actInfo, option);
                case TYPE_METHOD.PG_CACT
			        option = rlPGAgentOptions("DiscountFactor",discountFactor); 
			        agent =  rlPGAgent(obsInfo, actInfo, option);
                case TYPE_METHOD.PG_DACT
			        option = rlPGAgentOptions("DiscountFactor",discountFactor); 
			        agent =  rlPGAgent(obsInfo, actInfo, option);
                case TYPE_METHOD.TD3
			        option = rlTD3AgentOptions("DiscountFactor",discountFactor); 
			        agent =  rlTD3Agent(obsInfo, actInfo, option);
                %------
                case TYPE_METHOD.TRPO_CACT_DSTA
			        option = rlTRPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlTRPOAgent (obsInfo, actInfo, option);
                case TYPE_METHOD.TRPO_DACT_DSTA
			        option = rlTRPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlTRPOAgent (obsInfo, actInfo, option);
                case TYPE_METHOD.TRPO_CACT_CSTA
			        option = rlTRPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlTRPOAgent (obsInfo, actInfo, option);
                case TYPE_METHOD.TRPO_GRP_CACT_CSTA
			        option = rlTRPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlTRPOAgent (obsInfo, actInfo, option);
                case TYPE_METHOD.TRPO_DACT_CSTA
			        option = rlTRPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlTRPOAgent (obsInfo, actInfo, option);
                case TYPE_METHOD.TRPO_CACT_CSTA_SAC_ACTOR
			        option = rlTRPOAgentOptions("DiscountFactor",discountFactor); 
			        agent = rlTRPOAgent (obsInfo, actInfo, option);
                %------
    % 	        case TYPE_METHOD.MBPO_DQN
    % 				option = rlMBPOAgentOptions("DiscountFactor",discountFactor); 
    % 				agent = rlMBPOAgent(obsInfo, actInfo, option);
    % 	        case TYPE_METHOD.MBPO_DDPG
    % 				option = rlAgentOptions("DiscountFactor",discountFactor); 
    % 				agent = rlAgent(obsInfo, actInfo, option);
    % 	        case TYPE_METHOD.MBPO_TD3
    % 				option = rlAgentOptions("DiscountFactor",discountFactor); 
    % 				agent = rlAgent(obsInfo, actInfo, option);
    % 	        case TYPE_METHOD.MBPO_SAC		
    % 				option = rlAgentOptions("DiscountFactor",discountFactor); 
    % 				agent = rlAgent(obsInfo, actInfo, option); 	                
                otherwise
                    logger.warn(sprintf('[WARNING] Unsupported method:%s',method))
        %             
            end
        %% USE GPU or CPU
            if(usegpu && exist('agent','var'))
                try
                    actors = agent.getActor();
                    for i=1:numel(actors)
                        actors(i).UseDevice = "gpu";
                    end
                    agent.setActor(actors);
                catch err
                    
                end
                try
                    critics = agent.getCritic();
                    for i=1:numel(critics)
                        critics(i).UseDevice = "gpu";
                    end
                    agent.setCritic(critics);
                catch err
                end
            end
    
            switch method
                case TYPE_METHOD.THRESHOLD
                case TYPE_METHOD.THRESHOLD_2TH
                case TYPE_METHOD.PERIODICAL
                case TYPE_METHOD.DO_NOTHING 
                case TYPE_METHOD.MAINTAIN_EVERYTIME 
                otherwise
                    
                    %% === Train =======================================
                    trainOpts = rlTrainingOptions;
                    if(useParallel)
                        trainOpts.UseParallel = true;
                    end
                    trainOpts.MaxEpisodes = nTrainingEpisodes;
                    trainOpts.MaxStepsPerEpisode = nSteps;
                    trainOpts.StopTrainingCriteria = "AverageReward";
                    % trainOpts.StopTrainingValue = 500;
%                         trainOpts.ScoreAveragingWindowLength = 5;
    
                    % trainOpts.SaveAgentCriteria = "None";
                    % trainOpts.SaveAgentCriteria = "EpisodeReward" ;
                    % trainOpts.SaveAgentValue = -3000;
%                         trainOpts.SaveAgentCriteria = "EpisodeFrequency" ;
%                         trainOpts.SaveAgentValue = 1;
                    trainOpts.SaveAgentCriteria = "EpisodeCount" ;
                    trainOpts.SaveAgentValue = 1;
                    % trainOpts.SaveAgentCriteria = "EpisodeReward";
                    SaveAgentDir= sprintf('./savedAgents/%s_%s',prefix_filename, method );
                    trainOpts.SaveAgentDirectory = SaveAgentDir;
    
                    trainOpts.Verbose = verbose_training;
                    if(show_episode_manager)
                        trainOpts.Plots = "training-progress";
                    else
                        trainOpts.Plots = "none";
                    end
                    % plot(env)
                    if(show_progress_arg)
                        logger.log(sprintf('[Train:Start]  :'))
                    end
                    tic_train = tic();
                    if SAC_agent_type == 2
                        learnt_agent = load(agent_location);
                        agent = learnt_agent.saved_agent;
                        fprintf('The trained agent is loading : %s',agent_location);
                    end
                    %% START: TRAIN
                  if not(is_tested_version)
                    if random_init_for_train
                        env.random_init_degrad = true;
                    else
                        env.random_init_degrad = false;
                    end
                    trainingInfo = train(agent,env,trainOpts);
                    % logger_rl = rlDataLogger();
                    % logger_rl.LoggingOptions.LoggingDirectory = "myDataLog-"+prefix_filename;
                    % logger_rl.EpisodeFinishedFcn    = @myEpisodeFinishedFcn;
                    % logger_rl.AgentStepFinishedFcn  = @myAgentStepFinishedFcn;
                    % logger_rl.AgentLearnFinishedFcn = @myAgentLearnFinishedFcn;
                    % trainingInfo = train(agent,env,trainOpts, Logger=logger_rl);
                    trained_models{idx_repeat, idx_method} = trainingInfo;
                    if(isa(env,'Abs_Maintenance_env'))
%                             training_rewards(idx_repeat, idx_method,:) = env.training_rewards_real;
                        rewards_training = env.training_rewards_real;
%                             local_storage.rewards_real_training = rewards_training;
                    else
                        rewards_training = trainingInfo.EpisodeReward;
%                             local_storage.rewards_real_training = trainingInfo.EpisodeReward;
                    end
                    if random_init_for_train
                        env.random_init_degrad = false;
                    end
                   
                    %% DONE: TRAIN

                    %% store data
                    local_storage.trainOpts = trainOpts;
                    local_storage.trainingInfo = trainingInfo;
                    %% LOG
                    elapsed_time_training=toc(tic_train);
                    logger.log(sprintf('Training Time:%s',showPrettyElapsedTime(elapsed_time_training)));
%                         try
%                             training_rewards_each_method(idx_repeat, idx_param, :) = rewards_training;
%                         catch err
%                             showErrors(err)
% 
%                             try
%                                 training_rewards_each_method(idx_repeat, idx_param, 1:numel(rewards_training)) = rewards_training;
%                             catch err
%                                 showErrors(err)
%                             end
% 
%                         end
                    training_rewards_each_method = get_updated_training_rewards_each_methods(training_rewards_each_method, idx_repeat, idx_param, rewards_training);
                    cell_training_rewards{idx_method} = training_rewards_each_method;
                    
                    %% Save training rewards
                    train_reward = squeeze(vertcat(rewards_training));
                    record_name = sprintf('./data_csv/TrainingReward_%s.csv',prefix_filename);
                    writematrix(train_reward,record_name);
                 end
                    %% DRAW PLOT: TRAINING
%                         if isa(env,'Abs_Maintenance_env') && exist('draw_plot_training','var') && draw_plot_training==true
%                         if exist('draw_plot_training','var') && draw_plot_training==true
% %                             scr_visualize_training_every_iter
%                             visualize_rewards(cell_training_rewards, idx_repeat, idx_param, type_methods, nMethods, prefix_filename, 30)
%                         end

                    %% DONE: PLOT
    
                    % fprintf('Done: T\n')
    
                    % n_train=env.cnt_episode;
                    % predict(trainingInfo, 
                    % experiences = 
                    %% ----------------------------------------------------

                    %% START: TEST (VALIDATE):
                    if(show_progress_arg)
                        fprintf('[Vadlidate: Start] ')
                    end
                    if strcmp(env_type,'Complex-THRPUT')
                        n_fail = []; 
                        n_maintenance = []; 
                        n_inspection = []; 
                        env.count_fail = 0;
                        env.count_maintenance = 0;
                        env.count_inspection = 0;
                    end
                    tic_test=tic(); % Start Ticking Test
                    experiences_arr = zeros(num_test,1);
                    if is_tested_version
                        if strcmp(env_type,'Simple')
                            env.event_record ={};
                        end
                        fprintf('Loading the best of trained agents for testing.... \n ')
                        fileLoc = sprintf('./savedAgents/%s_%s/Agent%d.mat',prefix_filename, method ,evaluated_iteration );
                        learnt_agent = load(fileLoc);
                        agent = learnt_agent.saved_agent;
                        for itest = 1:num_test
                            simOptions = rlSimulationOptions('MaxSteps',nSteps);
                            experience = sim(env, agent, simOptions);
                            experiences_arr(itest)=sum(experience.Reward.Data);
                            experiences{idx_repeat, idx_method, itest} = experience;
                            if strcmp(env_type,'Complex-THRPUT')
                                n_fail = [n_fail,env.count_fail]; 
                                n_maintenance = [n_maintenance,env.count_maintenance]; 
                                n_inspection = [n_inspection,env.count_inspection ]; 
                                env.count_fail = 0;
                                env.count_maintenance = 0;
                                env.count_inspection = 0;
                            end
                        end
                        if is_evaluated_policy && unit == 2
                            if strcmp(env_type,'Simple') 
                                get_policyTable_afterTraining;
                                record_name = sprintf('./data_csv/PolicyTable_%s_Agent%d.csv',prefix_filename);
                                writematrix(result,record_name);
                            end
                        end

                    elseif trainOpts.SaveAgentCriteria == "EpisodeCount"  %"EpisodeFrequency"
                        if strcmp(env_type,'Simple')
                            env.event_record ={};
                        end
                        [val, agent_iter_max] =max(train_reward);
                        fprintf('Loading the best of trained agents for testing.... \n ')
                        fileLoc = sprintf('./savedAgents/%s_%s/Agent%d.mat',prefix_filename, method ,agent_iter_max );
                        learnt_agent = load(fileLoc);
                        agent = learnt_agent.saved_agent;
                        for itest = 1:num_test
                            simOptions = rlSimulationOptions('MaxSteps',nSteps);
                            experience = sim(env, agent, simOptions);
                            experiences_arr(itest)=sum(experience.Reward.Data);
                            if strcmp(env_type,'Complex-THRPUT')
                                n_fail = [n_fail,env.count_fail]; 
                                n_maintenance = [n_maintenance,env.count_maintenance]; 
                                n_inspection = [n_inspection,env.count_inspection ]; 
                                env.count_fail = 0;
                                env.count_maintenance = 0;
                                env.count_inspection = 0;
                            end
                        end
                        if is_evaluated_policy && unit == 2
                            if strcmp(env_type,'Simple') 
                                get_policyTable_afterTraining;
                                record_name = sprintf('./data_csv/PolicyTable_%s.csv',prefix_filename);
                                writematrix(result,record_name);
                            end
                        end
    %                     %Export test rewards
    %                     if isa(env,'Abs_Maintenance_env')
    %                         % Get real rewards without penalty or incentive : E[failure]
    %                         rewards_test = env.test_rewards_real((num_test+1):(num_test*2));
    %                     else
    %                         % Get rewards obtained as result of simulation
    % %                             rewards_test = sum(experience.Reward); %% TODO: USE experiences{}
    %                         rewards_test = experiences_arr_best;
    %                     end
    %                     test_reward = squeeze(vertcat(rewards_test));
    %                     record_name = sprintf('./data_csv/TestingReward_%s_%s_Agent%d.csv',prefix_filename, method ,agent_iter_max);
    %                     writematrix(test_reward,record_name);
                    else
                        if strcmp(env_type,'Simple')
                            env.event_record ={};
                        end
                        for itest = 1:num_test
                            simOptions = rlSimulationOptions('MaxSteps',nSteps);
                            experience = sim(env, agent, simOptions);
                            experiences_arr(itest)=sum(experience.Reward.Data);
                            experiences{idx_repeat, idx_method, itest} = experience;
                            if strcmp(env_type,'Complex-THRPUT')
                                n_fail = [n_fail,env.count_fail]; 
                                n_maintenance = [n_maintenance,env.count_maintenance]; 
                                n_inspection = [n_inspection,env.count_inspection ]; 
                                env.count_fail = 0;
                                env.count_maintenance = 0;
                                env.count_inspection = 0;
                            end
                        end
                        if is_evaluated_policy && unit == 2
                            if strcmp(env_type,'Simple') 
                                get_policyTable_afterTraining;
                                record_name = sprintf('./data_csv/PolicyTable_%s_last.csv',prefix_filename);
                                writematrix(result,record_name);
                            end
                        end

                    end
                    %% END: TEST (VALIDATE):
                    if strcmp(env_type,'Complex-THRPUT')
                        logger.log(sprintf('\t Summary from testing'));
                        logger.log(sprintf('\t Number of failures: mean = %.2f, median = %.2f , stdev= %.2f', mean(n_fail), median(n_fail), std(n_fail)));
                        logger.log(sprintf('\t Number of maintenance: mean = %.2f, median = %.2f , stdev= %.2f', mean(n_maintenance), median(n_maintenance), std(n_maintenance)));
                        logger.log(sprintf('\t Number of inspection: mean = %.2f, median = %.2f , stdev= %.2f', mean(n_inspection), median(n_inspection), std(n_inspection)));
                    end
                    % Calculate mean test reward
                    if is_tested_version
                         rewards_test = env.all_rewards_real(1:num_test) ;
                    elseif isa(env,'Abs_Maintenance_env')
                        % Get real rewards without penalty or incentive : E[failure]
                        rewards_test = env.test_rewards_real;
                    else
                        % Get rewards obtained as result of simulation
%                             rewards_test = sum(experience.Reward); %% TODO: USE experiences{}
                        rewards_test = experiences_arr;
                    end
                    %Export test rewards
                    test_reward = squeeze(vertcat(rewards_test));
                    % record_name = sprintf('./data_csv/TestingReward_%s_%s.csv',prefix_filename, method );
                    if is_tested_version
                        record_name = sprintf('./data_csv/TestingReward_%s_Iter%d.csv',prefix_filename,evaluated_iteration);
                    else
                        record_name = sprintf('./data_csv/TestingReward_%s.csv',prefix_filename);
                    end
                    writematrix(test_reward,record_name);
                    sprintf('\tMean Test Rewards:%.2f', mean(rewards_test))
                    sprintf('\tMedian Test Rewards:%.2f', median(rewards_test))
                    sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test))


					% Measure Testing Time
                    elapsed_time_testing=toc(tic_test); % Measure Testing Time
                    logger.log(sprintf('Testing Time:%s',showPrettyElapsedTime(elapsed_time_testing))); % Log Testing Time
                    logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_test)));
                    logger.log(sprintf('\tMedian Test Rewards:%.2f', median(rewards_test)));
                    logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test)));
                    test_rewards_each_method = get_updated_training_rewards_each_methods(test_rewards_each_method, idx_repeat, idx_param, rewards_test);
                    cell_test_rewards{idx_method} = test_rewards_each_method;
                                        elapsed_time_testing=toc(tic_test); % Measure Testing Time
            



%                     if isa(env,'Abs_Maintenance_env')
%                         % Get real rewards without penalty or incentive : E[failure]
%                         rewards_test = env.test_rewards_real;
%                     else
%                         % Get rewards obtained as result of simulation
% %                             rewards_test = sum(experience.Reward); %% TODO: USE experiences{}
%                         rewards_test = experiences_arr;
%                     end
%                         rewards_test_local_result(idx_method, :) = rewards_test;
%                         rewards_all_test(idx_repeat, idx_method,:) = rewards_test;

%                         test_rewards_each_method(idx_repeat, idx_param, :) = rewards_test;
                    % store data
                    local_storage.agent = agent.copy();        
                    if(isa(env,'Abs_Maintenance_env')  && numel(env.test_rewards_real) ~= numel(rewards_test))
                        logger.log("WARNING: Matrix size mismatch: env.test_rewards_real vs rewards_all_test(idx_repeat, idx_method,:)")
                    end
            end

            %% Save record of event during testing
            if strcmp(env_type,'Simple') && unit == 2
                fprintf('Event record is saving...');
                event_record = cell2mat(squeeze(vertcat(env.event_record)));
                record_name = sprintf('./testing_records/TestingReward_%s.csv',prefix_filename);
                writematrix(event_record ,record_name);
            end 
          
            mean_test_rewards = mean(test_rewards_each_method(idx_repeat, idx_param, :));
            median_test_rewards = median(test_rewards_each_method(idx_repeat, idx_param, :));
            std_test_rewards = std(test_rewards_each_method(idx_repeat, idx_param, :));
%             str = sprintf('filename|idx_repeat|method.char|elapsed_time_training|elapsed_time_testing|mean_test_rewards|std_test_rewards|median_test_rewards');
            
            %Swap from Line 491
            if exist('draw_plot_training','var')
                visualize_rewards(cell_training_rewards, idx_repeat, idx_param, type_methods, nMethods, prefix_filename, 'training', 30, [], draw_plot_training, sprintf('training_%s',filename))
            end
            if exist('draw_plot_test_rewards','var')
                visualize_rewards(cell_test_rewards, idx_repeat, idx_param, type_methods, nMethods, prefix_filename, 'test', 31, [], draw_plot_test_rewards, sprintf('test_%s',filename));                            
            end
            %End

            str = sprintf('%s\t%d\t%s\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f',filename, idx_repeat, method.char, elapsed_time_training, elapsed_time_testing, mean_test_rewards, std_test_rewards, median_test_rewards);
            result_writer.write_no_print(str);

            toc_method =toc(tic_method);
            logger.log(sprintf('Elapsed Time (%s):%s',method,showPrettyElapsedTime(toc_method)));
%                 logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_all_test(idx_repeat, idx_method, :))));
%                 logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_all_test(idx_repeat, idx_method, :))));
            % logger.log(sprintf('\tMean Test Rewards:%.2f', mean(rewards_test)));
            % logger.log(sprintf('\tStd.Dev Test Rewards:%.2f', std(rewards_test)));
            logger.seperate()
        % fprintf('Done: Validation\n')
        % bdclose(mdl)
        %% 
        % generatePolicyFunction(agent)


%                 local_storage.rewards_test = rewards_test_local_result(idx_method, :);
%                 local_storage.test_rewards_mean = mean(rewards_test_local_result(idx_method, :));
%                 local_storage.test_rewards_std = std(rewards_test_local_result(idx_method, :));
            local_storage.rewards_test = rewards_test;
            local_storage.test_rewards_mean = mean(rewards_test);
            local_storage.test_rewards_std = std(rewards_test);
            
            local_storage.rewards_training = rewards_training;
            local_storage.training_rewards_mean = mean(rewards_training);
            local_storage.training_rewards_std = std(rewards_training);
            
            local_storage.elapsed_time_method = toc_method;
            local_storage.elapsed_time_method_str = sprintf('Elapsed Time (%s):%s',method,showPrettyElapsedTime(toc_method));
            cell_local_storage{idx_repeat,idx_param,idx_method} = local_storage;                
        %% Validate
            delete(env);
        catch err
            logger.error(getStrErrors(err));
        end
        try
            if(exist('agent','var'))
                delete(agent)
            end
        catch err
            showErrors(err)
        end
        
    end
    logger.seperate('A Rep Ends')
    toc_rep = toc(tic_rep);
    logger.log(sprintf('Elapsed Time (One Repeat):%s',showPrettyElapsedTime(toc_rep)));
%     logger.log(sprintf('%s',getEstimatedRemainedTime(toc(tic_all), idx_repeat, nRepeats)));
%     logger.log(sprintf('%s',getEstimatedEndTime(toc(tic_all), idx_repeat, nRepeats)));
    logger.seperate()
    logger.seperate()
% end
% showPrettyElapsedTime(toc_all);

storage.rewards_all_test = rewards_all_test;
storage.training_rewards = training_rewards_each_method;
storage.experiences = experiences;
storage.trained_models = trained_models;

try
    mkdirIfNotExist('./save/');
    save(sprintf('./save/intermediate_results_%s',filename),'-v7.3');
catch err
    showErrors(err);
%         save(sprintf('C:\Matlab_saves/log_%s',filename),'-v7.3');
end


