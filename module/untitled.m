
% nMethods = TYPE_METHOD.nMethods;
nMethods = numel(type_methods);
results = zeros(nRepeats, nMethods, num_test);
training_rewards = zeros(nRepeats, nMethods, nTrainingEpisodes);
experiences = cell(nRepeats, nMethods, num_test);
trained_models = cell(nRepeats, nMethods);

filename = sprintf('%s %s',prefix_filename, showPrettyDateTime(now(),'[yy-mm-dd_hh-MM-SS]'));
logger = Logger(sprintf('./log/%s.log',filename));
% logger = Logger();

logger.log(sprintf('RL starts at %s', showPrettyDateTime(now())));tic_all = tic();
% logger.log(sprintf('# Training= %d, # Testing = %d, # Steps =%d', nTrainingEpisodes, num_test, nSteps));
% logger.log(sprintf('Costs:C(replace)=%.2f, C(setup)=%.2f, C(fail)=%.2f, C(lostDemand)=%.2f', replace_cost, fix_main, failure_cost, lost_demand ));
% logger.log(sprintf('th=%.2f', th ));
% logger.log(sprintf('# Training=\t%d\t# Testing=\t%d\t# Steps=\t%d\tCosts:C(replace)=\t%.2f\tC(setup)=\t%.2f\tC(fail)=\t%.2f\tC(lostDemand)=\t%.2f\tth=\t%.2f\t', nTrainingEpisodes, num_test, nSteps, replace_cost, fix_main, failure_cost, lost_demand, th));
logger.log(sprintf('# Training=\t%d\t# Testing=\t%d\t# Steps=\t%d\tCosts:C(replace)=\t%.2f\tC(setup)=\t%.2f\tC(fail)=\t%.2f\tth=\t%.2f\t', nTrainingEpisodes, num_test, nSteps, replace_cost, fix_main, failure_cost, lost_demand, th));

logger.seperate('START RL');
cnt_exp = 0;
for idx_repeat = 1:nRepeats
    tic_rep = tic();
    for idx_method = 1:nMethods
        cnt_exp = cnt_exp+1;
    %% methods
%         method = TYPE_METHOD.getMethod(idx_method);
        method = type_methods(idx_method);
        logger.log(sprintf('Run: [%s] (Rep:%d/%d, Method:%d/%d) (%d/%d)', method, idx_repeat, nRepeats, idx_method, nMethods, cnt_exp, nRepeats*nMethods));
    %     method = TYPE_METHOD.SAP_GRP;
    %     method = TYPE_METHOD.REGULAR;
    %     disp(method)
        %% CREATE ENVIRONMENT
        tic_method = tic();
        if TYPE_METHOD.areStatesContinuous(method)
    %         env = Maintenance_real_reward_v3
            if method == TYPE_METHOD.SAP_GRP || method==TYPE_METHOD.SAP_GRP_LOOKAHEAD
                addGroupVar = true;
            elseif method == TYPE_METHOD.SAP_NOGRP
                addGroupVar = false;
            else
                addGroupVar = false;
            end
            discretize_states = false;
    %         env = Maintenance_real_reward_v3(param, unit, th, cap_w, noworkload, unboundedAgent, agentCanUseDiscrete, strictPenalty, addGroupVar, noWorkloadState);
        else
    %         env = Maintenance_real_reward_v3_discretized
    %         env = Maintenance_real_reward_v3_discretized(param, unit, th, cap_w, noworkload, unboundedAgent, agentCanUseDiscrete, strictPenalty, addGroupVar, noWorkloadState, num_states);
            discretize_states = true;
            addGroupVar = false;
        end

        agentCanUseDiscrete = ~TYPE_METHOD.hasContinuousActionSpace(method);

        if (method == TYPE_METHOD.THRESHOLD || method == TYPE_METHOD.REGULAR)
            show_progress_arg = false;
        else
            show_progress_arg = show_progress;
        end
        if(method==TYPE_METHOD.SAP_GRP_LOOKAHEAD)
            lookahead = true;
        else
            lookahead = false;
        end
        if(lookahead)
            logger.log(sprintf('> Lookahead'));
        else
            logger.log(sprintf('> No Lookahead'));
        end
        env = Maintenance_real_reward_v3_EXPECT_COST(param, unit, th, cap_w, noworkload, unboundedAgent, agentCanUseDiscrete, strictPenalty, addGroupVar, noWorkloadState, lookahead, show_every_rewards, discretize_states, show_progress_arg);

        obsInfo = getObservationInfo(env);
        actInfo = getActionInfo(env);

%         logger.log(sprintf(' - Method:[%s]', method));
        switch method
            case TYPE_METHOD.SAP_NOGRP
                agent = rlSACAgent(obsInfo,actInfo, rlSACAgentOptions('DiscountFactor',discountFactor) );
            case TYPE_METHOD.SAP_GRP
                agent = rlSACAgent(obsInfo,actInfo, rlSACAgentOptions('DiscountFactor',discountFactor) );
            case TYPE_METHOD.SAP_GRP_LOOKAHEAD
                agent = rlSACAgent(obsInfo,actInfo, rlSACAgentOptions('DiscountFactor',discountFactor) );
            case TYPE_METHOD.DDPG
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
                qTable = rlTable(obsInfo,actInfo);
                critic = rlQValueRepresentation(qTable,getObservationInfo(env),getActionInfo(env));
                opt = rlQAgentOptions;
                opt.EpsilonGreedyExploration.Epsilon = 0.05;
                opt.DiscountFactor = discountFactor;
                agent = rlQAgent(critic,opt);
            case TYPE_METHOD.SALSA
                qTable = rlTable(obsInfo,actInfo);
                critic = rlQValueRepresentation(qTable,getObservationInfo(env),getActionInfo(env));
                agent = rlSARSAAgent(critic,  rlSARSAAgentOptions('DiscountFactor',discountFactor ) );
            case TYPE_METHOD.REGULAR
                n_interval = 20; show_only_specific_interval = false; 
%                 scr_module_replace_regularly;
                %% SET Discount factor
                results(idx_repeat, idx_method, :) = regular_maintenance(param, env, unit, num_test, verbose, 20);
            case TYPE_METHOD.THRESHOLD
%                 n_grid = 500;
                n_grid = 100;
                %% SET Discount factor
                results(idx_repeat, idx_method, :) = threshold_maintenance(param, env, unit, num_test, show_progress_arg, n_grid);
            otherwise
                logger.warn(sprintf('[WARNING] Unsupported method:%s',method))
    %             
        end
    %% Train

        switch method
            case TYPE_METHOD.THRESHOLD
            case TYPE_METHOD.REGULAR
            otherwise

                trainOpts = rlTrainingOptions;
                if(useParallel)
                    trainOpts.UseParallel = true;
                end
                trainOpts.MaxEpisodes = nTrainingEpisodes;
                trainOpts.MaxStepsPerEpisode = nSteps;
                trainOpts.StopTrainingCriteria = "AverageReward";
                % trainOpts.StopTrainingValue = 500;
                trainOpts.ScoreAveragingWindowLength = 5;

                trainOpts.SaveAgentCriteria = "None";
                % trainOpts.SaveAgentCriteria = "EpisodeReward";
                % trainOpts.SaveAgentValue = 500;
                % trainOpts.SaveAgentDirectory = "savedAgents";

                trainOpts.Verbose = verbose_training;
                if(show_episode_manager)
                    trainOpts.Plots = "training-progress";
                else
                    trainOpts.Plots = "none";
                end
                % plot(env)
                if(show_progress_arg)
                    fprintf('Start:   Train  :')
                end
                trainingInfo = train(agent,env,trainOpts);
                trained_models{idx_repeat, idx_method} = trainingInfo;
                training_rewards(idx_repeat, idx_method,:) = trainingInfo.EpisodeReward;
                % fprintf('Done: T\n')

                % n_train=env.cnt_episode;
                % predict(trainingInfo, 
                % experiences = 
                %% ----------------------------------------------------
                if(show_progress_arg)
                    fprintf('Start: Vadlidate:')
                end
                for itest = 1:num_test
                    simOptions = rlSimulationOptions('MaxSteps',nSteps);
                    experience = sim(env, agent, simOptions);
                    experiences{idx_repeat, idx_method, itest} = experience;
                end
                results(idx_repeat, idx_method,:) = env.test_rewards_real;
        end
        logger.print(sprintf('\tTest Rewards:%.2f', mean(results(idx_repeat, idx_method, :))));
        toc_method =toc(tic_method);
        logger.log(sprintf('Elapsed Time (%s):%s',method,showPrettyElapsedTime(toc_method)));
        logger.seperate()
    % fprintf('Done: Validation\n')
    % bdclose(mdl)
    %% 
    % generatePolicyFunction(agent)
    %% Validate
    end
    logger.seperate('A Rep Ends')
    toc_rep = toc(tic_rep);
    logger.log(sprintf('Elapsed Time (One Repeat):%s',showPrettyElapsedTime(toc_rep)));
%     logger.log(sprintf('%s',getEstimatedRemainedTime(toc(tic_all), idx_repeat, nRepeats)));
%     logger.log(sprintf('%s',getEstimatedEndTime(toc(tic_all), idx_repeat, nRepeats)));
    logger.seperate()
    logger.seperate()
end
toc_all = toc(tic_all);
logger.log(sprintf('Elapsed Time (All):%s',showPrettyElapsedTime(toc_all)));
% showPrettyElapsedTime(toc_all);

storage.results = results;
storage.training_rewards = training_rewards;
storage.experiences = experiences;
storage.trained_models = trained_models;

try
    save(sprintf('./save/%s',filename),'-v7.3');
catch
    save(sprintf('C:\Matlab_saves/%s',filename),'-v7.3');
end
