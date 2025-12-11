function agent = rlSACAgentMonotonic(varargin)
% RLSACAGENT: Creates a SAC agent.
%
%   AGENT = RLSACAGENT(OINFO,AINFO) creates a soft actor critic (SAC)
%   agent with default agent options and default deep neural network
%   representations. The default SAC agent uses a stochastic actor
%   network and a value network.
%       - Each fully-connected layer (fc) not on an output path has 256
%       outputs.
%       - For each spatial input, the 2D convolution layer
%       (cv) has 32 filters of size 3-by-3.
%       - Actor network does not use the tanh and scaling layer for the
%       output of the mean path since the squash functions are applied
%       outside of the network if the actions are bounded.
%   Default stochastic actor network
%                            +------+
%  o1 (vector) ---------fc-->|      |                    fc(numAction)---> mean
%                            |concat|-->relu--fc--relu-->
%  o2 (image)  -cv-relu-fc-->|      |                    fc(numAction)-->softplus---> std
%                            +------+
%   Default value function network
%                            +------+
%  o1 (vector) ---------fc-->|      |
%  o2 (image)  -cv-relu-fc-->|concat|-->relu--fc--relu-->fc(1)--> V([o1,o2])
%  a  (vector) ---------fc-->|      |
%                            +------+
%
%   AGENT = RLSACAGENT(OINFO,AINFO,INITOPTIONS) creates a soft actor
%   critic (SAC) agent with deep neural network representations
%   configured using options specified in INITOPTIONS. To create
%   INITOPTIONS, use an rlAgentInitializationOptions object. RNN is not
%   supported and INITOPTIONS.UseRNN must be false.
%
%   AGENT = RLSACAGENT(ACTOR,CRITIC) creates a soft actor critic agent
%   with default options using the specified ACTOR and 1x2 vector of
%   CRITIC representations. Each critic in CRITICS vector must have
%   different estimation for the same observation and action pair. For
%   example, they can have same structure but different initial
%   parameters or have different structures. The output of the mean path
%   in the SAC actor network should not have tanh or scaling layer
%   since the squash functions are automatically applied outside of the
%   network if the actions are bounded.
%       ACTOR: rlContinuousGaussianActor 
%       CRITIC: rlQValueFunction 
%
%   For all of the previous syntaxes, you can specify nondefault options
%   using an rlSACAgentOptions object, OPTIONS.
%
%       AGENT = RLSACAGENT(...,OPTIONS)
%
%   See also: rlSACAgentOptions, EntropyWeightOptions, rlTD3Agent, rlPPOAgent,
%   rlDDPGAgent, rlDQNAgent, rlContinuousGaussianActor, rlQValueFunction

% Copyright 2019-2022 The MathWorks, Inc.

narginchk(2,4)
AgentType = "SAC";
FirstArg = varargin{1};
if isa(FirstArg,'rl.representation.rlStochasticActorRepresentation') || ...
        (isa(FirstArg,'rl.function.rlContinuousGaussianActor') && ...
        isa(FirstArg,'rl.function.StochasticMixin'))
    % AGENT = RLSACAGENT(ACTOR,CRITIC)
    % AGENT = RLSACAGENT(ACTOR,CRITIC,AGENTOPTIONS)
    Actor = FirstArg;
    Critic = varargin{2};
    if nargin < 3
        AgentOptions = rl.util.getDefaultAgentOptions(AgentType,hasRNNState(Actor));
    else
        AgentOptions = varargin{3};
    end
    NumCritic = numel(Critic);
    % backward compatibility, convert representation to function
    if isa(Critic(1),'rl.representation.rlAbstractRepresentation')
        for ct = 1:NumCritic
            [NewCritic(ct),OptimizerOptions] = representation2function(Critic(ct));
            AgentOptions.CriticOptimizerOptions(ct) = OptimizerOptions;
        end
        Critic = NewCritic;
    end
    if isa(Actor,'rl.representation.rlAbstractRepresentation')
        % backward compatibility, convert representation to function
        [Actor,OptimizerOptions] = representation2function(Actor);
        AgentOptions.ActorOptimizerOptions = OptimizerOptions;
    end
elseif isa(FirstArg,'rl.util.RLDataSpec')
    % AGENT = rlSACAgent(OINFO,AINFO)
    % AGENT = rlSACAgent(OINFO,AINFO,INITOPTIONS)
    % AGENT = rlSACAgent(OINFO,AINFO,AGENTOPTIONS)
    % AGENT = rlSACAgent(OINFO,AINFO,INITOPTIONS,AGENTOPTIONS)
    [ObservationInfo,ActionInfo,InitOptions,AgentOptions] = rl.util.parseAgentInitializationInputs(AgentType,varargin{:});
    UseSquashInNetwork = false;

    %% Settings
    monotonic_required = true; %false; %true;
    connect_stdev_begin = true; %true;

    %% NN Structure 
    numHiddenUnits =[256 256 256 prod(ActionInfo.Dimension)];
%     numHiddenUnits =[32 32 32 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[256 256 256 256 256 256 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[256 256 256 64 64 64 prod(ActionInfo.Dimension)];

    %% Active parameters 
    add_residual_connection = true ; %false
    resNet_connectingStyle = 1;
    stdev_scalar =  true; 

    activation_fn ='relu';  %'tanh', 'relu' or 'fullsort'
    pNorm = 1;
    lambda_monotonic = 0.0001;
    weight_initializer = "orthogonal";  % For monotonic: "zeros"  , "orthogonal"

    %% Prepare the monotonic 
    lipSignature = 1; % 1 increasing -1 is decresing
    monotonicChannels = 1:prod(ObservationInfo.Dimension);  
    options.ResidualScaling = lambda_monotonic;


    %% Other options (Archived)
    stdev_deepNN =  false;
    positional_encode = false;
    residual_connection_2unit = true;
    L = 10;  %for positional encoding


    %% Network structure =======================================================
    % numHiddenUnits =[32 16 8 prod(ActionInfo.Dimension)];
    % if add_residual_connection
    %     % numHiddenUnits =[32 32 32 prod(ActionInfo.Dimension)];
    %     % numHiddenUnits =[32 32 32 8 8 prod(ActionInfo.Dimension)];
    %     % numHiddenUnits =[16 16 16 16 16 prod(ActionInfo.Dimension)];
    %     % numHiddenUnits =[32 32 32 8 8 8 prod(ActionInfo.Dimension)];
    %     % numHiddenUnits =[16 16 16 16 16 16 prod(ActionInfo.Dimension)];
    %     % numHiddenUnits =[32 32 32 prod(ActionInfo.Dimension)];
    %     numHiddenUnits =[256 256 256 prod(ActionInfo.Dimension)];
    % end
    % numHiddenUnits =[256 64 16 4 prod(ActionInfo.Dimension)];
    %For residual block concept
    % numHiddenUnits =[256 256 256 64 64 64 16 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[256 64 16 4 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[32  32 32 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[256 64 16 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[256 128 64 32 16 8 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[512 256 128 64 32 8 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[256 256 256 64 64 64 16 prod(ActionInfo.Dimension)];
    % numHiddenUnits =[256 256 256 64 64 64 16 prod(ActionInfo.Dimension)];
    
    %% Monotonic or not 
    if monotonic_required
        %% Monotonic structure =======================================================
        ubLipschitzConstant = lipSignature * options.ResidualScaling;
    
        disp(sprintf('Monotonic NN with lambda = %d , pNorm = %d , activation function = %s', options.ResidualScaling, pNorm,activation_fn));
        disp(sprintf('NN layers are %d , %d , %d , ... with %d layers', numHiddenUnits(1), numHiddenUnits(2), numHiddenUnits(3),length(numHiddenUnits)));
    
        
        %Input layer
        tempLayers = [
            featureInputLayer(prod(ObservationInfo.Dimension),Name="netObsInLyr")
            ];
    
        %Activation function
        switch activation_fn 
            case 'fullsort'
                gnpFcn = @(k)iFullSortLayer("activ_" + k);
            case 'relu'
                gnpFcn = @(k)reluLayer(Name="activ_" + k);
            case 'tanh'
                gnpFcn = @(k)tanhLayer(Name="activ_" + k);
        end
    
           
        %Positonal encoding
        if positional_encode    
            disp(sprintf('Positional encoding with L = %d ', L));
            tempLayers =[tempLayers
                PositionalEncodingLayer(L)
            ];
        end
    
        %Mean path neural network------------------------------------------
        tempLayers = [tempLayers
        fullyConnectedLayer(numHiddenUnits(1),Name="meanInLyr",WeightsInitializer=weight_initializer)
        ];
        for ii = 2:numel(numHiddenUnits)
            tempLayers = [tempLayers
                gnpFcn(ii)
                fullyConnectedLayer(numHiddenUnits(ii),Name="fc_" + ii,WeightsInitializer=weight_initializer)
                ];
        end
        net = dlnetwork(tempLayers);
    
        %Constrain layers
        lnet = conslearn.lipschitz.makeNetworkLipschitz(net,pNorm,ubLipschitzConstant);
        lgraph = layerGraph(lnet);
    
        %Add residual connection to induce monotonicity
        %tempLayers = conslearn.layer.ResidualMonotonicLayer(monotonicChannels,ubLipschitzConstant);
        %Above is default with 1 output but in this case is 3 
        if prod(ActionInfo.Dimension) > 1
            tempLayers = ResidualMonotonicLayer_v1(monotonicChannels,prod(ActionInfo.Dimension)*ubLipschitzConstant,prod(ActionInfo.Dimension));
            lgraph = addLayers(lgraph,tempLayers);
    
            % Add AdditionLayer
            tempLayers = additionLayer(2,"Name","MeanOutLyr");
            lgraph = addLayers(lgraph,tempLayers);
        
            % Connect layers
            lgraph = connectLayers(lgraph,"netObsInLyr","res_mono");  
            depth = numel(numHiddenUnits);
            lgraph = connectLayers(lgraph,"fc_" + depth,"MeanOutLyr/in1");
            lgraph = connectLayers(lgraph,"res_mono","MeanOutLyr/in2");
            % Initialize dlnetwork
            net = dlnetwork(lgraph);
            % Constraints monotonic
            lipschitzConstant = abs(net.Layers(end-1).ResidualScaling);
    
        else
            tempLayers = conslearn.layer.ResidualMonotonicLayer(monotonicChannels,prod(ActionInfo.Dimension)*ubLipschitzConstant);
            lgraph = addLayers(lgraph,tempLayers);
        
            %Expand dimension
            tempLayers = fullyConnectedLayer(prod(ActionInfo.Dimension),'Name',"expandLayer",...
                            'WeightLearnRateFactor',0,...
                            'BiasLearnRateFactor',0,... 
                            'WeightsInitializer','ones',...
                            'BiasInitializer','zeros');
            lgraph = addLayers(lgraph,tempLayers);
        
            % Add AdditionLayer
            tempLayers = additionLayer(2,"Name","MeanOutLyr");
            lgraph = addLayers(lgraph,tempLayers);
        
            % Connect layers
            lgraph = connectLayers(lgraph,"netObsInLyr","res_mono");
            lgraph = connectLayers(lgraph,"res_mono","expandLayer");
        
            depth = numel(numHiddenUnits);
            lgraph = connectLayers(lgraph,"fc_" + depth,"MeanOutLyr/in1");
            lgraph = connectLayers(lgraph,"expandLayer","MeanOutLyr/in2");
            % Initialize dlnetwork
            net = dlnetwork(lgraph);
            % Constraints monotonic
            lipschitzConstant = abs(net.Layers(end-2).ResidualScaling); 
        end
    
        
        [lipschitzParams,lipschitzIdx] = conslearn.lipschitz.getLipschitzParameterIdx(net,lipschitzConstant);
        params = net.Learnables;
        params(lipschitzIdx,:) = dlupdate(@(w,l)makeParametersMonotonic(w,l,pNorm),...
            params(lipschitzIdx,:),lipschitzParams(lipschitzIdx,:));
        net.Learnables = params;
    
        %Stdev path neural network------------------------------------------
        if stdev_scalar
            disp(sprintf('Stardard deviation is scalar'));
            if stdev_deepNN 
                disp(sprintf('Stardard deviation NN is deep'));
                sdevPath = [ 
                    fullyConnectedLayer(32,Name="stdInLyr")
                    reluLayer
                    fullyConnectedLayer(16)
                    reluLayer
                    fullyConnectedLayer(prod(ActionInfo.Dimension),'Name',"std_scalar",...
                        'WeightLearnRateFactor',0,...
                        'BiasLearnRateFactor',1,... 
                        'WeightsInitializer','zeros',...
                        'BiasInitializer','zeros')
                    softplusLayer(Name="StandardDeviationOutLyr")
                ];
            else
                sdevPath = [ 
                    fullyConnectedLayer(prod(ActionInfo.Dimension),'Name',"stdInLyr",...
                        'WeightLearnRateFactor',0,...
                        'BiasLearnRateFactor',1,... 
                        'WeightsInitializer','zeros',...
                        'BiasInitializer','zeros')
                    softplusLayer(Name="StandardDeviationOutLyr")
                ];
            end
        else
            if stdev_deepNN 
                disp(sprintf('Stardard deviation NN is deep'));
                 sdevPath = [ 
                            fullyConnectedLayer(32,Name="stdInLyr")
                            reluLayer
                            fullyConnectedLayer(16)
                            reluLayer
                            fullyConnectedLayer(prod(ActionInfo.Dimension))
                            softplusLayer(Name="StandardDeviationOutLyr")
                            ];
            else
                sdevPath = [ 
                            fullyConnectedLayer(prod(ActionInfo.Dimension),Name="stdInLyr")
                            softplusLayer(Name="StandardDeviationOutLyr")
                            ];
            end
    
        end
    
    
        % plot(net)
        % plot(lgraph)
        % analyzeNetwork(lgraph) 
        if add_residual_connection
            lgraph = net;   
            if resNet_connectingStyle == 2
                if length(numHiddenUnits) > 6
                    % Add 1st addition layer
                    tempLayers = additionLayer(2,"Name","res_add_1");
                    lgraph = addLayers(lgraph,tempLayers);
                    lgraph = connectLayers(lgraph,"activ_2","res_add_1/in1");
                    lgraph = disconnectLayers(lgraph,"fc_3","activ_4");
                    lgraph = connectLayers(lgraph,"fc_3","res_add_1/in2");
                    lgraph = connectLayers(lgraph,"res_add_1","activ_4");   
                    % Add 2nd addition layer
                    tempLayers = additionLayer(2,"Name","res_add_2");
                    lgraph = addLayers(lgraph,tempLayers);
                    lgraph = connectLayers(lgraph,"activ_5","res_add_2/in1");
                    lgraph = disconnectLayers(lgraph,"fc_6","activ_7");
                    lgraph = connectLayers(lgraph,"fc_6","res_add_2/in2");
                    lgraph = connectLayers(lgraph,"res_add_2","activ_7");
                    disp(sprintf('Residual connection 2 nodes'));
                else
                % Add addition layer
                    tempLayers = additionLayer(2,"Name","res_add_1");
                    lgraph = addLayers(lgraph,tempLayers);
                    lgraph = connectLayers(lgraph,"activ_2","res_add_1/in1");
                    lgraph = disconnectLayers(lgraph,"fc_3","activ_4");
                    lgraph = connectLayers(lgraph,"fc_3","res_add_1/in2");
                    lgraph = connectLayers(lgraph,"res_add_1","activ_4"); 
                    disp(sprintf('Residual connection 1 node'));
                end
            else
                % Add addition layer
                tempLayers = additionLayer(2,"Name","res_add_1");
                lgraph = addLayers(lgraph,tempLayers);
                lgraph = connectLayers(lgraph,"activ_2","res_add_1/in1");
                lgraph = disconnectLayers(lgraph,"activ_4","fc_4");
                lgraph = connectLayers(lgraph,"activ_4","res_add_1/in2");
                lgraph = connectLayers(lgraph,"res_add_1","fc_4");  
                if residual_connection_2unit
                    if length(numHiddenUnits) == 6
                        tempLayers = additionLayer(2,"Name","res_add_2");
                        lgraph = addLayers(lgraph,tempLayers);
                        lgraph = connectLayers(lgraph,"fc_4","res_add_2/in1");
                        lgraph = disconnectLayers(lgraph,"activ_6","fc_6");
                        lgraph = connectLayers(lgraph,"activ_6","res_add_2/in2");
                        lgraph = connectLayers(lgraph,"res_add_2","fc_6");
                        disp(sprintf('Residual connection 2 nodes'));
                    elseif numel(numHiddenUnits) > 6
                        tempLayers = additionLayer(2,"Name","res_add_2");
                        lgraph = addLayers(lgraph,tempLayers);
                        lgraph = connectLayers(lgraph,"fc_4","res_add_2/in1");
                        lgraph = disconnectLayers(lgraph,"activ_7","fc_7");
                        lgraph = connectLayers(lgraph,"activ_7","res_add_2/in2");
                        lgraph = connectLayers(lgraph,"res_add_2","fc_7");
                        disp(sprintf('Residual connection 2 nodes'));
                    end
                else
                    disp(sprintf('Residual connection 1 node'));
                end
            end
            net = lgraph ;
        end
    
        % Connect network
        actorNet = addLayers(net,sdevPath);
        actorNet = connectLayers(actorNet,"netObsInLyr","stdInLyr/in");
        actorNet = initialize(actorNet);
    else
        %Input layer
        tempLayers = [
            featureInputLayer(prod(ObservationInfo.Dimension),Name="netObsInLyr")
            ];
    
        %Activation function
        switch activation_fn 
            case 'fullsort'
                gnpFcn = @(k)iFullSortLayer("activ_" + k);
            case 'relu'
                gnpFcn = @(k)reluLayer(Name="activ_" + k);
            case 'tanh'
                gnpFcn = @(k)tanhLayer(Name="activ_" + k);
        end
        %Input neural network------------------------------------------
        tempLayers = [tempLayers
        fullyConnectedLayer(numHiddenUnits(1),Name="meanInLyr",WeightsInitializer="orthogonal")
        ];
        for ii = 2:numel(numHiddenUnits)
            if ii == numel(numHiddenUnits)
                tempLayers = [tempLayers
                    gnpFcn(ii)
                    fullyConnectedLayer(numHiddenUnits(ii),Name="MeanOutLyr",WeightsInitializer="orthogonal")
                    ];
            else
                tempLayers = [tempLayers
                    gnpFcn(ii)
                    fullyConnectedLayer(numHiddenUnits(ii),Name="fc_" + ii,WeightsInitializer="orthogonal")
                    ];
            end
        end
        net = dlnetwork(tempLayers);
        lgraph = net;   
        if add_residual_connection
            if resNet_connectingStyle == 2
                if length(numHiddenUnits) > 6
                    % Add 1st addition layer
                    tempLayers = additionLayer(2,"Name","res_add_1");
                    lgraph = addLayers(lgraph,tempLayers);
                    lgraph = connectLayers(lgraph,"activ_2","res_add_1/in1");
                    lgraph = disconnectLayers(lgraph,"fc_3","activ_4");
                    lgraph = connectLayers(lgraph,"fc_3","res_add_1/in2");
                    lgraph = connectLayers(lgraph,"res_add_1","activ_4");   
                    % Add 2nd addition layer
                    tempLayers = additionLayer(2,"Name","res_add_2");
                    lgraph = addLayers(lgraph,tempLayers);
                    lgraph = connectLayers(lgraph,"activ_5","res_add_2/in1");
                    lgraph = disconnectLayers(lgraph,"fc_6","activ_7");
                    lgraph = connectLayers(lgraph,"fc_6","res_add_2/in2");
                    lgraph = connectLayers(lgraph,"res_add_2","activ_7");
                    disp(sprintf('Residual connection 2 nodes'));
                else
                % Add addition layer
                    tempLayers = additionLayer(2,"Name","res_add_1");
                    lgraph = addLayers(lgraph,tempLayers);
                    lgraph = connectLayers(lgraph,"activ_2","res_add_1/in1");
                    lgraph = disconnectLayers(lgraph,"fc_3","activ_4");
                    lgraph = connectLayers(lgraph,"fc_3","res_add_1/in2");
                    lgraph = connectLayers(lgraph,"res_add_1","activ_4"); 
                    disp(sprintf('Residual connection 1 node'));
                end
            else
                % Add addition layer
                tempLayers = additionLayer(2,"Name","res_add_1");
                lgraph = addLayers(lgraph,tempLayers);
                lgraph = connectLayers(lgraph,"activ_2","res_add_1/in1");
                lgraph = disconnectLayers(lgraph,"activ_4","MeanOutLyr");
                lgraph = connectLayers(lgraph,"activ_4","res_add_1/in2");
                lgraph = connectLayers(lgraph,"res_add_1","MeanOutLyr"); 
            end
        end
        net= lgraph; 
        if stdev_scalar
            disp(sprintf('Stardard deviation is scalar'));
            sdevPath = [ 
                    fullyConnectedLayer(prod(ActionInfo.Dimension),'Name',"stdInLyr",...
                        'WeightLearnRateFactor',0,...
                        'BiasLearnRateFactor',1,... 
                        'WeightsInitializer','zeros',...
                        'BiasInitializer','zeros')
                    softplusLayer(Name="StandardDeviationOutLyr")
                ];
        else
            sdevPath = [ 
                        fullyConnectedLayer(prod(ActionInfo.Dimension),Name="stdInLyr")
                        softplusLayer(Name="StandardDeviationOutLyr")
                        ];
        end
        actorNet = addLayers(net,sdevPath);

        if connect_stdev_begin
            disp(sprintf('Stdev Path is connected at the beginning'));
            actorNet = connectLayers(actorNet,"netObsInLyr","stdInLyr/in");
        else
            disp(sprintf('Stdev Path is connected at the end'));
            actorNet = connectLayers(actorNet,"res_add_1","stdInLyr/in");
        end
        actorNet = initialize(actorNet);
    end

    % plot(actorNet)
    % analyzeNetwork(actorNet) 

    %End of modified
    %====================================================
    %====================================================
    %====================================================

    Actor = rlContinuousGaussianActor(actorNet, ObservationInfo, ActionInfo, ...
        ActionMeanOutputNames="MeanOutLyr",...
        ActionStandardDeviationOutputNames="StandardDeviationOutLyr",...
        ObservationInputNames="netObsInLyr");

    %[END] Create NN for actor as new nn =======================================
%    Actor = rl.function.rlContinuousGaussianActor.createDefault(ObservationInfo, ActionInfo, UseSquashInNetwork, InitOptions);
    Critic(1) = rl.function.rlQValueFunction.createDefault(ObservationInfo, ActionInfo, InitOptions);
    Critic(2) = rl.function.rlQValueFunction.createDefault(ObservationInfo, ActionInfo, InitOptions);
    %criticNet = getModel(Critic(1));
    %analyzeNetwork(criticNet) 
else
    error(message('rl:agent:errOnPolicyInvalidFirstArg'));
end
rl.util.validateAgentOptionType(AgentOptions,AgentType);
agent = rl.agent.rlSACAgent(Actor, Critic, AgentOptions);
end


function layer = iFullSortLayer(k)
layer = conslearn.layer.FullSortLayer(k);
end
