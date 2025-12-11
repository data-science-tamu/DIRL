%Get actor to evaluate
actor = getActor(this);
actorNet = getModel(actor);
th = 20;%20
increment = 0.1; %0.01;
state_comp_1 = [0:increment:th] ;
state_comp_2 = [0:increment:th] ;
[I1,J1] = size(state_comp_1);
[I2,J2] = size(state_comp_2);

state_1 = [];
state_2 = [];
action_mean = [];
action_stdev = [];

for i =1:J1
    for j=1:J2
        action = evaluate(actor,{[state_comp_1(i),state_comp_2(j)]});
        state_1 = [state_1 ,state_comp_1(i) ];
        state_2  =[state_2 ,state_comp_2(j)];
        action_mean = [action_mean,action(1)];
        action_stdev = [action_stdev ,action(2)];
    end
    disp(sprintf('Done in %d from %d (%0.1f percent) ',i,J1,100*i/J1));
end

state_1_mat = transpose(state_1);
state_2_mat = transpose(state_2);
% action_mean_mat = transpose(cell2mat(action_mean));
% action_stdev_mat = transpose(cell2mat(action_stdev));
action_mean_mat = vertcat(action_mean{:});
action_stdev_mat = vertcat(action_stdev{:});
% action_mean_mat= vertcat(action_mean{:});
% action_stdev_mat = vertcat(action_stdev{:});
% record_name = './data_csv/SACLK-state_1_mat-J24-xx.csv';
% writematrix(state_1_mat,record_name);
% record_name = './data_csv/SACLK-state_2_mat-J24-xx.csv';
% writematrix(state_2_mat,record_name);
record_name = './data_csv/SACLK-action-mean-J24-x7.csv';
writematrix(action_mean_mat,record_name);
record_name = './data_csv/SACLK-action-stdev-J24-x7.csv';
writematrix(action_stdev_mat,record_name);