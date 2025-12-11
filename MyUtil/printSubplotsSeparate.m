function printSubplotsSeparate(usedsubplots, fontsize, filename_prefix, legends)
    settingfig = figure(999);ssp = subtightplot(1,1,1);;settingfig.Visible='off';

    for idx_subplot=1:numel(usedsubplots)
        components=get(usedsubplots(idx_subplot),'children');
        if(numel(components)>0)

            outfig = figure(2);clf;
            copyobj(usedsubplots(idx_subplot),outfig);
            
            ax = findobj(outfig,'Type','Axes');
            ax.Position = ssp.Position;
            
            offset = .24;
            ax.Position(2)=ssp.Position(2) + offset;
            ax.Position(4)=ssp.Position(4) - offset;


            outfig.Position = [1, 50, 400 ,300];

            setFontSize(outfig,fontsize);
            ax.Title.String='';
            
            if (numel(usedsubplots(idx_subplot).Legend)>0)
                legend();
                leg = findobj(outfig,'Type','Legend');
                leg_comp = get(leg,'children');
                copyobj(legends{idx_subplot}, leg_comp);
                leg.NumColumns = ceil(numel(leg.String)/2);
                leg.Location = 'southoutside';
                
                ax.Position(2)=ssp.Position(2) + offset;
                ax.Position(4)=ssp.Position(4) - offset;
                pos = leg.Position;
                pos(2) = pos(2) + 0.013;
                leg.Position=pos;

                leg.FontSize = 11;
            end
            

            outfig.PaperPositionMode = 'auto';
            fig_pos = outfig.PaperPosition;
            outfig.PaperSize = [fig_pos(3) fig_pos(4)];
            print(outfig,'-dpdf','-painters','-r600','-bestfit',sprintf('%s_%s',filename_prefix));

        end
    end
end