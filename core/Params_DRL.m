classdef Params_DRL
    %DRL_PARAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time_budget = 100;
        var_beta = (0.1).^2
        mean_beta = 0.5
        var_meas_err = 0.01;
        
        var_unit0 = (0.1).^2
        mean_unit0 = 0.5

        replace_cost = 5
        fix_main = 10
        failure_cost = 500
        cost_w = 1
        lost_demand = 100
        demand = 10
        inspection_cost = 0
        
        verbose = false;
        
        num_training = 0;
        num_test = 0;
        
        num_discretized_states = 5;
%         replace_cost = 5, fix_main = 100, failure_cost = 500, cost_w = 1, lost_demand = 200, demand = 10, inspection_cost = 0

    end
    
    methods
        function this = Params_DRL(time_budget, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, cost_w, lost_demand, demand, inspection_cost, verbose, num_training, num_test, num_discretized_states, var_meas_err)
            %DRL_PARAMS Construct an instance of this class
            %   Detailed explanation goes here
            this.time_budget = time_budget;
            this.var_beta = var_beta;
            this.mean_beta = mean_beta;

            this.var_unit0 = var_unit0;
            this.mean_unit0 = mean_unit0;

            this.replace_cost = replace_cost;
            this.fix_main = fix_main;
            this.failure_cost = failure_cost;
            this.cost_w = cost_w;
            this.lost_demand = lost_demand;
            this.demand = demand;
            this.inspection_cost = inspection_cost;
            this.verbose = verbose;
            this.var_meas_err = var_meas_err;
            
            if(exist('num_training','var'))
                this.num_training = num_training;
            end
            if(exist('num_test','var'))
                this.num_test = num_test;
            end
%             obj.Property1 = inputArg1 + inputArg2;
            if(exist('num_discretized_states','var'))
                this.num_discretized_states = num_discretized_states;
            end
        end
        
    end
end

