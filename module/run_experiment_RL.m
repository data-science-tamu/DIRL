clc;clear all; close all;
param = RLParam();

%%----------------------------------------

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
verbose_training = false;
show_episode_manager = false;
% show_episode_manager = true;
show_progress = false;
% show_progress = true;
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
usegpu = false;
% usegpu = true;
useParallel = false;
% useParallel = true;

%% Option for neural net updating
updateFrequency = 1;

%% Option for environment
% unit = 20;
% th = 10;
% env = Maintenance(unit, th);
% nTrainingEpisodes = 10;
nSteps = 500; %% Simulation Horizon
nTrainingEpisodes = 100;
% num_training = 1000;
% num_test = 10;
num_test = 1000;




%% ---------------------
%% INPUT PARAMETERS
% scr_setting_v3_unit10_slow
param.th = 20;
param.setting='v3_unit10_';
param.unit = 5;
param.cap_w = unit;

% var_beta = (0.25).^2;
mean_beta = 1;
var_beta = (mean_beta/2).^2;
%% expected 1 cycle: 10. 

% Prior about beta
var_unit0 = var_beta;
mean_unit0 = mean_beta;

replace_cost = 5;
fix_main = 0; %th rocks
% fix_main = 10; %th rocks
% fix_main = 50; %th rocks
% fix_main = 200; %th rocks
% fix_main = 300; %th rocks
failure_cost = 300;
cost_w = 1;
lost_demand = 100;
demand = 1;
inspection_cost = 0;

% Expected lifetime of machines
% Degradation in [0,1]
% E[RUL] = 1/(beta*demand/unit*dt)
% E[RUL] = 1/(0.5*1/5*1): 10

param = Params_DRL(nSteps, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, cost_w, lost_demand, demand, inspection_cost, verbose, nTrainingEpisodes, num_test, num_discretized_states);
% env = Maintenance_real_reward_no_workload_assignment(param, unit, th, cap_w); fprintf('Maintenance_real_reward_no_workload_assignment\n');
% env = Maintenance_group_a_proportion_w_v3(param, unit, th, cap_w);
fprintf('noworkload=%d\n',noworkload);

%%----------------------------------------
fprintf('%s\n',setting);

prefix_filename='c0';

% nRepeats  = 100;
% lookahead = true;
% lookahead = false;

%% TEST
nRepeats  = 10;
discountFactor = 0.95;

type_methods = [...
    TYPE_METHOD.THRESHOLD ,...
    TYPE_METHOD.REGULAR ,...
    TYPE_METHOD.SAP_GRP, ...
    TYPE_METHOD.SAP_GRP_LOOKAHEAD, ...
    TYPE_METHOD.SAP_NOGRP ...
%     TYPE_METHOD.DQN ,...
%     TYPE_METHOD.DDQN ,...
%     TYPE_METHOD.QLEARNING ,...
%     TYPE_METHOD.SALSA ,...
%     TYPE_METHOD.THRESHOLD, ...
%     TYPE_METHOD.REGULAR, ...
%     TYPE_METHOD.SAP_GRP ...
    ];

fix_mains = [0,10,50,200,300]; %th rocks
% fix_main = 10; %th rocks
% fix_main = 50; %th rocks
% fix_main = 200; %th rocks
% fix_main = 300; %th rocks

settings
methods
nRepeats
runnable
prefix_filename
str_print

execute_multiple_experiments(setting, params, methods, nRepeats, runnable, prefix_filename, str_print);
