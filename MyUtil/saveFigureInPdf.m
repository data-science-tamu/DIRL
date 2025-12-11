function saveFigureInPdf(gcf, filename,position)
    if(exist('position','var') )
        if(~isnan(position))
            set(gcf, 'Units', 'inch', 'position', position);
        else
            set(gcf, 'Units', 'inch', 'position', [0, 0,5, 5]);
        end
    else
        set(gcf, 'Units', 'inch', 'position', [0, 0,5, 5]);
%         set(gcf, 'Units', 'inch', 'position', [-6.5000,3.8750,5, 5]);
    end
%     set(gcf,'Resize','off')
    set(gca, 'LooseInset', get(gca,'TightInset'))

%     saveas(gcf,sprintf('%s.fig',filename),'fig');
    if(contains(filename,'.pdf'))
        saveas(gcf,sprintf('%s',filename),'pdf');
%         print(gcf,'-dpdf','-painters','-r600','-bestfit',sprintf('%s',filename));
    else
        saveas(gcf,sprintf('%s.pdf',filename),'pdf');
%         print(gcf,'-dpdf','-painters','-r600','-bestfit',sprintf('%s.pdf',filename));
    end
end

