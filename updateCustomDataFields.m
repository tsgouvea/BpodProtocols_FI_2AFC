function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters

%% OutcomeRecord
statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});
BpodSystem.Data.Custom.ST(iTrial) = NaN;
if any(strcmp('Cin',statesThisTrial))
    if any(strcmp('stillSampling',statesThisTrial))
        if any(strcmp('stillSamplingJackpot',statesThisTrial))
            BpodSystem.Data.Custom.ST(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSamplingJackpot(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1,1);
        else
            BpodSystem.Data.Custom.ST(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSampling(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1,1);
        end
    else
        BpodSystem.Data.Custom.ST(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin);
    end
end

if any(strncmp('water_L',statesThisTrial,7))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 1;
elseif any(strncmp('water_R',statesThisTrial,7))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 0;
elseif any(strcmp('EarlyWithdrawal',statesThisTrial))
    BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) = true;
end
if any(strcmp('water_LJackpot',statesThisTrial)) || any(strcmp('water_RJackpot',statesThisTrial))
    BpodSystem.Data.Custom.Jackpot(iTrial) = true;
end


%% initialize next trial values
BpodSystem.Data.Custom.ChoiceLeft(iTrial+1) = NaN;
BpodSystem.Data.Custom.EarlyWithdrawal(iTrial+1) = false;
BpodSystem.Data.Custom.Jackpot(iTrial+1) = false;

%jackpot time
if  TaskParameters.GUI.Jackpot
    if sum(~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:iTrial)))>10
        TaskParameters.GUI.JackpotTime = max(TaskParameters.GUI.JackpotMin,quantile(BpodSystem.Data.Custom.ST,0.95));
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
if TaskParameters.GUI.AutoIncrSample
    History = 50;
    Crit = 0.8;
    if iTrial<5
        ConsiderTrials = iTrial;
    else
        ConsiderTrials = max(1,iTrial-History):1:iTrial;
    end
    ConsiderTrials = ConsiderTrials(~isnan(BpodSystem.Data.Custom.ChoiceLeft(ConsiderTrials))|BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials));
    if sum(~BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials))/length(ConsiderTrials) > Crit
        if ~BpodSystem.Data.Custom.EarlyWithdrawal(iTrial)
            BpodSystem.Data.Custom.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial) + TaskParameters.GUI.MinSampleIncr));
        else
            BpodSystem.Data.Custom.SampleTime(iTrial+1) =  min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial)));
        end
    elseif sum(~BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials))/length(ConsiderTrials) < Crit/2
        if BpodSystem.Data.Custom.EarlyWithdrawal(iTrial)
            BpodSystem.Data.Custom.SampleTime(iTrial+1) = max(TaskParameters.GUI.MinSampleTime,min(TaskParameters.GUI.MaxSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial) - TaskParameters.GUI.MinSampleDecr));
        else
            BpodSystem.Data.Custom.SampleTime(iTrial+1) =   min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial)));
        end
    else
        BpodSystem.Data.Custom.SampleTime(iTrial+1) =  BpodSystem.Data.Custom.SampleTime(iTrial);
    end
else
    BpodSystem.Data.Custom.SampleTime(iTrial+1) = TaskParameters.GUI.MinSampleTime;
end
% if BpodSystem.Data.Custom.Jackpot(iTrial)
%     BpodSystem.Data.Custom.SampleTime(iTrial+1) = BpodSystem.Data.Custom.SampleTime(iTrial+1)+0.05*TaskParameters.GUI.JackpotTime;
% end
TaskParameters.GUI.SampleTime = BpodSystem.Data.Custom.SampleTime(iTrial+1);

%send bpod status to server
try
    script = 'receivebpodstatus.php';
    %create a common "outcome" vector
    outcome = BpodSystem.Data.Custom.ChoiceLeft(1:iTrial); %1=left, 0=right
    outcome(BpodSystem.Data.Custom.EarlyWithdrawal(1:iTrial))=3; %early withdrawal=3
    outcome(BpodSystem.Data.Custom.Jackpot(1:iTrial))=4;%jackpot=4
    SendTrialStatusToServer(script,BpodSystem.Data.Custom.Rig,outcome,BpodSystem.Data.Custom.Subject,BpodSystem.CurrentProtocolName);
catch
end
end