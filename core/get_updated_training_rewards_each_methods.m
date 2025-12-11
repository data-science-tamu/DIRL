function training_rewards_each_method = get_updated_training_rewards_each_methods(training_rewards_each_method, idx_repeat, idx_cost_setup, rewards_training)
    try
        training_rewards_each_method(idx_repeat, idx_cost_setup, :) = rewards_training;
    catch err
%         showErrors(err)

        try
            training_rewards_each_method(idx_repeat, idx_cost_setup, 1:numel(rewards_training)) = rewards_training;
        catch err
            showErrors(err)
        end

    end
%     cell_training_rewards{idx_method} = training_rewards_each_method;
end
