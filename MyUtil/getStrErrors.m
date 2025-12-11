function str=getStrErrors(err)
    estack = err.stack;
    
    str = sprintf('[ERROR] %s \n', err.identifier);
    str = sprintf('%s%s \n', str,err.message);
    
    if(numel(err.cause)>0)
        str = sprintf('%s\n Caused by : \n',str);
        for i=1:numel(err.cause)
            out = getStrErrors(err.cause{i});
            str = sprintf('%s%s',str,out);
        end
        str = sprintf('%s%s',str,'\n in : \n');
    end
    for i=1:numel(estack)
        str = sprintf('%sError in <a href="matlab: opentoline(which(''%s''),%d)">%s</a> (<a href="matlab: opentoline(which(''%s''),%d)">line %d</a>)\n\n', str, estack(i).file, estack(i).line, estack(i).name,  estack(i).file, estack(i).line, estack(i).line);
    end

end
