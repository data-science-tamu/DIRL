function execute_multiple_experiments(setting, params, methods, nRepeats, runnable, prefix_filename, str_print)
    clc;clear all; close all;
    %% INPUT PARAMETERS
    if(exist(str_print,'var'))
        fprintf('%s\n',str_print);
    end
    nMethods = numel(methods);
    nParams = numel(params);
    results = cell(nMethods, nParams, nRepeats);
    
    filename = sprintf('%s %s',prefix_filename, showPrettyDateTime(now(),'[yy-mm-dd_hh-MM-SS]'));
    logger = Logger(sprintf('./log/%s.log',filename));
    %% TEST
    tic_all = tic();
    cnt_exp = 0;
    for idx_repeat = 1:nRepeats
        tic_rep = tic();
        for idx_param=1:numel(params)
            param = params(idx_param);
    
            
            logger.log(sprintf('Setting start:%s\n', param.print_str()));
%             logger.log(setting.print_str());
            tic_setting = tic();
            for idx_method = 1:nMethods
                cnt_exp = cnt_exp+1;
                method = methods(idx_method);
                logger.log(sprintf('[%s] (Method:%d/%d, Setting:%d/%d, Rep:%d/%d) (%d/%d)', method, idx_method, nMethods, idx_param, nParams, idx_repeat, nRepeats, cnt_exp, nParams*nRepeats*nMethods));

                tic_method = tic();
                result = Executer_runnable.run(setting, param, runnable, method, logger);
                results{idx_method, idx_param, idx_repeat} = result;
                %% CREATE ENVIRONMENT

                logger.print(result.print_str());
                toc_method =toc(tic_method);
                logger.log(sprintf('Elapsed Time (%s):%s',method,showPrettyElapsedTime(toc_method)));
                logger.seperate()
                
            end
            logger.seperate('A Setting Ends')
            toc_setting = toc(tic_setting);
            logger.log(sprintf('Elapsed Time (One Setting):%s',showPrettyElapsedTime(toc_setting)));
        end
        logger.seperate('A Rep Ends')
        toc_rep = toc(tic_rep);
        logger.log(sprintf('Elapsed Time (One Repeat):%s',showPrettyElapsedTime(toc_rep)));
        logger.log(sprintf('%s',getEstimatedRemainedTime(toc(tic_all), idx_repeat, nRepeats)));
        logger.log(sprintf('%s',getEstimatedEndTime(toc(tic_all), idx_repeat, nRepeats)));

    end
    logger.seperate('Experiments Finished')
    toc_all = toc(tic_all);
    logger.log(sprintf('Elapsed Time (All):%s',showPrettyElapsedTime(toc_all)));
    
    % storage.results = results;
    % storage.training_rewards = training_rewards;
    % storage.experiences = experiences;
    % storage.trained_models = trained_models;
    
    try
        save(sprintf('./save/%s',filename),'-v7.3');
    catch
        save(sprintf('C:\Matlab_saves/%s',filename),'-v7.3');
    end

end
