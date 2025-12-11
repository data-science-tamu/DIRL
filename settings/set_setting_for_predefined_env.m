base_niter=100;
base_niter = 2;
% type_methods = { ...
%     {TYPE_METHOD.TD3,2*base_niter} ...
%     {TYPE_METHOD.PPO_DACT,2*base_niter*12} ...
%     {TYPE_METHOD.AC_DACT,2*base_niter*12} ...
%     {TYPE_METHOD.PG_DACT,2*base_niter*15} ...
%     {TYPE_METHOD.DDQN ,2*base_niter*2} ... % Previously existing
%     {TYPE_METHOD.DQN ,2*base_niter*2} ... % Previously existing
%     {TYPE_METHOD.SAC_NOGRP, 100} ...
%     };
type_methods = [ ...
	TYPE_METHOD.TD3, ...
	TYPE_METHOD.PPO_DACT, ...
	TYPE_METHOD.AC_DACT, ...
	TYPE_METHOD.PG_DACT, ...
	TYPE_METHOD.DDQN , ... % Previously existing
	TYPE_METHOD.DQN , ... % Previously existing
	TYPE_METHOD.SAC_NOGRP, ...
	];

use_speicified_env = true;
% use_speicified_env = false;
specified_env = rlPredefinedEnv('CartPole-Continuous');
% % specified_env = rlPredefinedEnv('CartPole-Discrete');
prefix_filename=sprintf('test-CartPole-Continuous');


% nSteps = 50; %% Simulation Horizon
% nTrainingEpisodes = 100;
% nTrainingEpisodes = 2;

nSteps = 500; %% Simulation Horizon
nTrainingEpisodes = 1000;
% nTrainingEpisodes = 300;



% nTrainingEpisodes = 1000;
% num_training = 1000;
% num_test = 10;
% num_test = 1000;
num_test = 100;
