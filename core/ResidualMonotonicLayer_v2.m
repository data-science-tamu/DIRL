classdef ResidualMonotonicLayer_v2 < nnet.layer.Layer & nnet.layer.Formattable & nnet.layer.Acceleratable
    % ResidualMonotonicLayer    Sum and scale a subset of channels
    % This is the version for inspection 
    %   Copyright 2024 The MathWorks, Inc.

    properties        
        MonotonicChannels
        ResidualScaling
        LayerWidth;
    end

    methods
        function this = ResidualMonotonicLayer_v2(monotonicChannels,lipschitzConstant,dim)
            this.MonotonicChannels = monotonicChannels;
            this.ResidualScaling = lipschitzConstant;
            this.LayerWidth = dim;
            this.Name = 'res_mono';
        end

        function Z = predict(this,X)
            % Layer expects 'CB' dlarray
            Z = sum(X(this.MonotonicChannels,:),1);
            Z_lambda = this.ResidualScaling*Z;
            Z = ones(this.LayerWidth,1).*Z_lambda;
            for z_index = 1:(this.LayerWidth/2)
                Z((this.LayerWidth/2)+z_index,1) = 0;
            end
%             Z = ones(this.LayerWidth,1).*Z;
%             Z(this.LayerWidth,1) =  Z(this.LayerWidth,1) -1;
        end
    end
end