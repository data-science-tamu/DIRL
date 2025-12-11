classdef PositionalEncodingLayer < nnet.layer.Layer & nnet.layer.Formattable & nnet.layer.Acceleratable
    % PositionalEncoingLayer    

    % Build based on equation 4 in "NeRF: Representing Scenes as Neural
    % Radiance Fields for View Synthesis"

    properties        
        L_expandable
    end

    methods
        function this = PositionalEncodingLayer(L)
            this.L_expandable = L;
            this.Name = 'pos_emb';
        end

        function Z = predict(this,X)
            % Layer expects 'CB' dlarray
            trans_feature = [];
            for i= 1:this.L_expandable
                sin_l = sin(X*pi*(2^(i-1)));
                cos_l = cos(X*pi*(2^(i-1)));
                trans_feature = [trans_feature; sin_l ; cos_l];
            end
            Z = trans_feature;
        end
    end
end