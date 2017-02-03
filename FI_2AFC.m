function FI_2AFC()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    % General
    TaskParameters.GUI.Ports_LMR = '123';
    TaskParameters.GUI.FI = 3; % (s)
    TaskParameters.GUI.VI = true;
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUIPanels.General = {'Ports_LMR','FI','VI','ChoiceDeadline'};
    % Center Port ("stimulus sampling")
    TaskParameters.GUI.MinSampleTime = 0.05;
    TaskParameters.GUI.MaxSampleTime = 1;
    TaskParameters.GUI.AutoIncrSample = true;
    TaskParameters.GUIMeta.AutoIncrSample.Style = 'checkbox';
    TaskParameters.GUI.MinSampleIncr = 0.01;
    TaskParameters.GUI.MinSampleDecr = 0.005;
    TaskParameters.GUI.EarlyWithdrawalTimeOut = 1;
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
    TaskParameters.GUIMeta.SampleTime.Style = 'text';
    TaskParameters.GUIPanels.CenterPort = {'MinSampleTime','MaxSampleTime','AutoIncrSample','MinSampleIncr','MinSampleDecr','EarlyWithdrawalTimeOut','SampleTime'};
     % Reward
    TaskParameters.GUI.rewardAmount = 30;
    TaskParameters.GUI.Deplete = true;
    TaskParameters.GUIMeta.Deplete.Style = 'checkbox';
    TaskParameters.GUI.DepleteRate = 0.8;
    TaskParameters.GUI.Jackpot = false;
    TaskParameters.GUIMeta.Jackpot.Style = 'checkbox';
    TaskParameters.GUI.JackpotMin = 1;
    TaskParameters.GUI.JackpotTime = 1;
    TaskParameters.GUIMeta.JackpotTime.Style = 'text';
    TaskParameters.GUIPanels.Reward = {'rewardAmount','Deplete','DepleteRate','Jackpot','JackpotMin','JackpotTime'};
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    % Side Ports ("waiting for feedback")
    TaskParameters.GUI.MinFeedbackTime = 0.05;
    TaskParameters.GUI.MaxFeedbackTime = 1;
    TaskParameters.GUI.AutoIncrFeedback = true;
    TaskParameters.GUIMeta.AutoIncrFeedback.Style = 'checkbox';
    TaskParameters.GUI.MinCutoff = 5; % New FeedbackTime as percentile of empirical distribution
    TaskParameters.GUI.EarlyWithdrEndsTrial = true;
    TaskParameters.GUIMeta.EarlyWithdrEndsTrial.Style = 'checkbox';
    TaskParameters.GUI.FeedbackTime = TaskParameters.GUI.MinFeedbackTime;
    TaskParameters.GUIMeta.FeedbackTime.Style = 'text';
    TaskParameters.GUIPanels.SidePorts = {'MinFeedbackTime','MaxFeedbackTime','AutoIncrFeedback','MinCutoff','EarlyWithdrEndsTrial','FeedbackTime'};   
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.EarlyWithdrawal(1) = false;
BpodSystem.Data.Custom.Jackpot(1) = false;
BpodSystem.Data.Custom.RewardMagnitude = [TaskParameters.GUI.rewardAmount,TaskParameters.GUI.rewardAmount];
BpodSystem.Data.Custom.Rewarded = false;
BpodSystem.Data.Custom.SampleTime(1) = NaN;
BpodSystem.Data.Custom.FeedbackTime(1) = NaN;

%server data
BpodSystem.Data.Custom.Rig = getenv('computername');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));

BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%% Initialize plots
BpodSystem.GUIHandles.Figs.MainFig = figure('Position', [200, 200, 1000, 400],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.Axes.OutcomePlot.MainHandle = axes('Position', [.06 .15 .91 .3]);
BpodSystem.GUIHandles.Axes.TrialRate.MainHandle = axes('Position', [[1 0]*[.06;.12] .6 .12 .3]);
BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle = axes('Position', [[2 1]*[.06;.12] .6 .12 .3]);
BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle = axes('Position', [[3 2]*[.06;.12] .6 .12 .3]);
MainPlot('init');
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
    MainPlot('update',iTrial);
end
end