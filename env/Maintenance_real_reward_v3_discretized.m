classdef Maintenance_real_reward_v3_discretized < rl.env.MATLABEnvironment& Abs_Maintenance_env
    %MAINTENANCE: Template for defining custom environment in MATLAB.    
    
    %% Properties (set properties' attributes accordingly)
    properties
        % Specify and initialize environment's necessary properties    

%         verbose = false
        show_original_action = false;
        LARGE_NUMBER = 1000000; 
        verbose = true
        th_replace=0.5
        
        unit
        action_space_dim
        observation_space_dim
        threshold
        cap_w = 10
        var_pop = 0.01
%         state = this.reset()
        state
        dt = 1
        
        time_budget = 100;
        
        time
        
        var_beta = 0.01
        mean_beta = 0.5
        
        var_unit0 = 0.01    % Prior for beta
        mean_unit0 = 0.5    % Prior for beta
       
        
        sample_beta
        mean_unit2          % Posterior for beta
        var_unit2           % Posterior for beta    
        
        noworkload = false;
        totalrewards
        
        unboundedAgent
        agentUseDiscrete
        strictPenalty = false;
        addGroupVar = true;
        randomInit = false;
        noWorkloadState = false;
        num_states
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
        function this = Maintenance_real_reward_v3_discretized(param, unit, th, cap_w, noworkload, unboundedAgent, agentUseDiscrete, strictPenalty, addGroupVar, noWorkloadState, num_states)
            
%             this.unit = unit;
            if(nargin>4 && noworkload)
                if(addGroupVar)
                    action_space_dim = unit+1;
                else
                    action_space_dim = unit;
                end
            else
                if(addGroupVar)
                    action_space_dim = 2*unit+1; % if noworkload=1, unit+1, else, 2unit +1
                else
                    fprintf('ERROR: NOT IMPLEMENTED addGroupVar=false with workload\n');
                end
            end
            
%             action_space_dim = 2*unit+1;
%             end
            if(noWorkloadState)
                observation_space_dim = unit;
            else
                observation_space_dim = 2*unit;
            end
%             cap_w = 10;
            
            
%             [ObservationInfo,ActionInfo, this.state] = this.init();
%             ObservationInfo = cell(2,1);
%             states_cell = comb_state(repmat([0, 1], unit, 1));
            %% ----------------------- Finite obs
            fprintf('Start: creating states.\n');
            baseline = [0:num_states-1];;
            obsspace = baseline;
            for i=1:unit-1;
                obsspace = combvec(obsspace, baseline);
            end
            obsspace_cell = mat2cell(obsspace', ones(1,num_states^(unit)),unit);
            ObservationInfo = rlFiniteSetSpec(obsspace_cell);
            ObservationInfo.Name = sprintf('num of units:%d, num of states:%d', unit, num_states);
            fprintf('Done: creating states.\n');
%             ObservationInfo.Name = '1:unit = Degradation, unit+1:end = Cumulative Worload State';
            %% ----------------------- Finite obs

%             ObservationInfo = rlNumericSpec([1, observation_space_dim],'LowerLimit', 0, 'UpperLimit', 1);
            ObservationInfo.Name = '1:unit = Degradation, unit+1:end = Cumulative Worload State';
            %% -------------------------------------------------
%             ObservationInfo(1) = rlNumericSpec([1, unit],'LowerLimit', 0, 'UpperLimit', th);
%             ObservationInfo(1).Name = 'Degradation State';
%             ObservationInfo(2) = rlNumericSpec([1, unit],'LowerLimit', 0, 'UpperLimit', cap_w);
%             ObservationInfo(2).Name = 'Cumulative Worload State';
            
            
            % Initialize Action settings   
            if(agentUseDiscrete)
%                 ActionInfo = rlFiniteSetSpec([1, action_space_dim],'LowerLimit', 0, 'UpperLimit', 1);
%                 ActionInfo.Name = '1:unit = maintenace, unit+1 = whether maintain or not, unit+2:end = workload action, ';                
                actspace = [0 1];
                for i=1:unit;
                    actspace = combvec(actspace, [0 1]);
                end
                actspace_cell = mat2cell(actspace', ones(1,2^(unit+1)),unit+1);
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
            this.num_states = num_states;

            this.time = 0;
            this.unit = unit;
            this.cap_w = cap_w;
            this.totalrewards = 0;
            this.threshold = ones(1,unit)*th;
            this.init_state();
            %%
            this.time_budget = param.time_budget;
            this.var_beta = param.var_beta;
            this.mean_beta = param.mean_beta;

            this.var_unit0 = param.var_unit0;
            this.mean_unit0 = param.mean_unit0;

            this.replace_cost = param.replace_cost;
            this.fix_main = param.fix_main;
            this.failure_cost = param.failure_cost;
            this.cost_w = param.cost_w;
            this.lost_demand = param.lost_demand;
            this.demand = param.demand;
            this.inspection_cost = param.inspection_cost;
            this.verbose = param.verbose;

            % Initialize property values and pre-compute necessary values
%             updateActionInfo(this);
            this.reset();
        end
        
        function info(this)
            this.ActionInfo
            this.ObservationInfo
        end
        

        
        % Apply system dynamics and simulates the environment with the 
        % given action for one step.
        function replace_mc(this, idx_mc)
            this.sample_beta(idx_mc) = abs(normrnd(this.mean_beta, sqrt(this.var_beta)));
            this.mean_unit2(idx_mc) = this.mean_unit0;
            this.var_unit2(idx_mc) = this.var_unit0;
            
%             state = this.State;
            this.set_state_i(0, 0, idx_mc);
            
        end
        
        function replace = getReplaceAction(this, Action)
            if(this.addGroupVar)
                do_maintenance = Action(this.unit+1)>this.th_replace;
            else
                do_maintenance = true;
            end
            replace = (Action(1:this.unit)>this.th_replace) .* do_maintenance;
        end
        
        % Only if 1: replace
        function do_maintenance = getWhetherReplace(this, Action)
            if(this.addGroupVar)
                do_maintenance = Action(this.unit+1)>this.th_replace;
            else
                do_maintenance = 1;
            end
        end

        % Workload: Proportion.
        function workload = getWorkloadAction(this, Action)
%             workload = Action(this.unit+2:end)*this.cap_w;
% try
            if(this.noworkload)
                workload = ones(size(Action(1:this.unit))).* (this.demand * this.dt)./this.unit ;
            else
                if(sum(Action(this.unit+2:end),'all')>0)
                    workload = Action(this.unit+2:end)/sum(Action(this.unit+2:end),'all')*this.demand * this.dt;
                else
                    workload = Action(this.unit+2:end);
                end
            end
% catch err
%     disp(err);
% end
        end
        
        function [Observation, Reward, IsDone, LoggedSignals] = step(this,Action)

            if(this.verbose)
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
            
            workload = this.getWorkloadAction(Action);
            
            for i=1:this.unit
                if replace(i)==1
                    this.replace_mc(i)
                end
            end
            
            
            delta = this.sample_beta .*workload.* this.dt + normrnd(0, sqrt(this.var_pop * workload * this.dt), [1,this.unit] );
            degradation = (this.get_state_deg_vec() +delta);
            failure = degradation>=this.threshold;  %Units failure indicator (1:failed unit)
            this.set_state_deg_vec( degradation.*(1-failure))    % Final degradation values after actions

            
            
            
            % Update Variables
            this.set_state_cum_w_vec( (this.get_state_cum_w_vec() + this.dt * workload).*(1-failure) )
            this.mean_unit2 = (this.var_unit0.*degradation+this.var_pop.*this.mean_unit0)./(this.var_unit0.*this.get_state_cum_w_vec()+this.var_pop);
            this.var_unit2 = (this.var_unit0.*this.var_pop)./(this.var_unit0.*this.get_state_cum_w_vec()+this.var_pop);

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
            
            
            Observation = this.getObservations(this.State);
            
            LoggedSignals = [];
            
            Reward = this.getReward(failure, workload, replace);
%             Reward = Reward - this.getPenalty(Action);
            this.totalrewards = this.totalrewards + Reward;
            

            notifyEnvUpdated(this);
        end
        function [cost_obj, cost_actual] = getCost(this, failure, workload, replace)
            lost_dem_val = max(this.demand * this.dt-sum(workload)- 1e-10,0) ;
            mean_fu = this.get_state_deg_vec() + this.mean_unit2.*workload.*this.dt;
            try
                var_fu = ((workload.*this.dt).^2 .* this.var_unit2) + (workload*this.dt .* this.var_pop) + 1e-5 ; % To help convergence
            catch err
                disp(err)
            end

            cost_obj = sign(sum(replace))*this.fix_main+ ...
                sum(this.replace_cost*replace)+...      % Replace cost : sum individual
                 sum(this.cost_w.*workload)+...         % Workload cost : sum individual
                 this.lost_demand .* lost_dem_val+...   % Lost Demand cost : demand
                   sum(failure)*this.failure_cost*this.dt+... % Failure Cost
                   this.inspection_cost*this.unit ; % Insepction cost;default
               
           cost_actual = cost_obj;
               
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
            
            interval = 1./(this.num_states-2);
            obs = floor(states/interval)+1;

            obs(states<=0) = 0;
            obs(states>=1) = this.num_states-1;
            
            if(sum(obs<0,'all')>0 || sum(obs>=this.num_states,'all')>0)
                fprintf('warning\n');
            end
%             this.num_states
        end
        
        function penalty = getPenalty(this, Action)
            wheatherReplace = this.getWhetherReplace(Action);
            replaces = Action(1:this.unit);
            penalty = 0;
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
                state1 = zeros(1,this.unit);
                this.set_state(state1);
            else
                state1 = zeros(1,this.unit);
                state2 = zeros(1,this.unit);
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
                res = ones(1, this.unit);
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
            this.init_state();
            if(this.randomInit)
%             this.set_state(unifrnd(0,1,[1,this.unit]), unifrnd(0,1,[1,this.unit]));
            end
            
            
            InitialObservation = this.State;
            this.time = 0;
%             this.mean_unit1 = abs( normrnd(this.mean_unit0, sqrt(this.var_unit0)) );
            
            this.sample_beta = normrnd(this.mean_beta, sqrt(this.var_beta), [1,this.unit]);
            this.mean_unit2 = zeros(1,this.unit) * this.mean_beta;
            this.var_unit2 = zeros(1,this.unit) * this.var_beta;
            
            this.totalrewards = 0;
            
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
        function [reward, reward_actual] = getReward(this, failure, workload, replace)
            reward = -this.getCost(failure, workload, replace);
            reward_actual = reward;
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
