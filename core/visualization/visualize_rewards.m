function visualize_rewards(cell_training_rewards, idx_repeat, idx_cost_setup, type_methods, nMethods, prefix_filename, str_fig_title, num_fig, cell_x_axis, showplot, filename )
    
    
    %% PREPROCESSING
    line_types = {'b-','g-','r-','c-','m-','y-','k-','b-.','g-.','r-.','c-.','m-.','y-.','k-.','b--','g--','r--','c--','m--','y--','k--','b:','g:','r:','c:','m:','y:','k:'};
    if ~exist('str_methods','var')
        str_methods = {};
        for idx_method_4str = 1:nMethods
            if isa(type_methods,'cell')
                info_method = type_methods{idx_method_4str};
                str_methods{idx_method_4str} = strrep(sprintf('%s',info_method{1}),'_',',');
            else
                str_methods{idx_method_4str} = strrep(sprintf('%s',type_methods(idx_method_4str)),'_',',');
            end
        end
    end
    %% ALL METHODS
    if(exist('showplot','var') && ~showplot)
        f=figure('visible','off');
    else
        f=figure(num_fig);
    end
    clf;
    subplot(2,3,1);
    % if(use_speicified_env)
        cla;
        for idx_method_4plot = 1:nMethods
            training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
            if(numel(training_rewards_each_method_4_plot)>1)
                res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
                if(sum(res(idx_repeat,1,:),'all')==0 && idx_repeat>1)
                    res = training_rewards_each_method_4_plot(1:idx_repeat-1,idx_cost_setup,:);
                    res_ = reshape(res, [], size(res,3))';
                else
                    res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
                end
%                 if(isa(type_methods,'cell'))
%                     method_info = type_methods{idx_method_4plot};
%                     x_range = [1:method_info{2}]';
%                 else
                if (exist('cell_x_axis','var') && numel(cell_x_axis)>0 )
                    x_range_ = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
                    if(numel(x_range_)>0 && numel(x_range_)>numel(res_))
                        res_ = res_(1:numel(x_range_),1);
                        x_range = x_range_;
                    else
                        x_range = [1:size(res_,1)]';
                    end
                else
                    x_range = [1:size(res_,1)]';
                end
%                 end
            
                hold on;
                try
                    p=plot(x_range, res_, line_types{idx_method_4plot} ,'DisplayName',str_methods{idx_method_4plot});
                    showOneLegend(p)
                catch err
                    showErrors(err);
                end
            end
        end
    % else
    %     hold on;
    %     plot(trainingInfo.EpisodeIndex, env.training_rewards_real ,line_types{idx_method})
    % end
    f.Name = sprintf('[%s] %s Results',prefix_filename, str_fig_title);
    legend('Location','best');
    title(sprintf('[%s] Real Reward (# repeats = %d)',str_fig_title, idx_repeat));
%% SUBPLOT 2
    if(isa(type_methods,'cell'))
        subplot(2,3,2);
    %     f.Name = sprintf('[%s] Training Results',prefix_filename);
    %     if(use_speicified_env)
            cla;
            for idx_method_4plot = 1:nMethods
                training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
                if(numel(training_rewards_each_method_4_plot)>1)
                    res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
                    if(sum(res(idx_repeat,1,:),'all')==0 && idx_repeat>1)
                        res = training_rewards_each_method_4_plot(1:idx_repeat-1,idx_cost_setup,:);
                        res_ = reshape(res, [], size(res,3))';
                    else
                        res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
                    end
%                     end
%                     res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
%                     if(isa(type_methods,'cell'))
%                         method_info = type_methods{idx_method_4plot};
%                         x_range = [1:method_info{2}]';
%                     else
%                         x_range = [1:size(res_,1)]';
                    if (exist('cell_x_axis','var') && numel(cell_x_axis)>0 )
                        x_range_ = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
                        if(numel(x_range_)>0 && numel(x_range_)>numel(res_))
                            res_ = res_(1:numel(x_range_),1);
                            x_range = x_range_;
                        else
                            x_range = [1:size(res_,1)]';
                        end
                    else
                        x_range = [1:size(res_,1)]';
                    end
                
                    hold on;
                    try
                        p=plot(x_range./max(x_range), res_, line_types{idx_method_4plot} ,'DisplayName',str_methods{idx_method_4plot});
                        showOneLegend(p)
                    catch err
                        showErrors(err);
                    end
                end
            end
            legend('Location','best');
    %     else
    %         hold on;
    %         plot(trainingInfo.EpisodeIndex/max(trainingInfo.EpisodeIndex), env.training_rewards_real ,line_types{idx_method})
    %         legend(str_methods{:},'Location','best');
    %     end
    
        title('Real Reward')
    end
    
    %% SUBPLOT 3
        ss=subplot(2,3,3);
    %     f.Name = sprintf('[%s] Training Results',prefix_filename);
    %     if(use_speicified_env)
            cla;
            cum_results = zeros((idx_repeat-1)*nMethods+idx_method_4plot, 1, size(training_rewards_each_method_4_plot, 3));
%             for idx_method_4plot = 1:nMethods
%                 training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
%                 if(numel(training_rewards_each_method_4_plot)>1)
%                 end
%             end
%             quantile(cum_results,.3,'all')
            
            for idx_method_4plot = 1:nMethods
                training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
                if(numel(training_rewards_each_method_4_plot)>1)
                    res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
                    if(sum(res(idx_repeat,1,:),'all')==0 && idx_repeat>1)
                        res = training_rewards_each_method_4_plot(1:idx_repeat-1,idx_cost_setup,:);
                        res_ = reshape(res, [], size(res,3))';
                    else
                        res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
                    end
%                     end
%                     res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
%                     if(isa(type_methods,'cell'))
%                         method_info = type_methods{idx_method_4plot};
%                         x_range = [1:method_info{2}]';
%                     else


                    if (exist('cell_x_axis','var') && numel(cell_x_axis)>0 )
                        x_range_ = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
                         if(numel(x_range_)>0 && numel(x_range_)>numel(res_))
                            res_ = res_(1:numel(x_range_),1);
                            x_range = x_range_;
                        else
                            x_range = [1:size(res_,1)]';
                        end
                        x_range = x_range./max(x_range);
                    else
                        x_range = [1:size(res_,1)]';
                        if(isa(type_methods,'cell'))
                            x_range = x_range./max(x_range);
                        end
                    end

%                     end
                
                    hold on;
                    try
                        p=plot(x_range, res_, line_types{idx_method_4plot} ,'DisplayName',str_methods{idx_method_4plot});
                        showOneLegend(p)
                    catch err
                        showErrors(err);
                    end
                end
                try
%                     cum_results((idx_method_4plot-1)*idx_repeat+1:idx_method_4plot*idx_repeat,1,:) = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
                    low_yaxes(method) = quantile(training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:), .3, 'all');

                    current_limit_yaxis = ss.YAxis.Limits;
                    low_yaxis = mean(low_yaxes);
        
        %             low_yaxis = quantile(cum_results,.3,'all');
                    ss.YAxis.Limits = [low_yaxis, current_limit_yaxis(2)];
                catch err
                end
            end
            legend('Location','best');
            %     else
    %         hold on;
    %         plot(trainingInfo.EpisodeIndex/max(trainingInfo.EpisodeIndex), env.training_rewards_real ,line_types{idx_method})
    %         legend(str_methods{:},'Location','best');
    %     end
    
        title('Real Reward (Zoomed)')
%     end
    
    
    % res_mean_ = squeeze(res_mean(1,:,:))';
    
%% SUBPLOT 4
    subplot(2,3,4);cla;
    for idx_method_4plot = 1:nMethods
        training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
        if(numel(training_rewards_each_method_4_plot)>1)
            res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
            if(sum(res(idx_repeat,1,:),'all')==0 && idx_repeat>1)
                res = training_rewards_each_method_4_plot(1:idx_repeat-1,idx_cost_setup,:);
%                 res_ = reshape(res, [], size(res,3))';
%             else
%                 res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
            else
                res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
            end
%             end
            res_mean = mean(res,1);            
%             res_mean = mean(training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:),1);
            res_mean_ = reshape(res_mean(1,:,:), [], size(res_mean,3))';
%             if(isa(type_methods,'cell'))
%                 method_info = type_methods{idx_method_4plot};
%                 x_range = [1:method_info{2}]';
%             else
%             end

            if (exist('cell_x_axis','var') && numel(cell_x_axis)>0 )
                x_range_ = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
                if(numel(x_range_)>0 && numel(x_range_)>numel(res_))
                    res_mean_ = res_mean_(1:numel(x_range_),1);
                    x_range = x_range_;
                else
                    x_range = [1:size(res_,1)]';
                end
                
%                 res_mean_ = res_mean_(1:numel(x_range),1);
                x_range = x_range./max(x_range);
            else
                x_range = [1:size(res_mean_,1)]';
                if(isa(type_methods,'cell'))
                    x_range = x_range/max(x_range);
                end
            end


            hold on;
            try
                p=plot(x_range, res_mean_, line_types{idx_method_4plot} ,'DisplayName',str_methods{idx_method_4plot});
    %             showOneLegend(p)
            catch err
                showErrors(err);
                
            end
        end
    end
    % else
    %     p=plot(trainingInfo.EpisodeIndex, res_mean_);
    % %                         legend(str_methods{:},'Location','best');
    % end
    legend('Location','best');
    
    
    %                     p(1).Color(4)=.5;
    %                     p(2).Color(4)=.5;
    title('Mean: Real Reward (Extended x axis)')                    
    
    %                     subplot(2,2,4);
    %                     p=plot(trainingInfo.EpisodeIndex, res_med_);
    subplot(2,3,5);cla;
    % if(size(res_med_,2)>1)
    for idx_method_4plot = 1:nMethods
        training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
        if(numel(training_rewards_each_method_4_plot)>1)
            res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
            if(sum(res(idx_repeat,1,:),'all')==0 && idx_repeat>1)
                res = training_rewards_each_method_4_plot(1:idx_repeat-1,idx_cost_setup,:);
%                 res_ = reshape(res, [], size(res,3))';
%             else
%                 res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
            else
                res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
            end
%             end
            res_med = median(res,1);
            res_med_ = reshape(res_med(1,:,:), [], size(res_med,3))';
%             if(isa(type_methods,'cell'))
%                 method_info = type_methods{idx_method_4plot};
%                 x_range = [1:method_info{2}]';
%             else
%                 x_range = [1:size(res_med_,1)]';
%             end
            if (exist('cell_x_axis','var') && numel(cell_x_axis)>0 )
%                 x_range = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
                x_range_ = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
                if(numel(x_range_)>0 && numel(x_range_)>numel(res_))
                    res_med_ = res_med_(1:numel(x_range_),1);
                    x_range = x_range_;
                else
                    x_range = [1:size(res_,1)]';
                end

%                 res_med_ = res_med_(1:numel(x_range),1);
                x_range = x_range./max(x_range);
            else
                x_range = [1:size(res_med_,1)]';
                if(isa(type_methods,'cell'))
                    x_range = x_range/max(x_range);
                end
            end
        
            hold on;
%             if(isa(type_methods,'cell'))
%                 x_range = x_range/max(x_range);
%             end
            p=plot(x_range, res_med_, line_types{idx_method_4plot} ,'DisplayName',str_methods{idx_method_4plot});
        end
    end
    legend('Location','best');
    title('Median: Real Reward (Extended x axis)')                    
    
    
    %% True x-range
    if(isa(type_methods,'cell'))
        subplot(2,3,6);cla;
        % if(size(res_med_,2)>1)
        for idx_method_4plot = 1:nMethods
            training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
            if(numel(training_rewards_each_method_4_plot)>1)

            res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
            if(sum(res(idx_repeat,1,:),'all')==0 && idx_repeat>1)
                res = training_rewards_each_method_4_plot(1:idx_repeat-1,idx_cost_setup,:);
            else
                res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
            end
%             end
            res_med = median(res,1);
%                 res_med = median(training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:),1);
                res_med_ = reshape(res_med(1,:,:), [], size(res_med,3))';
%                 if(isa(type_methods,'cell'))
%                     method_info = type_methods{idx_method_4plot};
%                     x_range = [1:method_info{2}]';
%                 else
%                     x_range = [1:size(res_med_,1)]';
%                 end
                if (exist('cell_x_axis','var') && numel(cell_x_axis)>0 )
                    x_range_ = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
                    if(numel(x_range_)>0 && numel(x_range_)>numel(res_))
                        res_med_ = res_med_(1:numel(x_range_),1);
                        x_range = x_range_;
                    else
                        x_range = [1:size(res_,1)]';
                    end
%                     x_range = cell_x_axis{idx_repeat, idx_cost_setup, idx_method_4plot};
%                     res_med_ = res_med_(1:numel(x_range),1);
                else
                    x_range = [1:size(res_med_,1)]';
                end
                if(isa(type_methods,'cell'))
                    x_range = x_range/max(x_range);
                end
            
                hold on;
                p=plot(x_range, res_med_, line_types{idx_method_4plot} ,'DisplayName',str_methods{idx_method_4plot});
            end
        end
        legend('Location','best');
        title('Median: Real Reward (True X axis)')    
    end


    if(exist('filename','var') )
        mkdirIfNotExist('figs');
        saveas(f, sprintf('./figs/%s.fig',filename));
    end
    %% store data
%     local_storage.figure = f;
    %% PLOT BY METHODS
    
%     show_individual_method = false;
%     if(show_individual_method)
%         f2=figure(10+idx_method);
%     %                     clf;
%     %                     hold on;
%     %                     f.Position(3:4)=[900,900];
%         f2.Name = sprintf('[%s, %s] Training Results',prefix_filename, method);
%         subplot(2,2,1);
%         hold on;
%         plot(trainingInfo.EpisodeIndex, trainingInfo.EpisodeReward, 'r', trainingInfo.EpisodeIndex, trainingInfo.AverageReward,'m:', trainingInfo.EpisodeIndex, env.training_rewards_real ,'k')
%         legend('Episode Reward','Average Reward','Real Reward','Location','best');
%         title('Reward')
%     
%         subplot(2,2,2);
%         hold on;
%         plot(trainingInfo.EpisodeIndex, env.training_rewards_real ,'k')
%         legend('Real Reward','Location','best');
%         title('Real Reward')
%     
%         subplot(2,2,3);
%         hold on;
%         plot(trainingInfo.EpisodeIndex, trainingInfo.EpisodeQ0,'y')
%         legend('Q0','Location','best');
%         title('Average Q0 (Objective Value)')
%     
%         subplot(2,2,4);
%         hold on;
%         res_med = median(training_rewards_each_method(1:idx_repeat,:,:),1);
%         res_med_ = reshape(res_med(1,idx_method,:),[],1);
%         res_mean = mean(training_rewards_each_method(1:idx_repeat,:,:),1);
%         res_mean_ = reshape(res_mean(1,idx_method,:),[],1);
%         p=plot(trainingInfo.EpisodeIndex, res_mean_ ,'b', trainingInfo.EpisodeIndex, res_med_ ,'r--');
%         legend('mean','median','Location','best');
%         p(1).Color(4)=.5;
%         p(2).Color(4)=.5;
%         title('Mean & Median: Real Reward')
%     %                     training_rewards
%     end
%     
    
    %% RESCALED
    %                     mn=min(trainingInfo.EpisodeReward);
    %                     rng=max(trainingInfo.EpisodeReward)-mn;
    %                     adjEpReward = (trainingInfo.EpisodeReward-mn)/rng;
    %                     adjAvReward = (trainingInfo.AverageReward-mn)/rng;
    %                    
    %                     mn=min(env.training_rewards_real);
    %                     rng=max(env.training_rewards_real)-mn;
    %                     adjRR = (env.training_rewards_real-mn)/rng;
    % 
    %                     mn=min(trainingInfo.EpisodeQ0);
    %                     rng=max(trainingInfo.EpisodeQ0)-mn;
    %                     adjQ = (trainingInfo.EpisodeQ0-mn)/rng;
    %                     plot(trainingInfo.EpisodeIndex, adjEpReward, 'r', trainingInfo.EpisodeIndex, adjAvReward,'b', trainingInfo.EpisodeIndex, adjQ,'y', trainingInfo.EpisodeIndex, adjRR, 'k');
    %                     legend('Episode R','Avrage R','Q0','Real R','Location','best');
    %                     title('rescaled')
    %% END: RESCALED
    
    %                     subplot(2,2,3);
    %                     plot(trainingInfo.AverageReward)
    %                     subplot(2,2,4);
    %                     plot(trainingInfo.EpisodeSteps)
end