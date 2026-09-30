param_default = Params_DRL(nSteps, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, cost_w, lost_demand, demand, inspection_cost, verbose, nTrainingEpisodes, num_test, num_discretized_states, var_meas_err);

% num_parameters = 10;
num_parameters = 1;
cell_params = cell(1,num_parameters);
% initialization
for idx_params = 1:num_parameters
    cell_params{idx_params} = param_default;
end
