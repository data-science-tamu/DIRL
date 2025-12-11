% Clear enviroments
clc;
clear all; 
close all;
warning('off')

%% Define setting
methodList = [[TYPE_METHOD.SAC_GRP_LOOKAHEAD],[TYPE_METHOD.SAC_NOGRP],[TYPE_METHOD.PPO_CACT],[TYPE_METHOD.TRPO_CACT_CSTA],[TYPE_METHOD.DDPG],[TYPE_METHOD.THRESHOLD_2TH],[TYPE_METHOD.THRESHOLD],[TYPE_METHOD.PERIODICAL],[TYPE_METHOD.DO_NOTHING],[TYPE_METHOD.MAINTAIN_EVERYTIME]];

%% Environment
env_type = 'Complex-THRPUT';
settingFileName = 'manufacturingCellSetting_numerical1';  

numReplication = 5;

%% simulation section ===================================================
for rep = 1:numReplication
    for fileID=1:length(methodList)
        %% Clear variables excepts
        clearvars -except filenameList methodList fileID env_type settingFileName rep
        close all;
        warning('off')
        %% SET UP GPU
        usegpu = true;
        gpuDevice(1);
   
        %RL methods : Can run one by one method
        type_methods = methodList(fileID);
    
        %% Define filename
        methodName = char(type_methods);
        prefix_filename = sprintf('CASE1-R%d-%s', rep, methodName);
        fprintf('Start with %s  (file %d/%d)\n', prefix_filename, fileID, length(methodList));

    
        %Cost information
        failureToThroughput = false;
        proportion_LossTPMaintenance = 1.00;
        proportion_LossTPInspection = 0.00;  
        unit_cost_lossThroughput = 40;
        fixedMaintenacetoCost = true;
        fixedCostToInitiateMaintenace =1000;
        if fixedMaintenacetoCost
            fprintf('runing with fixed maintenance cost structure :%d \n',fixedCostToInitiateMaintenace);
        end
    
    
        if ~strcmp(env_type,'Simple')
            fprintf('runing with %s enviroment :  %s\n',env_type ,settingFileName);
            fprintf('Unit cost of production loss = %0.2f \n',unit_cost_lossThroughput);
            fprintf('Proportion of loss from maintenance  = %0.2f \n',proportion_LossTPMaintenance);
            fprintf('Proportion of loss from inspection  = %0.2f \n',proportion_LossTPInspection);
            if ~ failureToThroughput
                fprintf('Failure will not affect the throughput \n');
            end
        end
    
        %% SAC LOOKAHEAD        
        %SAC GROUP LOOKAHEAD VARIANTS
        SAC_agent_type =1; 
        agent_PolUpdateFreq = 1;
        entropy_exploration= 1;
        random_init_for_train = false; 

    
        if type_methods(1) == TYPE_METHOD.SAC_GRP_LOOKAHEAD
            is_monotinicNN = true;
            if  SAC_agent_type == 0
                fprintf('Default SAC Agent \n');
            else
                fprintf('SAC With modification \n');
            end
            if agent_PolUpdateFreq > 1
                fprintf('Policy will be updated for every %d steps \n',agent_PolUpdateFreq);
            end
            if entropy_exploration > 1
                fprintf('Entropy exploration =  %d \n',entropy_exploration);
            end
            if random_init_for_train 
                fprintf('Random initializatiion when machine is replaced \n');
            end
        end
    
        %% Inspection everytime or not
        inspection_everytime = false;
        if type_methods(1) == TYPE_METHOD.THRESHOLD_2TH || type_methods(1) == TYPE_METHOD.THRESHOLD
            inspection_everytime = true;
        end
    
        %% Run next code
        set_running_preference_case_study
        nTrainingEpisodes = 50; 
        num_test = 500;
        %%Debugging
        % code_debugging
        %% End
        scr_experiment_multisetting_complexEnv
    end
end