th = 10;
setting='unit10_slow';
unit = 10;
cap_w = unit;

% var_beta = (0.25).^2;
mean_beta = 0.25;
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