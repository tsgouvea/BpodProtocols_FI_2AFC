function FI_2AFC
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem
%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    TaskParameters.GUI.FI = 5; % (s)
    TaskParameters.GUI.rewardAmount = 5;
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.OutcomeRecord = nan;
BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
FI_2AFC_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'init');
BpodNotebook('init');

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix(TaskParameters);
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
    
    updateCustomDataFields(TaskParameters)
    iTrial = iTrial + 1;
    FI_2AFC_PlotSideOutcome(BpodSystem.GUIHandles.SideOutcomePlot,'update',iTrial);
end
end

function sma = stateMatrix(TaskParameters)
ValveTimes  = GetValveTimes(TaskParameters.GUI.rewardAmount, [1 3]);
LeftValveTime = ValveTimes(1);
RightValveTime = ValveTimes(2);
clear ValveTimes

sma = NewStateMatrix();
sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'wait_Sin'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'wait_Sin',...
    'Timer',0,...
    'StateChangeConditions', {'Port1In','water_L','Port3In','water_R'},...
    'OutputActions',{'PWM1',255,'PWM3',255});
sma = AddState(sma, 'Name', 'water_L',...
    'Timer', LeftValveTime,...
    'StateChangeConditions', {'Tup','FI'},...
    'OutputActions', {'ValveState', 1});
sma = AddState(sma, 'Name', 'water_R',...
    'Timer', RightValveTime,...
    'StateChangeConditions', {'Tup','FI'},...
    'OutputActions', {'ValveState', 4});
sma = AddState(sma, 'Name', 'FI',...
    'Timer',TaskParameters.GUI.FI,...
    'StateChangeConditions',{'Tup','exit'},...
    'OutputActions',{});
%     sma = AddState(sma, 'Name', 'state_name',...
%         'Timer', 0,...
%         'StateChangeConditions', {},...
%         'OutputActions', {});
end

function updateCustomDataFields(TaskParameters)
global BpodSystem
%% OutcomeRecord
temp = BpodSystem.Data.RawData.OriginalStateData{end};
temp =  temp(temp==3|temp==4);
if ~isempty(temp)
    BpodSystem.Data.Custom.OutcomeRecord(end) = temp;
end
clear temp
if BpodSystem.Data.Custom.OutcomeRecord(end) == 3
    BpodSystem.Data.Custom.ChoiceLeft(end) = 1;
elseif BpodSystem.Data.Custom.OutcomeRecord(end) == 4
    BpodSystem.Data.Custom.ChoiceLeft(end) = 0;
end
BpodSystem.Data.Custom.OutcomeRecord(end+1) = NaN;
BpodSystem.Data.Custom.ChoiceLeft(end+1) = NaN;

end