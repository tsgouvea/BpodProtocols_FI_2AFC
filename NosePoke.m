function NosePoke()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    %general
    TaskParameters.GUI.Ports_LMR = '123';
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
    TaskParameters.GUI.MinSampleIncr = 0.01;
    TaskParameters.GUI.MinSampleDecr = 0.005;
    TaskParameters.GUI.EarlyWithdrawalTimeOut = 1;
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
    TaskParameters.GUIMeta.SampleTime.Style = 'text';
    TaskParameters.GUIPanels.Sampling = {'MinSampleTime','MaxSampleTime','AutoIncrSample','MinSampleIncr','MinSampleDecr','EarlyWithdrawalTimeOut','SampleTime'};
    %Reward
    TaskParameters.GUI.rewardAmount = 30;
    TaskParameters.GUI.Deplete = true;
    TaskParameters.GUIMeta.Deplete.Style = 'checkbox';
    TaskParameters.GUI.DepleteRate = 0.8;
    TaskParameters.GUI.Jackpot = true;
    TaskParameters.GUIMeta.Jackpot.Style = 'checkbox';
    TaskParameters.GUI.JackpotMin = 1;
    TaskParameters.GUI.JackpotTime = 1;
    TaskParameters.GUIMeta.JackpotTime.Style = 'text';
        TaskParameters.GUIPanels.Reward = {'rewardAmount','Deplete','DepleteRate','Jackpot','JackpotMin','JackpotTime'};
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.SampleTime(1) = TaskParameters.GUI.MinSampleTime;
BpodSystem.Data.Custom.EarlyWithdrawal(1) = false;
BpodSystem.Data.Custom.Jackpot(1) = false;
BpodSystem.Data.Custom.RewardMagnitude = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);
%server data
BpodSystem.Data.Custom.Rig = getenv('computername');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));

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