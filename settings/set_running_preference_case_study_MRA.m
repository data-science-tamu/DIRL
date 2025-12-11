
%% TRUE
noworkload = true; % For Action
noWorkloadState = true; % For State

%% VERBOSE
% verbose = true;
% show_every_rewards = true;
% verbose_training = true;
% show_episode_manager = true;

verbose = false;
show_every_rewards = false;
verbose_training = true;
show_episode_manager = false;
% show_episode_manager = true;
% show_progress = false;
show_progress = true;
% draw_plot_test_rewards = false;
draw_plot_test_rewards = true;
% draw_plot_training = false;
draw_plot_training = true;

%% For Agent with Continuous action 
unboundedAgent = true; % continuous action variable > binary variable

%% For Agent that can be both discrete/continuous
% agentCanUseDiscrete = true; %% Discrete Action Space
agentCanUseDiscrete = false;  %% Discrete Action Space

%% For Agent with discrete State
num_discretized_states = 5;
% nSteps = 10;

% %% Probably for Discrete State Agent
% num_states = 6;
% fprintf('#s: %d\n',num_states);
% % agentCanUseDiscrete = false;

% %% GROUP-INDUCING VARIABLE TO Action Space
% % addGroupVar = true;
% addGroupVar = false;

%% Penalty with Large Number to the CONFLICT between Group Variable & Individual Action Variables
% strictPenalty = true;
strictPenalty = false;


% show_optimal_value = false;
% % show_optimal_value = true;

%% Option for computing resource
% usegpu = false;
usegpu = true;
useParallel = false;
% useParallel = true;

%% Option for neural net updating
updateFrequency = 1;

%% Option for environment
% unit = 20;
% th = 10;
% env = Maintenance(unit, th);
% nTrainingEpisodes = 10;
nSteps = 10000; %5000; %500,10000; %% Simulation Horizon
% nTrainingEpisodes = 20;
nTrainingEpisodes = 1; %1000; %1000; %30 %100 %200
% nTrainingEpisodes = 300;
% nTrainingEpisodes = 1000;
% num_training = 1000;
% num_test = 10;
% num_test = 1000;
num_test = 500; %500

% comment this if you want to use default value. This is only for SAC
% learn_rate = 3e-4;

% apportion_workload_wrt_demand = false;
% apportion_workload_wrt_demand = true;

% param = Params_DRL(nSteps, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, cost_w, lost_demand, demand, inspection_cost, verbose, nTrainingEpisodes, num_test, num_discretized_states);
% env = Maintenance_real_reward_no_workload_assignment(param, unit, th, cap_w); fprintf('Maintenance_real_reward_no_workload_assignment\n');
% env = Maintenance_group_a_proportion_w_v3(param, unit, th, cap_w);
fprintf('noworkload=%d\n',noworkload);


% num_test = 5; %500
% nTrainingEpisodes = 3;
% nSteps = 200;