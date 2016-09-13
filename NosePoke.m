function NosePoke()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    TaskParameters.GUI.FI = 5; % (s)
    TaskParameters.GUI.rewardAmount = 20;
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    TaskParameters.GUI.VI = true;
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.Ports_LMR = '123';
    TaskParameters.GUI.MinSampleTime = 0.05;
    TaskParameters.GUI.ChoiceDeadline = 10;
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.OutcomeRecord = nan;
BpodSystem.Data.Custom.ChoiceLeft = NaN;
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
    
    updateCustomDataFields()
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
    'Timer', TaskParameters.GUI.MinSampleTime,...
    'StateChangeConditions', {CenterPortOut, 'ITI','Tup','wait_Sin'},...
    'OutputActions', {strcat('PWM',num2str(CenterPort)),255});
sma = AddState(sma, 'Name', 'wait_Sin',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {LeftPortIn,'water_L',RightPortIn,'water_R','Tup','ITI'},...
    'OutputActions',{strcat('PWM',num2str(LeftPort)),255,strcat('PWM',num2str(RightPort)),255});
sma = AddState(sma, 'Name', 'water_L',...
    'Timer', LeftValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', LeftValve});
sma = AddState(sma, 'Name', 'water_R',...
    'Timer', RightValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', RightValve});
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

function updateCustomDataFields()
global BpodSystem
global TaskParameters
%% OutcomeRecord
temp = BpodSystem.Data.RawData.OriginalStateData{end};
temp =  temp(temp==5|temp==6);
if ~isempty(temp)
    BpodSystem.Data.Custom.OutcomeRecord(end) = temp;
end
clear temp
if BpodSystem.Data.Custom.OutcomeRecord(end) == 5
    BpodSystem.Data.Custom.ChoiceLeft(end) = 1;
elseif BpodSystem.Data.Custom.OutcomeRecord(end) == 6
    BpodSystem.Data.Custom.ChoiceLeft(end) = 0;
end

BpodSystem.Data.Custom.OutcomeRecord(end+1) = NaN;
BpodSystem.Data.Custom.ChoiceLeft(end+1) = NaN;
BpodSystem.Data.Custom.RewardMagnitude(end+1,:) = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];

end