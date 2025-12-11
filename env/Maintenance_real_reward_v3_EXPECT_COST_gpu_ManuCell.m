classdef Maintenance_real_reward_v3_EXPECT_COST_gpu_ManuCell < rl.env.MATLABEnvironment& Abs_Maintenance_env
    %MAINTENANCE: Template for defining custom environment in MATLAB.    
    
    %% Properties (set properties' attributes accordingly)
    properties
        % Specify and initialize environment's necessary properties    

        add_incentive = true;
        random_init_degrad = true;
        random_init_degrad_t0 = true; 
%         verbose = false
        show_original_action = false;
        LARGE_NUMBER = single(1000000); 
        verbose = true
        th_replace = single(0.5)
        
        unit
        action_space_dim
        observation_space_dim
        threshold
        cap_w = single(10)
        var_meas_err = single(0.01)
%         state = this.reset()
        state
        dt = single(1)
        
        time_budget = single(100);
        
        time
        
        var_beta = single(0.01)
        mean_beta = single(0.5)
        
        var_unit0 = single(0.01)    % Prior for beta
        mean_unit0 = single(0.5)    % Prior for beta

        throughput 
        max_cap
        cost_Lossthroughput 
       
        
        sample_beta
        mean_unit2          % Posterior for beta
        var_unit2           % Posterior for beta    
    
        %Declare variable for gamma
        mean_global 
        var_global 
        var_within_mc
        var_over_mc
        b 
        b_shape
        a_shape 
        sample_a
        lifetime_mc
        
        noworkload = false;
        
        unboundedAgent
        agentUseDiscrete
        strictPenalty = false;
        addGroupVar = true;
        randomInit = false;
        noWorkloadState = false;
        show_every_rewards = false;
        show_progress = true;
        
        num_training =single(0);
        num_test =single(0);
    
        degrad_record = single([]);

        cnt_episode = single(0);
        totalrewards = single(0);
        total_reward_actual = single(0);
        all_rewards = single([]);
        all_rewards_real =single([]);
        training_rewards = single([]);
        training_rewards_real = single([]);
        test_rewards = single([]);
        test_rewards_real =single([]);
        param

        tic_created
        
        discretize_states = false;
        num_discretized_states = 5;
%         replace_cost = 5, fix_main = 10, failure_cost = 500, cost_w = 1, lost_demand = 100, demand = 10, inspection_cost = 0
        replace_cost = 5, fix_main = 100, failure_cost = 500, cost_w = 1, lost_demand = 200, demand = 10, inspection_cost = 0
%         -------------------------------------------------
% 
%         % Acceleration due to gravity in m/s^2
%         Gravity = 9.8
%         
%         % Mass of the cart
%         CartMass = 1.0
%         
%         % Mass of the pole
%         PoleMass = 0.1
%         
%         % Half the length of the pole
%         HalfPoleLength = 0.5
%         
%         % Max Force the input can apply
%         MaxForce = 10
%                
%         % Sample time
%         Ts = 0.02
%         
%         % Angle at which to fail the episode (radians)
%         AngleThreshold = 12 * pi/180
%         
%         % Distance at which to fail the episode
%         DisplacementThreshold = 2.4
%         
%         % Reward each time step the cart-pole is balanced
%         RewardForNotFalling = 1
%         
%         % Penalty when the cart-pole fails to balance
%         PenaltyForFalling = -10 
    end
    
    properties
        % Initialize system state [x,dx,theta,dtheta]'
        State = [];
%         state1
%         state2
    end
    
    properties(Access = protected)
        % Initialize internal flag to indicate episode termination
        IsDone = false        
    end

    %% Necessary Methods
    methods              
        % Contructor method creates an instance of the environment
        % Change class name and constructor name accordingly
        function this = Maintenance_real_reward_v3_EXPECT_COST_gpu_ManuCell(param, unit, th, cap_w, noworkload, unboundedAgent, agentUseDiscrete, strictPenalty, addGroupVar, noWorkloadState, incentivized, show_every_rewards, discretize_states, show_progress,cellInfo)
            
%             this.unit = unit;
            if(nargin>4 && noworkload)
                if(addGroupVar)
                    action_space_dim = single(unit+1);
                else
                    action_space_dim = single(unit);
                end
            else
                if(addGroupVar)
                    action_space_dim = single(2*unit+1); % if noworkload=1, unit+1, else, 2unit +1
                else
                    fprintf('ERROR: NOT IMPLEMENTED addGroupVar=false with workload\n');
                end
            end
            
%             action_space_dim = 2*unit+1;
%             end
            if(noWorkloadState)
                observation_space_dim = single(unit);
            else
                observation_space_dim = single(2*unit);
            end
%             cap_w = 10;
            
            
%             [ObservationInfo,ActionInfo, this.state] = this.init();
%             ObservationInfo = cell(2,1);
%             states_cell = comb_state(repmat([0, 1], unit, 1));

            if(discretize_states)
                num_discretized_states = param.num_discretized_states;
                %% ----------------------- Finite obs
                fprintf('[Env] Start: creating states.');
                baseline = single([0:num_discretized_states-1]);
                obsspace = baseline;
                for i=1:unit-1;
                    obsspace = combvec(obsspace, baseline);
                end
                obsspace_cell = mat2cell(single(obsspace'), ones(1,num_discretized_states^(unit)),unit);
                ObservationInfo = rlFiniteSetSpec(obsspace_cell);
                ObservationInfo.Name = sprintf('num of units:%d, num of states:%d', unit, num_discretized_states);
                fprintf('Done.\n');
    %             ObservationInfo.Name = '1:unit = Degradation, unit+1:end = Cumulative Worload State';
                %% ----------------------- Finite obs                
            else
                ObservationInfo = rlNumericSpec([1, observation_space_dim],'LowerLimit', 0, 'UpperLimit', 1);
                ObservationInfo.Name = '1:unit = Degradation, unit+1:end = Cumulative Worload State';
            end
%             ObservationInfo(1) = rlNumericSpec([1, unit],'LowerLimit', 0, 'UpperLimit', th);
%             ObservationInfo(1).Name = 'Degradation State';
%             ObservationInfo(2) = rlNumericSpec([1, unit],'LowerLimit', 0, 'UpperLimit', cap_w);
%             ObservationInfo(2).Name = 'Cumulative Worload State';
            
            
            % Initialize Action settings   
            if(agentUseDiscrete)
%                 ActionInfo = rlFiniteSetSpec([1, action_space_dim],'LowerLimit', 0, 'UpperLimit', 1);
%                 ActionInfo.Name = '1:unit = maintenace, unit+1 = whether maintain or not, unit+2:end = workload action, ';                
                actspace = single([0 1]);
                for i=1:action_space_dim-1;
                    actspace = combvec(actspace, [0 1]);
                end
                actspace_cell = mat2cell(actspace', ones(1,2^(action_space_dim)),action_space_dim);
                ActionInfo = rlFiniteSetSpec(actspace_cell);
            else
                ActionInfo = rlNumericSpec([1, action_space_dim],'LowerLimit', 0, 'UpperLimit', 1);
                ActionInfo.Name = '1:unit = maintenace, unit+1 = whether maintain or not, unit+2:end = workload action, ';
            end
% %             ActionInfo = cell(2,1);
%             states_cell = comb_state(repmat([0, 1], unit, 1));
% %             ActionInfo(1) = rlFiniteSetSpec(states_cell);
%             ActionInfo(1) = rlNumericSpec([1, unit],'LowerLimit', 0, 'UpperLimit', 1);
%             ActionInfo(1).Name = 'Maintenance action';
%             ActionInfo(2) = rlNumericSpec([1, unit],'LowerLimit', 0, 'UpperLimit', cap_w);
%             ActionInfo(2).Name = 'Workload action';
            
            this = this@rl.env.MATLABEnvironment(ObservationInfo,ActionInfo);
            this.noworkload = noworkload;
            this.unboundedAgent = unboundedAgent;
            this.agentUseDiscrete = agentUseDiscrete;
            this.strictPenalty = strictPenalty;
            this.addGroupVar = addGroupVar;
            this.noWorkloadState = noWorkloadState;
            this.add_incentive = incentivized;
            this.show_every_rewards = show_every_rewards;
            this.discretize_states = discretize_states;
            this.num_discretized_states = param.num_discretized_states;
            this.show_progress = show_progress;

            this.time = single(0);
            this.unit = single(unit);
            this.cap_w = single(cap_w);
%             this.threshold = ones(1,unit)*th;
            this.threshold = single(th);
            %% Modification from cell manufacturing
            this.threshold = cell2mat(cellInfo.th);
            this.unit =length(cell2mat( cellInfo.thrput));
            %%----------------------------------------

            this.init_state();
            this.time_budget = single(param.time_budget);
            this.var_beta = single(param.var_beta);
            this.mean_beta = single(param.mean_beta);

            this.var_unit0 = single(param.var_unit0);
            this.mean_unit0 = single(param.mean_unit0);

            this.replace_cost = single(param.replace_cost);
            this.fix_main = single(param.fix_main);
            this.failure_cost = single(param.failure_cost);
            this.cost_w = single(param.cost_w);
            this.lost_demand = single(param.lost_demand);
            this.demand = single(param.demand);
            this.inspection_cost = single(param.inspection_cost);
            this.verbose = param.verbose;
            this.cnt_episode = single(1);
%             if(isfield(param,'num_training'))
            this.num_training = single(param.num_training);
%             end
            this.var_meas_err = param.var_meas_err;


            %% Modification from cell manufacturing
            this.threshold = cell2mat(cellInfo.th);

            this.mean_beta = cell2mat(cellInfo.mean_beta );
            this.var_beta = cell2mat(cellInfo.var_beta);
            this.var_meas_err = cell2mat(cellInfo.var_meas_err);
            this.var_unit0 = cell2mat(cellInfo.var_unit0);
            this.mean_unit0 = cell2mat(cellInfo.mean_unit0);
            this.replace_cost =  cell2mat(cellInfo.replace_cost);
            this.fix_main =  cell2mat(cellInfo.fix_cost);
            this.failure_cost = cell2mat(cellInfo.failure_cost);
            this.throughput = cellInfo.thrput;
            this.cost_Lossthroughput = cellInfo.lossThroughput_cost;
            
            %Find max capacity from throughput
            process_num = length(this.throughput);
            cap_per_process  = zeros(process_num,1);
            for i= 1:process_num 
                cap_per_process(i) = sum( this.throughput{i});
            end
            this.max_cap = min(cap_per_process);

            this.param = param;
%             if(isfield(param,'num_test'))
            this.totalrewards = single(0);

            this.num_test = single(param.num_test);
            this.all_rewards = single(zeros(this.num_training + param.num_test,1));
            this.all_rewards_real = single(zeros(this.num_training + param.num_test,1));
            this.training_rewards = single(zeros(this.num_training,1));
            this.training_rewards_real = single(zeros(this.num_training,1));
            this.test_rewards = single(zeros(param.num_test,1));
            this.test_rewards_real = single(zeros(param.num_test,1));

            this.tic_created = tic();
%             end

            % Initialize property values and pre-compute necessary values
%             updateActionInfo(this);
            this.reset();
        end

        function init_rewards(this)
            this.cnt_episode = single(1);
            this.totalrewards = single(0);
            this.total_reward_actual = single(0);
            this.all_rewards = single([]);
            this.all_rewards_real =single([]);
            this.training_rewards = single([]);
            this.training_rewards_real = single([]);
            this.test_rewards = single([]);
            this.test_rewards_real =single([]);
        end
        
        function info(this)
            this.ActionInfo
            this.ObservationInfo
        end
        

        
        % Apply system dynamics and simulates the environment with the 
        % given action for one step.
        function replace_mc(this, idx_mc)
            %Start modification here 
%             fprintf('New Machine is added at  %d \n',this.time)
            this.sample_beta(idx_mc) = abs(normrnd(this.mean_beta(idx_mc), sqrt(this.var_beta(idx_mc))));
%             fprintf('At step %d : The new beta is %7.2f \n' ,this.time ,this.sample_beta(idx_mc));
            this.mean_unit2(idx_mc) = this.mean_beta(idx_mc);
            this.var_unit2(idx_mc) = this.var_beta(idx_mc);
            this.lifetime_mc(idx_mc) = 0;
            this.lifetime_mc(idx_mc) = 0;

%             %GAMMA DISTRIBUTION
%             this.mean_global(idx_mc) = this.mean_beta ;
%             this.var_within_mc(idx_mc) = this.var_meas_err;
%             this.var_over_mc(idx_mc) = this.var_beta  ;
%             this.var_global(idx_mc) = this.var_beta + this.var_meas_err;
% 
%             this.b_shape(idx_mc) = -0.5 + sqrt(this.mean_global(idx_mc)^2+4*this.var_global(idx_mc)*this.var_over_mc(idx_mc))/(2*this.mean_global(idx_mc));
%             this.a_shape(idx_mc) =  this.var_over_mc(idx_mc)/(this.b_shape(idx_mc)^2);
%             this.sample_a(idx_mc) =  gamrnd(this.a_shape(idx_mc),this.b_shape(idx_mc));
%             this.b(idx_mc)= this.mean_global(idx_mc)/(this.a_shape(idx_mc)*this.b_shape(idx_mc));

%             %GAMMA DISTRIBUTION Given b_shape
%             this.b_shape(idx_mc) = 0.01 ;
%             this.a_shape(idx_mc) = (this.mean_global(idx_mc)^2)*(this.b_shape(idx_mc)+1)/(this.var_global(idx_mc)*this.b_shape(idx_mc));
%             this.sample_a(idx_mc) = gamrnd(this.a_shape(idx_mc),this.b_shape(idx_mc));
%             this.b(idx_mc) = this.var_global(idx_mc)/(this.mean_global(idx_mc)*(this.b_shape(idx_mc)+1)) ;

%             %GAMMA DISTRIBUTION Given b
%             this.b(idx_mc) = 0.01;
%             this.b_shape(idx_mc) = (this.var_global(idx_mc)/(this.b(idx_mc)*this.mean_global(idx_mc)))-1 ;
%             this.a_shape(idx_mc) = (this.mean_global(idx_mc)/this.b(idx_mc))/this.b_shape(idx_mc) ;
%             this.sample_a(idx_mc) = gamrnd(this.a_shape(idx_mc),this.b_shape(idx_mc));      

            %WEIBULL DISTRIBUTION
%             shape = 1;
%             this.a_0(idx_mc) = this.mean_unit0/gamma(1+(1/shape));
%             this.b_0(idx_mc) = shape;
%             this.a(idx_mc)= wblrnd(this.a_0(idx_mc),this.b_0(idx_mc));
%             this.b(idx_mc) = shape;
%             this.sample_beta(idx_mc) = wblrnd(this.a(idx_mc), this.b(idx_mc));
%             syms x y
%             eqns = [x *gamma(1+(1/y)) == this.mean_unit0, x*x*(gamma(1+(2/y))-gamma(1+(1/y))^2) == this.var_unit0];
%             vars = [x y];
%             [ans_a, ans_b] = solve(eqns,vars)
%             this.a_0(idx_mc) = ans_a
%             this.b_0(idx_mc) = ans_b
%             this.a(idx_mc)= wblrnd(this.a_0(idx_mc),this.b_0(idx_mc));
%             syms x y
%             eqns = [x *gamma(1+(1/y)) == this.mean_beta, x*x*(gamma(1+(2/y))-gamma(1+(1/y))^2) == this.var_beta];
%             vars = [x y];
%             [ans_a, ans_b] = solve(eqns,vars)
%             this.b(idx_mc) = ans_b;
%             this.sample_beta(idx_mc) = wblrnd(this.a(idx_mc), this.b(idx_mc));
            %WEIBULL DISTRIBUTION_v2            
%             shape = 1;
%             this.a_0(idx_mc) = this.mean_beta/gamma(1+(1/shape));
%             this.b_0(idx_mc) = shape;
%             this.sample_beta(idx_mc) = wblrnd(this.a_0(idx_mc), this.b_0(idx_mc));
%             this.mean_unit2(idx_mc) = this.mean_unit0;
%             this.var_unit2(idx_mc) =  this.var_unit0;

            
%             state = this.State;
            if this.random_init_degrad
                random_init_state = rand(1)*0.5*this.threshold(idx_mc);
                this.set_state_i(random_init_state, single(0), idx_mc);
            else
                this.set_state_i(single(0), single(0), idx_mc);
            end
        end
        
        function replace = getReplaceAction(this, Action)
            if(this.addGroupVar)
                do_maintenance = single(Action(this.unit+1)>this.th_replace);
            else
                do_maintenance = single(true);
            end
            replace = (Action(1:this.unit)>this.th_replace) .* do_maintenance;
        end
        
        % Only if 1: replace
        function do_maintenance = getWhetherReplace(this, Action)
            if(this.addGroupVar)
                do_maintenance = single(Action(this.unit+1)>this.th_replace);
            else
                do_maintenance = single(1);
            end
        end

        % Workload: Proportion.
        function workload = getWorkloadAction(this, Action)
%             workload = Action(this.unit+2:end)*this.cap_w;
% try
            if(this.noworkload)
                workload = single(ones(size(Action(1:this.unit))).* (this.demand * this.dt)./this.unit );
            else
                if(sum(Action(this.unit+2:end),'all')>0)
                    workload = single(Action(this.unit+2:end)/sum(Action(this.unit+2:end),'all')*this.demand * this.dt);
                else
                    workload = single(Action(this.unit+2:end));
                end
            end
% catch err
%     disp(err);
% end
        end
        
        function [Observation, Reward, IsDone, LoggedSignals] = step(this,Action)
            Action = single(Action);
            print_degrade = false;
            if(print_degrade)
                fprintf('[t=%3d: replace=%d] ',this.time, getWhetherReplace(this, Action));
%                 for i=1:this.unit
                if(this.show_original_action)
                    fprintf('%.2f ',Action(1:this.unit))
                    fprintf('%.2f ',Action(this.unit+2:end))
                else
                    fprintf('%d ',this.getReplaceAction(Action))
%                     fprintf('%.2f ',Action(this.unit+2:end))
                    fprintf('||[Deg]');
                    fprintf('%.2f ',this.State(1:this.unit));
                end
%                 end
                fprintf('\n');
            end
            
            if(this.unboundedAgent)
                Action=(Action>this.th_replace);
            end
            
            this.time = this.time + 1;
            IsDone = false;
            if this.time >= this.time_budget;
                IsDone = true;
            end
            this.IsDone = IsDone;
            
            replace = this.getReplaceAction(Action);
            
%             if(this.verbose)
%                 fprintf('[t=%3d: replace=%d] ',this.time, getWhetherReplace(this, Action));
%                 for i=1:this.unit
%                     fprintf('%d ',replace(i))
%                 end
%                 fprintf('\n');
%             end
            
%             workload = this.getWorkloadAction(Action);
            
            for i=1:this.unit
                if replace(i)==1
                    this.replace_mc(i)
                end
            end
            
            
%             delta = this.sample_beta .*workload.* this.dt + normrnd(0, sqrt(this.var_meas_err * workload * this.dt), [1,this.unit] );
            
            %Without workload : NORMAL
            delta = this.sample_beta.* this.dt + normrnd(0, sqrt(this.var_meas_err * this.dt), [1,this.unit] );
            this.lifetime_mc = this.lifetime_mc + 1;
%             %GAMMA 
%              delta = gamrnd(this.sample_a ,this.b, [1,this.unit]);
            
            
            degradation = (this.get_state_deg_vec() +delta);
            this.degrad_record = (this.get_state_deg_vec() +delta);

            failure = degradation>=this.threshold;  %Units failure indicator (1:failed unit)
            %Print- Added 
%             fprintf('Current step is  %d \n',this.time)
%             fprintf('This sample beta is %.2f \n',this.sample_beta)
%             fprintf('The delta is %.2f \n',delta)
%             fprintf('Current degradation is %.2f and threshold %.2f \n',degradation,this.threshold)
%             fprintf('lifetime_mc is %d \n',this.lifetime_mc)


            this.set_state_deg_vec( degradation.*(1-failure))    % Final degradation values after actions

            
            
            
            % Update Variables
%             this.set_state_cum_w_vec( (this.get_state_cum_w_vec() + this.dt * workload).*(1-failure) )
            %Modify by add mean0 and var0 update
%             this.mean_unit2 = (this.var_unit0.*degradation+this.var_meas_err.*this.mean_unit0)./(this.var_unit0.*this.get_state_cum_w_vec()+this.var_meas_err);
%             this.var_unit2 = (this.var_unit0.*this.var_meas_err)./(this.var_unit0.*this.get_state_cum_w_vec()+this.var_meas_err);
%             this.mean_unit0 = this.mean_unit2;
%             this.var_unit0 = this.var_unit2;
            %Added 
            this.mean_unit2 = (this.var_unit0.*degradation+this.var_meas_err.*this.mean_unit0)./(this.var_unit0.*this.lifetime_mc+this.var_meas_err);
            this.var_unit2 = (this.var_unit0.*this.var_meas_err)./(this.var_unit0.*this.lifetime_mc+this.var_meas_err);
            %Print- Added 
%             fprintf('Current mean2 is %.2f and variance2 is %.4f \n',this.mean_unit2,this.var_unit2)

            % Failure Adjustment
            for i= 1:this.unit
                if failure(i) == 1
                    this.replace_mc(i);
%                     this.mean_unit1(i) = abs(normrnd(this.mean_unit0, sqrt(this.var_unit0))) ;
%                     this.mean_unit2(i) = this.mean_unit0;
%                     this.var_unit2(i) = this.var_unit0;
                    % this.state[this.unit+i] = 0
                end
            end

            if(sum(Action>1)>0 || sum(Action<0)>0)
                fprintf('[WARNING: Action >1 or <0]');
                fprintf('[t=%3d: replace=%d] ',this.time, getWhetherReplace(this, Action));
%                 for i=1:this.unit
                fprintf('%.2f ',Action(1:this.unit))
                fprintf('%.2f ',Action(this.unit+2:end))
                
                fprintf('||[Deg]');
                fprintf('%.2f ',this.State(1:this.unit));
%                 end
                fprintf('\n');
            end
            
%             Observation = this.State;
            Observation = this.getObservations(this.State);
            
            LoggedSignals = [];
            
            [Reward, reward_actual] = this.getReward_without_workload(failure, replace);
%             [Reward, reward_actual] = this.getReward(failure, workload, replace);
%             Reward = Reward - this.getPenalty(Action);
            this.totalrewards = this.totalrewards + Reward;
            this.total_reward_actual = this.total_reward_actual + reward_actual;
            
            if(this.IsDone)
                this.save_rewards()
            end

            notifyEnvUpdated(this);
         end

             %% Cost function
            function [cost_obj, cost_actual] = getCost_without_workload(this, failure, replace)
%             lost_dem_val = max(this.demand * this.dt-sum(workload)- single(1e-10),0) ;
            mean_fu = this.get_state_deg_vec() + this.mean_unit2.*this.dt;
            try
                var_fu = ((this.dt).^2 .* this.var_unit2) + (this.dt .* this.var_meas_err) + 1e-5 ; % To help convergence
            catch err
                disp(err)
            end

            if(this.add_incentive)
                failure_cost = sum( (1-normcdf(-((mean_fu-this.threshold)./sqrt(var_fu)), 0, 1)) .*this.failure_cost).*this.dt;
%                 %Print- Added 
%                 fprintf('Mean_fu=  %.4f , Var_fu = %.4f , Threshold = %.4f  \n',mean_fu,var_fu,this.threshold)
%                 fprintf('Failure prop is %.4f \n',1-normcdf(-((mean_fu-this.threshold)./sqrt(var_fu)), 0, 1))
%                 fprintf('Failure cost = %.4f  \n',failure_cost);
            else
                failure_cost = sum(failure.*this.failure_cost.*this.dt); % Failure Cost
            end
            
            %% Old cost structure normal set up  ---------
           %  cost_obj = sign(sum(replace))*this.fix_main+ ...
           %      sum(this.replace_cost*replace)+...      % Replace cost : sum individual
           %      failure_cost;
           % 
           % 
           % cost_actual = sign(sum(replace))*this.fix_main+ ...
           %      sum(this.replace_cost*replace)+...      % Replace cost : sum individual
           %         sum(failure)*this.failure_cost*this.dt; % Failure Cost
            
           %% New cost structure normal set up  ---------
           actual_cap = this.throughput;
           process_num = length(actual_cap);
           cap_per_process  = zeros(process_num,1);
           run_component_id = 1;
           for i= 1:process_num
               num_comp_per_process = length(actual_cap{i});
               nonreplacement_decision = abs(1-replace(run_component_id:(run_component_id+num_comp_per_process-1)));
               actual_cap_per_process = actual_cap{i} .* nonreplacement_decision;
               cap_per_process(i) = sum( actual_cap_per_process);
               run_component_id = run_component_id + num_comp_per_process;
           end
           actual_thrput = min(cap_per_process);

           loss_thrput = this.max_cap - actual_thrput ;
            cost_obj = loss_thrput *this.cost_Lossthroughput+ ...
                sum(this.replace_cost.*replace)+...      % Replace cost : sum individual
                failure_cost;
               
               
           cost_actual = loss_thrput * this.cost_Lossthroughput+ ...
                sum(this.replace_cost.*replace)+...      % Replace cost : sum individual
                   sum(failure.*this.failure_cost.*this.dt); % Failure Cost

           cost_obj = single(cost_obj);
           cost_actual = single(cost_actual);
%            %Print- Added 
%            fprintf('Decision: replace=  %.2f , failure = %.2f \n', replace,failure)
%            fprintf('Cost obj=  %.2f , Cost actual = %.2f \n\n', cost_obj,cost_actual)
               
%         lost_dem_val = max(demand*self.dt-np.sum(workload),0)
%         mean_fu = self.state[:self.unit] + self.mean_unit2*workload*self.dt
%         var_fu = np.multiply(np.square(workload*self.dt), self.var_unit2) + np.multiply(workload*self.dt, self.var_pop) + 1e-5 # To help convergence
% 
%         cost = np.sign(np.sum(replace))*fix_main+np.sum(replace_cost*replace)+\
%              np.sum(cost_w*workload)+\
%              lost_demand*lost_dem_val+\
%                np.sum((1-norm.cdf(-np.divide((mean_fu-self.threshold), np.sqrt(var_fu))))*failure_cost)*self.dt+\
%                inspection_cost*self.unit
               
        end
        function [cost_obj, cost_actual] = getCost(this, failure, workload, replace)
            lost_dem_val = max(this.demand * this.dt-sum(workload)- single(1e-10),0) ;
            mean_fu = this.get_state_deg_vec() + this.mean_unit2.*workload.*this.dt;
            try
                var_fu = ((workload.*this.dt).^2 .* this.var_unit2) + (workload*this.dt .* this.var_meas_err) + 1e-5 ; % To help convergence
            catch err
                disp(err)
            end

            if(this.add_incentive)
                failure_cost = sum( (1-normcdf(-((mean_fu-this.threshold)./sqrt(var_fu)), 0, 1)) .*this.failure_cost).*this.dt;
            else
                failure_cost = sum(failure)*this.failure_cost*this.dt; % Failure Cost
            end
            
            cost_obj = sign(sum(replace))*this.fix_main+ ...
                sum(this.replace_cost*replace)+...      % Replace cost : sum individual
                 sum(this.cost_w.*workload)+...         % Workload cost : sum individual
                 this.lost_demand .* lost_dem_val+...   % Lost Demand cost : demand
                failure_cost+...
                   this.inspection_cost*this.unit ; % Insepction cost;default
               
           cost_actual = sign(sum(replace))*this.fix_main+ ...
                sum(this.replace_cost*replace)+...      % Replace cost : sum individual
                 sum(this.cost_w.*workload)+...         % Workload cost : sum individual
                 this.lost_demand .* lost_dem_val+...   % Lost Demand cost : demand
                   sum(failure)*this.failure_cost*this.dt+... % Failure Cost
                   this.inspection_cost*this.unit ; % Insepction cost;default;
           cost_obj = single(cost_obj);
           cost_actual = single(cost_actual);
               
%         lost_dem_val = max(demand*self.dt-np.sum(workload),0)
%         mean_fu = self.state[:self.unit] + self.mean_unit2*workload*self.dt
%         var_fu = np.multiply(np.square(workload*self.dt), self.var_unit2) + np.multiply(workload*self.dt, self.var_pop) + 1e-5 # To help convergence
% 
%         cost = np.sign(np.sum(replace))*fix_main+np.sum(replace_cost*replace)+\
%              np.sum(cost_w*workload)+\
%              lost_demand*lost_dem_val+\
%                np.sum((1-norm.cdf(-np.divide((mean_fu-self.threshold), np.sqrt(var_fu))))*failure_cost)*self.dt+\
%                inspection_cost*self.unit
               
        end

        function obs = getObservations(this, states)
%             obs =zeros(size(states));
            if(this.discretize_states)
                interval = single(1./(this.num_discretized_states-2));
                obs = single(floor(states/interval)+1);

                obs(states<=0) = single(0);
                obs(states>=1) = single(this.num_discretized_states-1);

                if(sum(obs<0,'all')>0 || sum(obs>=this.num_discretized_states,'all')>0)
                    fprintf('[warning]\n');
                end
            else
                obs = states;
            end
%             this.num_discretized_states
        end
        
        function penalty = getPenalty(this, Action)
            wheatherReplace = this.getWhetherReplace(Action);
            replaces = Action(1:this.unit);
            penalty = single(0);
            if(this.addGroupVar)
                if (~wheatherReplace)
                    if(sum(replaces,'all')>0)
                        penalty = this.LARGE_NUMBER;
                    end
                end

                if(this.strictPenalty)
                    if (wheatherReplace)
                        if(sum(replaces,'all')==0)
                            penalty = this.LARGE_NUMBER;
                        end
                    end
                end

                if(sum(this.getWorkloadAction(Action))==0)
                    penalty = penalty + this.LARGE_NUMBER;
                end
            end
        end
        
        function init_state(this)
            if(this.noWorkloadState)
                if this.random_init_degrad_t0
                    state1 = unifrnd(0,1,[1,this.unit])* 0.5 .* this.threshold;
                    this.set_state(state1);
                else
                    state1 = single(zeros(1,this.unit));
                    this.set_state(state1);
                end
            else
                state1 = single(zeros(1,this.unit));
                state2 = single(zeros(1,this.unit));
    %             InitialObservation = {state1, state2};
                this.set_state(state1, state2);
            end
        end
        
        function set_state_deg_vec(this, deg_state_vec)
%             set_observation = [deg_state_vec, this.get_state_cum_w_vec()];            
            this.set_state(deg_state_vec, this.get_state_cum_w_vec() );
%             this.State = set_observation;
        end
        
        function set_state_cum_w_vec(this, cum_w_vec)
%             set_observation = [this.get_state_deg_vec(), cum_w_vec];            
            this.set_state(this.get_state_deg_vec(), cum_w_vec );
%             this.State = set_observation;
        end

        %% SCALE THE STATES
        function set_state(this, deg_state, cum_w_state)
            if(this.noWorkloadState)
                this.State = deg_state;
            else
                set_observation = [deg_state, cum_w_state];            
                this.State = set_observation;
            end
%             this.state1 = deg_state;
%             this.state2 = cum_w_state;
            notifyEnvUpdated(this);
        end
        
        function res = get_state_deg_vec(this)
%             res = this.State(1);
            res = this.State(1:this.unit);
        end
        
        function res = get_state_cum_w_vec(this)
%             res = this.State(2);
            if(this.noWorkloadState)
                res = single(ones(1, this.unit));
            else
                res = this.State(this.unit+1:end);
            end
        end
        

        function set_state_i(this, deg, cum_w, i)
%             sel_state = this.State ;
            if(this.noWorkloadState)
                deg_state = this.get_state_deg_vec();
                deg_state(i) = deg;

                this.set_state(deg_state);
            else
                deg_state = this.get_state_deg_vec();
                cum_w_state = this.get_state_cum_w_vec();
                deg_state(i) = deg;
                cum_w_state(i) = cum_w;

                this.set_state(deg_state, cum_w_state);
            end
        end
        
        function save_rewards(this)
%             this.cnt_episode = this.cnt_episode+1;
            idx = this.cnt_episode;
%             fprintf('%d\n',idx)
            
            this.all_rewards(idx) = this.totalrewards;
            this.all_rewards_real(idx) = this.total_reward_actual;
            
            if(idx>this.num_training)
                this.test_rewards(idx-this.num_training) = this.totalrewards;
                this.test_rewards_real(idx-this.num_training) = this.total_reward_actual;
            else
                this.training_rewards(idx) = this.totalrewards;
                this.training_rewards_real(idx) = this.total_reward_actual;                
            end
%             if(~this.show_every_rewards && ~this.verbose)
%                 fprintf('.');
%             end
            if(idx>this.num_training + this.num_test)
                fprintf('WARNING: SOMETHING IS WRONG: env save count went above the needed steps.');
            end
            if(this.show_progress)
                if(this.num_training>0 && idx<=this.num_training )
                    if(mod(idx, floor((this.num_training)/100))==0)
                        if(idx == floor((this.num_training)/100))
                            fprintf('Estimated End Time (Training):%s (Remaining:%s)\n',getEstimatedEndTime(toc(this.tic_created),idx,this.num_training), getEstimatedRemainedTime(toc(this.tic_created), idx, this.num_training));
%     logger.log(sprintf('%s',getEstimatedRemainedTime(toc(tic_all), idx_repeat, nRepeats)));
%     logger.log(sprintf('%s',getEstimatedEndTime(toc(tic_all), idx_repeat, nRepeats)));                            
                        end
                        fprintf('.');
    %                 elseif(mod(idx, floor((this.num_training)/5))==0)
    %                     fprintf('|');
                    end
                    if(mod(idx, floor((this.num_training)/10))==0)
                        fprintf('|%d|',floor(idx./floor((this.num_training)/10)));
    %                 elseif(mod(idx, floor((this.num_training)/5))==0)
    %                     fprintf('|');
                        if(idx == floor((this.num_training)/10*5))
                            fprintf('\n'); %% For narrow screen
                        end
                    end
                end
                if(this.num_test>0 && this.num_training>0 && idx>this.num_training)
                    if(mod(idx-this.num_training, floor((this.num_test)/100))==0)
                        fprintf('.');
    %                 elseif(mod(idx-this.num_training, floor((this.num_test)/5))==0)
    %                     fprintf('|');
                    end
                    if(mod(idx-this.num_training, floor((this.num_test)/10))==0)
                        fprintf('|%d|',floor((idx-this.num_training)./floor((this.num_test)/10)));
    %                 elseif(mod(idx-this.num_training, floor((this.num_test)/5))==0)
    %                     fprintf('|');
                        if(idx-this.num_training == floor((this.num_test)/10*5))
                            fprintf('\n'); %% For narrow screen
                        end
                    end
                end
                if(this.num_training==idx)
                    fprintf('\n');
                end
                if(this.num_training + this.num_test==idx)
                    fprintf('\n');
                end
            end
        end
        
        % Reset environment to initial state and output initial observation
        function InitialObservation = reset(this)
%             % Theta (+- .05 rad)
%             T0 = 2 * 0.05 * rand - 0.05;  
%             % Thetadot
%             Td0 = 0;
%             % X 
%             X0 = 0;
%             % Xdot
%             Xd0 = 0;
%             
%             InitialObservation = [T0;Td0;X0;Xd0];

            if(this.time>0)
                this.cnt_episode = this.cnt_episode+1;
            end
            % If not saved until the steps are not satisfied.
            if(~this.IsDone && this.time>0)
                this.save_rewards()
            end

            this.init_state();
            if(this.randomInit)
%             this.set_state(unifrnd(0,1,[1,this.unit]), unifrnd(0,1,[1,this.unit]));
            end
            
            if(this.show_every_rewards)
                fprintf('%.0f (%.2f)\n', this.total_reward_actual, this.totalrewards);
            end
            
            InitialObservation = this.State;
            this.time = 0;
            this.IsDone = false;
%             this.mean_unit1 = abs( normrnd(this.mean_unit0, sqrt(this.var_unit0)) );

%             %ORIGINAL
%             this.sample_beta = normrnd(this.mean_beta, sqrt(this.var_beta), [1,this.unit]);
%             this.mean_unit2 = zeros(1,this.unit) * this.mean_beta;
%             this.var_unit2 = zeros(1,this.unit) * this.var_beta;

          %NORMAL DISTRIBUTION
            this.sample_beta = abs(normrnd(this.mean_beta, sqrt(this.var_beta)));
%             fprintf('The initial beta is %7.2f \n' , this.sample_beta);
            this.mean_unit2 = this.mean_beta;
            this.var_unit2 = this.var_beta;
            this.lifetime_mc = zeros(1,this.unit) ;

%             %GAMMA DISTRIBUTION
%             this.mean_global = ones(1,this.unit) * this.mean_beta ;
%             this.var_within_mc = ones(1,this.unit) * this.var_meas_err;
%             this.var_over_mc = ones(1,this.unit) * this.var_beta  ;
%             this.var_global = ones(1,this.unit) * (this.var_beta + this.var_meas_err);
% 
%             this.b_shape = (ones(1,this.unit) * (-0.5)) + sqrt(this.mean_global.^2 + (4 * this.var_global) .*this.var_over_mc)/(2*this.mean_global);
%             this.a_shape =  this.var_over_mc/(this.b_shape.^2);
%             this.sample_a =  gamrnd(this.a_shape,this.b_shape, [1,this.unit]);
%             this.b = this.mean_global ./(this.a_shape .* this.b_shape);

%             %GAMMA DISTRIBUTION Given b_shape
%             this.b_shape = ones(1,this.unit) *0.01 ;
%             this.a_shape= (this.mean_global .* this.mean_global).*(this.b_shape+1)/(this.var_global.*this.b_shape);
%             this.sample_a = gamrnd(this.a_shape,this.b_shape, [1,this.unit]);
%             this.b = this.var_global ./ (this.mean_global.*(this.b_shape+1)) ;
%             
%             %GAMMA DISTRIBUTION Given b
%             this.b= ones(1,this.unit) *0.01;
%             this.b_shape = (this.var_global ./ (this.b .* this.mean_global))-1 ;
%             this.a_shape = (this.mean_global ./ this.b) ./ this.b_shape ;
%             this.sample_a = gamrnd(this.a_shape,this.b_shape, [1,this.unit]);


            this.totalrewards = 0;
            this.total_reward_actual = 0;
            % (optional) use notifyEnvUpdated to signal that the 
            % environment has been updated (e.g. to update visualization)
            notifyEnvUpdated(this);
        end
        

    end
    %% Optional Methods (set methods' attributes accordingly)
    methods               
        % update the action info based on max force
        function updateActionInfo(this)
%             this.ActionInfo.Elements = this.MaxForce*[-1 1];
        end
        
        % Reward function
        function [reward, reward_actual] = getReward_without_workload(this, failure, replace)
%             [cost, cost_actual] = this.getCost(failure, workload, replace);
            [cost, cost_actual] = this.getCost_without_workload(failure, replace);
            
            reward = -cost;
            reward_actual = -cost_actual;
%             reward_actual = reward;
        end
        function [reward, reward_actual] = getReward(this, failure, workload, replace)
            [cost, cost_actual] = this.getCost(failure, workload, replace);
%             [cost, cost_actual] = this.getCost_without_workload(failure, replace);
            
            reward = -cost;
            reward_actual = -cost_actual;
%             reward_actual = reward;
        end
        

        
        
        function res = getObservationInfo(this)
            res = this.ObservationInfo;
        end
        
        function res = getActionInfo(this)
            res = this.ActionInfo;
        end
        
        % (optional) Visualization method
        function plot(this)
            % Initiate the visualization
            
            % Update the visualization
            envUpdatedCallback(this)
        end
        
        % (optional) Properties validation through set methods
        function set.State(this,state)
%             validateattributes(state(1),{'numeric'},{'finite','real','vector','numel',this.unit},'','State');
%             validateattributes(state(2),{'numeric'},{'finite','real','vector','numel',this.unit},'','State');
try
    if(this.noWorkloadState)
            validateattributes(state,{'numeric'},{'finite','real','vector','numel',this.unit},'','State');
    else
            validateattributes(state,{'numeric'},{'finite','real','vector','numel',this.unit*2},'','State');
    end
catch ex
    showErrors(ex);
end
%             this.State = double(state(:));
            this.State=state;
            notifyEnvUpdated(this);
        end
%         function set.HalfPoleLength(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','HalfPoleLength');
%             this.HalfPoleLength = val;
%             notifyEnvUpdated(this);
%         end
%         function set.Gravity(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','Gravity');
%             this.Gravity = val;
%         end
%         function set.CartMass(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','CartMass');
%             this.CartMass = val;
%         end
%         function set.PoleMass(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','PoleMass');
%             this.PoleMass = val;
%         end
%         function set.MaxForce(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','MaxForce');
%             this.MaxForce = val;
%             updateActionInfo(this);
%         end
%         function set.Ts(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','Ts');
%             this.Ts = val;
%         end
%         function set.AngleThreshold(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','AngleThreshold');
%             this.AngleThreshold = val;
%         end
%         function set.DisplacementThreshold(this,val)
%             validateattributes(val,{'numeric'},{'finite','real','positive','scalar'},'','DisplacementThreshold');
%             this.DisplacementThreshold = val;
%         end
%         function set.RewardForNotFalling(this,val)
%             validateattributes(val,{'numeric'},{'real','finite','scalar'},'','RewardForNotFalling');
%             this.RewardForNotFalling = val;
%         end
%         function set.PenaltyForFalling(this,val)
%             validateattributes(val,{'numeric'},{'real','finite','scalar'},'','PenaltyForFalling');
%             this.PenaltyForFalling = val;
%         end
    end
    
    methods (Access = protected)
        % (optional) update visualization everytime the environment is updated 
        % (notifyEnvUpdated is called)
        function envUpdatedCallback(this)
            totalrewards = this.totalrewards;
%             N = numel(totalrewards);
%             running_avg = zeros(1,N);
%             for t =1:N
%                 running_avg(t) = mean(totalrewards(max(1, t-50):t)  );
%             end
%             figure(1);clf;
%             plot(running_avg);
%             title("Running Average")

            
%           N = len(totalrewards)
%           running_avg = np.empty(N)
%           for t in range(N):
%             running_avg[t] = totalrewards[max(0, t-50):(t+1)].mean()
%           plt.plot(running_avg)
%           plt.title("Running Average")
%           plt.show()
        end
    end
end
