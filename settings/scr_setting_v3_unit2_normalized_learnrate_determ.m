th = 1;
setting='unit2_normalized';
unit = 2;
cap_w = unit;

% var_beta = (0.25).^2;
mean_beta = 1/20;
var_beta = (0.0000001).^2;
%% expected 1 cycle: 10. 
% var_pop = 0.01;
var_meas_err = (0.0000001).^2;
% Prior about beta
var_unit0 = var_beta;
mean_unit0 = mean_beta;

replace_cost = 5;   % Cost: Individual Maintenance 

% fix_main = 0;       % Cost: Setup
% fix_main = 10;    % Cost: Setup
% fix_main = 50;    % Cost: Setup
% fix_main = 200;   % Cost: Setup
% fix_main = 300;   % Cost: Setup

failure_cost = 300; % Cost: Corrective maintenace (Failure)

cost_w = 1;         % No effects
lost_demand = 100;  % No effects
demand = 1;
inspection_cost = 0;
learn_rate = 3e-4;

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

