function NosePoke()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    %general
    TaskParameters.GUI.Ports_LMR = '423';
    TaskParameters.GUI.FI = 1; % (s)
    TaskParameters.GUI.VI = false;
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUIPanels.General = {'Ports_LMR','FI','VI','ChoiceDeadline'};
    %"stimulus"
    TaskParameters.GUI.MinSampleTime = 0.05;
    TaskParameters.GUI.MaxSampleTime = 0.5;
    TaskParameters.GUI.AutoIncrSample = true;
    TaskParameters.GUIMeta.AutoIncrSample.Style = 'checkbox';
    TaskParameters.GUI.AutoIncrSampleAmount = 0.02;
    TaskParameters.GUI.EarlyWithdrawalTimeOut = 1;
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
    TaskParameters.GUIMeta.SampleTime.Style = 'text';
    TaskParameters.GUIPanels.Sampling = {'MinSampleTime','MaxSampleTime','AutoIncrSample','AutoIncrSampleAmount','EarlyWithdrawalTimeOut','SampleTime'};
    %Reward
    TaskParameters.GUI.rewardAmount = 30;
    TaskParameters.GUI.Deplete = true;
    TaskParameters.GUIMeta.Deplete.Style = 'checkbox';
    TaskParameters.GUI.DepleteRate = 0.8;
    TaskParameters.GUIPanels.Reward = {'rewardAmount','Deplete','DepleteRate'};
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.OutcomeRecord = nan;
BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.SampleTime(1) = TaskParameters.GUI.MinSampleTime;
BpodSystem.Data.Custom.EarlyWithdrawal(1) = false;
BpodSystem.Data.Custom.RewardMagnitude = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);


%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'init');
% BpodNotebook('init');

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix(iTrial);
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    updateCustomDataFields(iTrial)
    iTrial = iTrial + 1;
    NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'update',iTrial);
end
end

function sma = stateMatrix(iTrial)
global BpodSystem
global TaskParameters
%% Define ports
LeftPort = floor(mod(TaskParameters.GUI.Ports_LMR/100,10));
CenterPort = floor(mod(TaskParameters.GUI.Ports_LMR/10,10));
RightPort = mod(TaskParameters.GUI.Ports_LMR,10);
LeftPortOut = strcat('Port',num2str(LeftPort),'Out');
CenterPortOut = strcat('Port',num2str(CenterPort),'Out');
RightPortOut = strcat('Port',num2str(RightPort),'Out');
LeftPortIn = strcat('Port',num2str(LeftPort),'In');
CenterPortIn = strcat('Port',num2str(CenterPort),'In');
RightPortIn = strcat('Port',num2str(RightPort),'In');


LeftValve = 2^(LeftPort-1);
RightValve = 2^(RightPort-1);

LeftValveTime  = GetValveTimes(BpodSystem.Data.Custom.RewardMagnitude(iTrial,1), LeftPort);
RightValveTime  = GetValveTimes(BpodSystem.Data.Custom.RewardMagnitude(iTrial,2), RightPort);


sma = NewStateMatrix();
sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'wait_Cin'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'wait_Cin',...
    'Timer', 0,...
    'StateChangeConditions', {CenterPortIn, 'Cin'},...
    'OutputActions', {strcat('PWM',num2str(CenterPort)),255});
sma = AddState(sma, 'Name', 'Cin',...
    'Timer', BpodSystem.Data.Custom.SampleTime(iTrial),...
    'StateChangeConditions', {CenterPortOut, 'EarlyWithdrawal','Tup','wait_Sin'},...
    'OutputActions', {strcat('PWM',num2str(CenterPort)),255});
sma = AddState(sma, 'Name', 'wait_Sin',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {LeftPortIn,'water_L',RightPortIn,'water_R','Tup','ITI'},...
    'OutputActions',{strcat('PWM',num2str(LeftPort)),0,strcat('PWM',num2str(RightPort)),0});
sma = AddState(sma, 'Name', 'water_L',...
    'Timer', LeftValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', LeftValve});
sma = AddState(sma, 'Name', 'water_R',...
    'Timer', RightValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', RightValve});
sma = AddState(sma, 'Name', 'EarlyWithdrawal',...
    'Timer', TaskParameters.GUI.EarlyWithdrawalTimeOut,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {});
if TaskParameters.GUI.VI
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',exprnd(TaskParameters.GUI.FI),...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
else
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',TaskParameters.GUI.FI,...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
end

end

function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters

%% OutcomeRecord
statesVisited = BpodSystem.Data.RawData.OriginalStateData{iTrial};
temp =  statesVisited(statesVisited==5|statesVisited==6);
if ~isempty(temp)
    BpodSystem.Data.Custom.OutcomeRecord(iTrial) = temp;
end
clear temp
if BpodSystem.Data.Custom.OutcomeRecord(iTrial) == 5
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 1;
elseif BpodSystem.Data.Custom.OutcomeRecord(iTrial) == 6
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 0;
end

% BpodSystem.Data.Custom.SamplingTime = BpodSystem.Data.RawEvents.Trial{iTrial}.States.unrewarded_Lin

if ismember(7,statesVisited)
    BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) = true;
end

%% initialize next trial values
BpodSystem.Data.Custom.OutcomeRecord(iTrial+1) = NaN;
BpodSystem.Data.Custom.ChoiceLeft(iTrial+1) = NaN;
BpodSystem.Data.Custom.EarlyWithdrawal(iTrial+1) = false;

%reward depletion
if BpodSystem.Data.Custom.ChoiceLeft(iTrial) == 1 && TaskParameters.GUI.Deplete
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,1) = BpodSystem.Data.Custom.RewardMagnitude(iTrial,1)*TaskParameters.GUI.DepleteRate;
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,2) = TaskParameters.GUI.rewardAmount;
elseif BpodSystem.Data.Custom.ChoiceLeft(iTrial) == 0 && TaskParameters.GUI.Deplete
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,2) = BpodSystem.Data.Custom.RewardMagnitude(iTrial,2)*TaskParameters.GUI.DepleteRate;
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,1) = TaskParameters.GUI.rewardAmount;
elseif isnan(BpodSystem.Data.Custom.ChoiceLeft(iTrial)) && TaskParameters.GUI.Deplete
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,:) = BpodSystem.Data.Custom.RewardMagnitude(iTrial,:);
else
    BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,:) = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
end

%increase sample time
if TaskParameters.GUI.AutoIncrSample
    History = 50;
    Crit = 0.8;
    if iTrial<10
        ConsiderTrials = iTrial;
    else
        ConsiderTrials = max(1,iTrial-History):1:iTrial;
    end
    ConsiderTrials = ConsiderTrials(~isnan(BpodSystem.Data.Custom.ChoiceLeft(ConsiderTrials))|BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials));
    if sum(~BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials))/length(ConsiderTrials) > Crit
        BpodSystem.Data.Custom.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial) + TaskParameters.GUI.AutoIncrSampleAmount));
    else
        BpodSystem.Data.Custom.SampleTime(iTrial+1) = max(TaskParameters.GUI.MinSampleTime,min(TaskParameters.GUI.MaxSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial) - TaskParameters.GUI.AutoIncrSampleAmount));
    end
else
    BpodSystem.Data.Custom.SampleTime(iTrial+1) = TaskParameters.GUI.MinSampleTime;
end
TaskParameters.GUI.SampleTime = BpodSystem.Data.Custom.SampleTime(iTrial+1);

    
end
end