[val, agent_iter_max] =max(train_reward);
ID_mc1 = [1];
ID_mc2 = [2];
[K1,K2] = size(ID_mc2);

index_mc1 = 1;
index_mc2 = 2;
disp(sprintf('The policy table for machine ID %d Vs %d ',index_mc1,index_mc2));

if method==TYPE_METHOD.SAC_GRP_LOOKAHEAD 
    actor = getActor(agent);
    critics = getCritic(agent);
    actorNet = getModel(actor);
    th = 20;
    increment = 0.25; %0.1;
    state_comp_1 = [0:increment:th] ;
    state_comp_2 = [0:increment:th] ;
    [I1,J1] = size(state_comp_1);
    [I2,J2] = size(state_comp_2);

    state_1 = [];
    state_2 = [];
    action_mean = [];
    action_stdev = [];
    disp(sprintf('The policy table is calculating'));
    for i =1:J1
        for j=1:J2
            action = evaluate(actor,{[state_comp_1(i),state_comp_2(j)]});
            state_1 = [state_1 ,state_comp_1(i) ];
            state_2  =[state_2 ,state_comp_2(j)];
            action_mean = [action_mean,action(1)];
            action_stdev = [action_stdev ,action(2)];
        end
        fprintf('.');
        if rem(i*100/(J1-1),5) == 0
            fprintf('||');
        end
        if rem(i*100/(J1-1),50) == 0
            fprintf('\n');
        end
    end
    disp(sprintf('The policy table is done.'));
    state_1_mat = transpose(state_1);
    state_2_mat = transpose(state_2);
    action_mean_mat =  transpose(horzcat(action_mean{:}));
    action_stdev_mat =  transpose(horzcat(action_stdev{:}));
%     action_mean_mat =  vertcat(action_mean{:});  %2024
%     action_stdev_mat = vertcat(action_stdev{:});
    result = [state_1_mat state_2_mat action_mean_mat action_stdev_mat ];
elseif method==TYPE_METHOD.DQN
    th = 20;
    increment = 0.25; %0.1;
    state_comp_1 = [0:increment:th] ;
    state_comp_2 = [0:increment:th] ;
    [I1,J1] = size(state_comp_1);
    [I2,J2] = size(state_comp_2);
    
    state_1 = [];
    state_2 = [];
    action_binary = [];
    disp(sprintf('The policy table is calculating'));
    for i =1:J1
        for j=1:J2
            action = getAction(agent,{[state_comp_1(i),state_comp_2(j)]});
            state_1 = [state_1 ,state_comp_1(i) ];
            state_2  =[state_2 ,state_comp_2(j)];
            action_binary = [action_binary ,  action];
        end
        fprintf('.');
        if rem(i*100/(J1-1),5) == 0
            fprintf('||');
        end
        if rem(i*100/(J1-1),50) == 0
            fprintf('\n');
        end
    end
    disp(sprintf('The policy table is done.'));
    state_1_mat = transpose(state_1);
    state_2_mat = transpose(state_2);
    result = [state_1_mat state_2_mat vertcat(action_binary{:})];
else
    th = num_discretized_states;
    increment = 1; %0.1;
    state_comp_1 = [0:increment:th] ;
    state_comp_2 = [0:increment:th] ;
    [I1,J1] = size(state_comp_1);
    [I2,J2] = size(state_comp_2);
    
    state_1 = [];
    state_2 = [];
    action_binary = [];
    disp(sprintf('The policy table is calculating'));
    for i =1:J1
        for j=1:J2
            action = getAction(agent,{[state_comp_1(i),state_comp_2(j)]});
            state_1 = [state_1 ,state_comp_1(i) ];
            state_2  =[state_2 ,state_comp_2(j)];
            action_binary = [action_binary ,  action];
        end
        fprintf('.');
        if rem(i*100/(J1-1),5) == 0
            fprintf('||');
        end
        if rem(i*100/(J1-1),50) == 0
            fprintf('\n');
        end
    end
    disp(sprintf('The policy table is done.'));
    state_1_mat = transpose(state_1);
    state_2_mat = transpose(state_2);
    result = [state_1_mat state_2_mat vertcat(action_binary{:})];
end




