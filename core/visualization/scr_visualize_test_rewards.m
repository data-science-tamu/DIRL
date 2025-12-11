line_types = {'b-','g-','r-','c-','m-','y-','k-','b-.','g-.','r-.','c-.','m-.','k-.','b--','g--','r--','c--','m--','y--','k--','b:','g:','r:','c:','m:','y:','k:'};

if ~exist('str_methods','var')
    str_methods = {};
    for i = 1:numel(type_methods)
        if( isa(type_methods,'cell'))
            info_method = type_methods{i};
            str_methods{i} = strrep(sprintf('%s',info_method{1}),'_',' ');
        else
            str_methods{i} = strrep(sprintf('%s',type_methods(i)),'_',' ');
        end
    end
end
ff=figure(1);clf;
for i=1:nMethods
    plot([1:num_test]',rewards_test_local_result(i,:)', line_types{i});
%     plot([1:num_test]'*ones(1,nMethods),rewards_test_local_result');
end
legend(str_methods{:});
ff.Name = sprintf('[%s] Results of this round of experiment',prefix_filename);


f2=figure(2);clf;
results_to_plot = reshape(mean(rewards_all_test,1),nMethods,num_test)';
for i=1:nMethods
    plot([1:num_test]', results_to_plot(:,i), line_types{i});
end
% plot([1:num_test]'*ones(1,nMethods),reshape(results(1,:,:),nMethods,1000)');
% legend('SAP_GRP','SAP_GRP_LH','NO_GRP','THRESHOLD','REGULAR');
legend(str_methods{:});
f2.Name = sprintf('[%s] Results of mean of the total experiment so far',prefix_filename);
% f2.Name = 'Results of mean of the total experiment so far';
% 
%     TYPE_METHOD.SAP_GRP, ...
%     TYPE_METHOD.SAP_GRP_LOOKAHEAD, ...
%     TYPE_METHOD.SAP_NOGRP ...
%     TYPE_METHOD.THRESHOLD ,...
%     TYPE_METHOD.REGULAR ,...



% f3=figure(3);clf;
% pp=plot([1:100]'*ones(1,5),reshape(mean(training_rewards(:,:,:),1),5,100)');
% 
% if(isa(f3.Children,'matlab.graphics.axis.Axes'))
%     f3.Children.YLim(1)=mean(training_rewards(:,:,:),'all') - 2*std(training_rewards(:,:,:),[],'all');
% end

% legend('SAP_GRP','SAP_GRP_LH','NO_GRP','THRESHOLD','REGULAR');
