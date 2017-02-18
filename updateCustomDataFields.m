function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters

%% Center port
statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});
if any(strcmp('Cin',statesThisTrial))
    if any(strcmp('stillSampling',statesThisTrial))
        if any(strcmp('stillSamplingJackpot',statesThisTrial))
            BpodSystem.Data.Custom.SampleTime(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSamplingJackpot(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1,1);
        else
            BpodSystem.Data.Custom.SampleTime(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSampling(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1,1);
        end
    else
        BpodSystem.Data.Custom.SampleTime(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin);
    end
end
%% Side ports
if any(strcmp('Lin',statesThisTrial)) || any(strcmp('Rin',statesThisTrial))
    Sin = statesThisTrial{strcmp('Lin',statesThisTrial)|strcmp('Rin',statesThisTrial)};
    if any(strcmp('stillLin',statesThisTrial)) || any(strcmp('stillRin',statesThisTrial))
        stillSin = statesThisTrial{strcmp('stillLin',statesThisTrial)|strcmp('stillRin',statesThisTrial)};
        BpodSystem.Data.Custom.FeedbackTime(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.(stillSin)(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.(Sin)(1,1);
    else
        BpodSystem.Data.Custom.FeedbackTime(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.(Sin));
    end
end
%%
if any(strcmp('Lin',statesThisTrial))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 1;
elseif any(strcmp('Rin',statesThisTrial))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 0;
end
BpodSystem.Data.Custom.EarlyCout(iTrial) = any(strcmp('EarlyCout',statesThisTrial));
BpodSystem.Data.Custom.EarlySout(iTrial) = any(strcmp('EarlyRout',statesThisTrial)) || any(strcmp('EarlyLout',statesThisTrial));
BpodSystem.Data.Custom.Rewarded(iTrial) = any(strncmp('water_',statesThisTrial,6));
BpodSystem.Data.Custom.Jackpot(iTrial) = any(strcmp('water_LJackpot',statesThisTrial)) || any(strcmp('water_RJackpot',statesThisTrial));

%% initialize next trial values
BpodSystem.Data.Custom.ChoiceLeft(iTrial+1) = NaN;
BpodSystem.Data.Custom.EarlyCout(iTrial+1) = false;
BpodSystem.Data.Custom.EarlySout(iTrial+1) = false;
BpodSystem.Data.Custom.Jackpot(iTrial+1) = false;
BpodSystem.Data.Custom.Rewarded(iTrial+1) = false;
BpodSystem.Data.Custom.SampleTime(iTrial+1) = NaN;
BpodSystem.Data.Custom.FeedbackTime(iTrial+1) = NaN;

%jackpot time
if  TaskParameters.GUI.Jackpot
    if sum(~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:iTrial)))>10
        TaskParameters.GUI.JackpotTime = max(TaskParameters.GUI.JackpotMin,quantile(BpodSystem.Data.Custom.SampleTime,0.95));
    else
        TaskParameters.GUI.JackpotTime = TaskParameters.GUI.JackpotMin;
    end
end

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
%% Center port
if TaskParameters.GUI.AutoIncrSample && sum(~isnan(BpodSystem.Data.Custom.SampleTime)) >= 10
    TaskParameters.GUI.SampleTime = prctile(BpodSystem.Data.Custom.SampleTime,TaskParameters.GUI.MinCutoff);
else
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
end
TaskParameters.GUI.SampleTime = max(TaskParameters.GUI.MinSampleTime,min(TaskParameters.GUI.SampleTime,TaskParameters.GUI.MaxSampleTime));

%% Side ports
if TaskParameters.GUI.AutoIncrSample && sum(~isnan(BpodSystem.Data.Custom.FeedbackTime)) >= 10
    TaskParameters.GUI.FeedbackTime = prctile(BpodSystem.Data.Custom.FeedbackTime(max(1,end-100):end),TaskParameters.GUI.MinCutoff);
else
    TaskParameters.GUI.FeedbackTime = TaskParameters.GUI.MinFeedbackTime;
end
TaskParameters.GUI.FeedbackTime = max(TaskParameters.GUI.MinFeedbackTime,min(TaskParameters.GUI.FeedbackTime,TaskParameters.GUI.MaxFeedbackTime));

%% send bpod status to server
try
    BpodSystem.Data.Custom.Script = 'receivebpodstatus.php';
    %create a common "outcome" vector
    outcome = BpodSystem.Data.Custom.ChoiceLeft(1:iTrial); %1=left, 0=right
    outcome(BpodSystem.Data.Custom.EarlyCout(1:iTrial))=3; %early C withdrawal=3
    outcome(BpodSystem.Data.Custom.Jackpot(1:iTrial))=4; %jackpot=4
    outcome(BpodSystem.Data.Custom.EarlySout(1:iTrial))=5; %early S withdrawal=5
    SendTrialStatusToServer(BpodSystem.Data.Custom.Script,BpodSystem.Data.Custom.Rig,outcome,BpodSystem.Data.Custom.Subject,BpodSystem.CurrentProtocolName);
catch
end
end