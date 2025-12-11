% close all;
% xxl = repmat(cc,1,nIter-nBurnin+1);
% idx = 1;
% zz=zeros(M,nIter-nBurnin+1);zz(:,:)=theta(:,idx,nBurnin:end);
% figure(1);hold on;
%     lb = mean(zz,2)-2*std(zz,0,2);
%     ub = mean(zz,2)+2*std(zz,0,2);
%    
%     plot(xxl,zz,'-');
%     plot(xxl,(true_theta(:,idx)),'ok'); 
%     plot(xxl,mean(zz,2),'-r','LineWidth',2);
%     plot(xxl,ub,'-b','LineWidth',2);
%     plot(xxl,lb,'-b','LineWidth',2);
% 
%     title('\theta(c) (o:data, -:est)');  ylabel('\theta(.)'); xlabel('c');
% 
% hold off;

infig=figure(1);s1=subplot(2,1,1);plot([1 2], [3 4]);subplot(2,1,2);plot([4 2],[2 4]);
from=get(infig.Children(2),'children');

figure(2);clf;
outfig = subplot(1,1,1);

copyobj(from,outfig)
