function out_str = getEstimatedRemainedTime(elapsedTime,iter,nIter)
%GETESTIMATEDREMAINEDTIME Summary of this function goes here
%   Detailed explanation goes here
%     getEstimatedRemainedTime(toc(tic_all), idx_repeat, nRepeats)
    out_str = showPrettyElapsedTime( elapsedTime *(nIter-iter)/iter,false);
end

