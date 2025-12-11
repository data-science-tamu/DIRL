set_setting_here
get_params

nMethods = numel(type_methods);
rewards_all_test = zeros(nRepeats, nMethods, num_test);
% training_rewards = zeros(nRepeats, nMethods, nTrainingEpisodes);
cell_training_rewards = cell(nMethods,1);
cell_test_rewards = cell(nMethods,1);
experiences = cell(nRepeats, nMethods, num_test);
trained_models = cell(nRepeats, nMethods);
      
if exist('cost_setups','var') && numel(cost_setups)>1
    whole_storage = cell(numel(cost_setups), nRepeats);
    cell_local_storage = cell(nRepeats, numel(cost_setups), nMethods);
else
    whole_storage = cell(1, nRepeats);
    cell_local_storage = cell(nRepeats, 1, nMethods);
    cost_setups = [1];
end

cnt_exp = 0;


fprintf('%s\n',prefix_filename);
filename = sprintf('%s %s',prefix_filename, showPrettyDateTime(now(),'[yy-mm-dd_hh-MM-SS]'));
logger = Logger(sprintf('./log/%s.log',filename));

result_writer = Logger(sprintf('./log/%s.tsv',filename));
%%
cell_print={
    filename,
    unit,
    mean_beta,
    var_beta,
    var_meas_err,
    th,
    nSteps,
    discountFactor,
    nTrainingEpisodes,
    num_test,
    nRepeats,
    fix_main,
    replace_cost, 
    failure_cost
    };
str = sprintf('Log name\tnumber of components\tmean beta\tvar beta\tvar measurment errors\tFailure threshold\tHorizon length\tdiscountFactor\tNumber of training episodes\tNum of test\tNumber of replications\tsetup cost\treplacement cost\tdowntime cost');
result_writer.write_no_print(str);
str = sprintf('%s\t%d\t%.2f\t%.2f\t%.2f\t%.1f\t%d\t%.2f\t%d\t%d\t%d\t%.2f\t%.2f\t%.2f\n',cell_print{:});
% str = sprintf('%s\t%d\t%s\t%.1f\t%.1f\t%.1g\t%.1g\t%.1g',filename, idx_repeat, method.char, elapsed_time_training, elapsed_time_testing, mean_test_rewards, std_test_rewards, median_test_rewards);
result_writer.write_no_print(str);

str = sprintf('Log name\tRep\tMethod\tTraining time\tTesting time\tMean Test Rewards\tStd.Dev Test Rewards\tMedian Test Rewards');
% str = sprintf('%s\t%d\t%s\t%.1f\t%.1f\t%.1g\t%.1g\t%.1g',filename, idx_repeat, method.char, elapsed_time_training, elapsed_time_testing, mean_test_rewards, std_test_rewards, median_test_rewards);
result_writer.write_no_print(str);



%%


tic_all = tic();
if(usegpu)
    logger.log('GPU USED')
else
    logger.log('CPU USED')
end

cell_training_visualization_x_axis = cell(nRepeats, numel(cost_setups), nMethods);


for idx_repeat = 1:nRepeats
    for idx_param=1:numel(cell_params)
        try
    %         scr_setting_v3_unit10
    %         scr_setting_v3_unit15
    %         scr_setting_v3_unit15_normalized
    %         scr_setting_v3_unit15_normalized_learnrate
    %         scr_setting_v3_unit5
    %         scr_setting_v3_unit2
    %         scr_setting_v3_unit2_normalized
%             scr_setting_v3_unit2_normalized_learnrate
%             scr_setting_v3_unit2_normalized_learnrate_determ
%             set_setting_here
    %         scr_setting_v3_unit10_normalize
    %         scr_setting_v3_unit10_normalize_learnrate
    
%             fix_main = cost_setups(idx_cost_setup);
            param = cell_params{idx_param};
    %         param = Params_DRL(nSteps, var_beta, mean_beta, var_unit0, mean_unit0, replace_cost, fix_main, failure_cost, cost_w, lost_demand, demand, inspection_cost, verbose, nTrainingEpisodes, num_test, num_discretized_states, var_meas_err);
            fprintf('%s\n',setting);
            %% RUN EXPERIMENT
            scr_experiment
            whole_storage{idx_param,idx_repeat} = storage;
%             if(draw_plot_test_rewards )
%                 scr_visualize_test_rewards
%             end
        catch err
            logger.error(getStrErrors(err));
        end
    end
end
toc_all = toc(tic_all);
logger.log(sprintf('Elapsed Time (All):%s',showPrettyElapsedTime(toc_all)));
% Close the logger
logger.close()
result_writer.close();


try
    mkdirIfNotExist('./save/');
    save(sprintf('./save/final_results_%s',filename),'-v7.3');
catch err
    showErrors(err);
%         save(sprintf('C:\Matlab_saves/log_%s',filename),'-v7.3');
end