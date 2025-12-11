function out_str = getEstimatedEndTime(elapsedTime,iter,nIter)
%GETESTIMATEDREMAINEDTIME Summary of this function goes here
%   Detailed explanation goes here
%     getEstimatedRemainedTime(toc(tic_all), idx_repeat, nRepeats)
    out_str = showPrettyDateTime( now()+seconds(elapsedTime *(nIter-iter)/iter));
end

