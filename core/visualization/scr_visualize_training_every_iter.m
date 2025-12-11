% type_methods
% nMethods
% prefix_filename
% env
% trainingInfo
% training_rewards_each_method
% idx_repeat
% idx_method


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
f=figure(30);clf;
subplot(2,2,1);
% if(use_speicified_env)
    cla;
    for idx_method_4plot = 1:nMethods
        training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
        if(numel(training_rewards_each_method_4_plot)>1)
            res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
            res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
            if(isa(type_methods,'cell'))
                method_info = type_methods{idx_method_4plot};
                x_range = [1:method_info{2}]';
            else
                x_range = trainingInfo.EpisodeIndex;
            end
        
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
f.Name = sprintf('[%s] Training Results',prefix_filename);
legend('Location','best');
title(sprintf('Real Reward (# repeats = %d)',idx_repeat));

if(isa(type_methods,'cell'))
    subplot(2,2,2);
%     f.Name = sprintf('[%s] Training Results',prefix_filename);
%     if(use_speicified_env)
        cla;
        for idx_method_4plot = 1:nMethods
            training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
            if(numel(training_rewards_each_method_4_plot)>1)
                res = training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:);
                res_ = reshape(res(1:idx_repeat,:,:), idx_repeat, size(res,3))';
                if(isa(type_methods,'cell'))
                    method_info = type_methods{idx_method_4plot};
                    x_range = [1:method_info{2}]';
                else
                    x_range = trainingInfo.EpisodeIndex;
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


% res_mean_ = squeeze(res_mean(1,:,:))';

subplot(2,3,4);cla;
for idx_method_4plot = 1:nMethods
    training_rewards_each_method_4_plot = cell_training_rewards{idx_method_4plot};
    if(numel(training_rewards_each_method_4_plot)>1)
        res_mean = mean(training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:),1);
        res_mean_ = reshape(res_mean(1,:,:), [], size(res_mean,3))';
        if(isa(type_methods,'cell'))
            method_info = type_methods{idx_method_4plot};
            x_range = [1:method_info{2}]';
        else
            x_range = trainingInfo.EpisodeIndex;
        end
        if(isa(type_methods,'cell'))
            x_range = x_range/max(x_range);
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
        res_med = median(training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:),1);
        res_med_ = reshape(res_med(1,:,:), [], size(res_med,3))';
        if(isa(type_methods,'cell'))
            method_info = type_methods{idx_method_4plot};
            x_range = [1:method_info{2}]';
        else
            x_range = trainingInfo.EpisodeIndex;
        end
    
        hold on;
        if(isa(type_methods,'cell'))
            x_range = x_range/max(x_range);
        end
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
            res_med = median(training_rewards_each_method_4_plot(1:idx_repeat,idx_cost_setup,:),1);
            res_med_ = reshape(res_med(1,:,:), [], size(res_med,3))';
            if(isa(type_methods,'cell'))
                method_info = type_methods{idx_method_4plot};
                x_range = [1:method_info{2}]';
            else
                x_range = trainingInfo.EpisodeIndex;
            end
        
            hold on;
            p=plot(x_range, res_med_, line_types{idx_method_4plot} ,'DisplayName',str_methods{idx_method_4plot});
        end
    end
    legend('Location','best');
    title('Median: Real Reward (True X axis)')    
end
%% store data
local_storage.figure = f;
%% PLOT BY METHODS

show_individual_method = false;
if(show_individual_method)
    f2=figure(10+idx_method);
%                     clf;
%                     hold on;
%                     f.Position(3:4)=[900,900];
    f2.Name = sprintf('[%s, %s] Training Results',prefix_filename, method);
    subplot(2,2,1);
    hold on;
    plot(trainingInfo.EpisodeIndex, trainingInfo.EpisodeReward, 'r', trainingInfo.EpisodeIndex, trainingInfo.AverageReward,'m:', trainingInfo.EpisodeIndex, env.training_rewards_real ,'k')
    legend('Episode Reward','Average Reward','Real Reward','Location','best');
    title('Reward')

    subplot(2,2,2);
    hold on;
    plot(trainingInfo.EpisodeIndex, env.training_rewards_real ,'k')
    legend('Real Reward','Location','best');
    title('Real Reward')

    subplot(2,2,3);
    hold on;
    plot(trainingInfo.EpisodeIndex, trainingInfo.EpisodeQ0,'y')
    legend('Q0','Location','best');
    title('Average Q0 (Objective Value)')

    subplot(2,2,4);
    hold on;
    res_med = median(training_rewards_each_method(1:idx_repeat,:,:),1);
    res_med_ = reshape(res_med(1,idx_method,:),[],1);
    res_mean = mean(training_rewards_each_method(1:idx_repeat,:,:),1);
    res_mean_ = reshape(res_mean(1,idx_method,:),[],1);
    p=plot(trainingInfo.EpisodeIndex, res_mean_ ,'b', trainingInfo.EpisodeIndex, res_med_ ,'r--');
    legend('mean','median','Location','best');
    p(1).Color(4)=.5;
    p(2).Color(4)=.5;
    title('Mean & Median: Real Reward')
%                     training_rewards
end


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