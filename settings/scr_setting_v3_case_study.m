% th = 25;
% th = 1;
unit = 2;
setting= sprintf('nunit=%d',unit);
cap_w = unit;
%Numerical setting 
mean_beta = 0.5;
var_beta = 0.00 ;  %0.04
var_meas_err = 1;
th = 20;


% % Case study setting
% mean_beta = 0.43;
% var_beta = 0.032 ;
% var_meas_err = 2.8;
% th = 20;

% mean_beta = 0.5;
% var_beta = 0.04 ;
% var_meas_err = 1;
% th = 20;

% mean_beta = 0.215;
% var_beta = 0.008 ;
% var_meas_err = 1.4;
% th = 25;

%% expected 1 cycle: 10. 

% Prior about beta
var_unit0 = var_beta;
mean_unit0 = mean_beta;


% fix_main = 0;       % Cost: Setup
% fix_main = 100;    % Cost: Setup
% fix_main = 50;    % Cost: Setup
fix_main = 250; %250;   % Cost: Setup
% fix_main = 300;   % Cost: Setup

replace_cost = 5;   % Cost: Individual Maintenance 
failure_cost = 1000; % Cost: Corrective maintenace (Failure)

cost_w = 1;         % No effects
lost_demand = 100;  % No effects
demand = 1;
inspection_cost = 0;
learn_rate = 3e-4;
% learn_rate = 1e-3;

% learn_rate = 5e-4;
% Expected lifetime of machines
% Degradation in [0,1]
% E[RUL] = 1/(beta*demand/unit*dt)
% E[RUL] = 1/(0.5*1/5*1): 10

%             cost_obj = sign(sum(replace))*this.fix_main+ ...
%                 sum(this.replace_cost*replace)+...      % Replace cost : sum individual
%                  sum(this.cost_w.*workload)+...         % Workload cost : sum individual
%                  this.lost_demand .* lost_dem_val+...   % Lost Demand cost : demand
%                 failure_cost+...
%                    this.inspection_cost*this.unit ; % Insepction cost;default
