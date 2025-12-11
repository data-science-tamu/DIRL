function mkdirIfNotExist(newdir)
    files = dir(newdir);
    if(numel(files)==0)
        mkdir(newdir);        
    else
        sel_dir = files(1); %'.'%
        if(~sel_dir.isdir)
            mkdir(sel_dir(1).folder);
        end
    end;
end