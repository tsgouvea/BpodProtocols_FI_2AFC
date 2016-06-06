function FI_2AFC_PlotSideOutcome(AxesHandle, Action, varargin)
global nTrialsToShow %this is for convenience
global BpodSystem

switch Action
    case 'init'
        %initialize pokes plot
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin >= 3 %custom number of trials
            nTrialsToShow =varargin{1};
        end
        axes(AxesHandle);
        %plot in specified axes
        BpodSystem.GUIHandles.CurrentTrialCircle = line(-1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.CurrentTrialCross = line(-1,0.5, 'LineStyle','none','Marker','+','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.RewardedL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.RewardedR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        set(AxesHandle,'TickDir', 'out','YLim', [-1, 2], 'YTick', [0 1],'YTickLabel', {'Right','Left'}, 'FontSize', 16);
        xlabel(AxesHandle, 'Trial#', 'FontSize', 18);
        hold(AxesHandle, 'on');
        
    case 'update'
        CurrentTrial = varargin{1};
        OutcomeRecord = BpodSystem.Data.Custom.OutcomeRecord;
        
        % recompute xlim
        [mn, mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow);
        
        set(BpodSystem.GUIHandles.CurrentTrialCircle, 'xdata', CurrentTrial, 'ydata', .5);
        set(BpodSystem.GUIHandles.CurrentTrialCross, 'xdata', CurrentTrial, 'ydata', .5);
        
        %Plot past trials
        if ~isempty(OutcomeRecord)
            indxToPlot = mn:CurrentTrial-1;
            %Plot Rewarded Left
            ndxRwdL = OutcomeRecord(indxToPlot) == 3;
            Xdata = indxToPlot(ndxRwdL); Ydata = ones(1,sum(ndxRwdL));
            set(BpodSystem.GUIHandles.RewardedL, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Rewarded Right
            ndxRwdR = OutcomeRecord(indxToPlot) == 4;
            Xdata = indxToPlot(ndxRwdR); Ydata = zeros(1,sum(ndxRwdR));
            set(BpodSystem.GUIHandles.RewardedR, 'xdata', Xdata, 'ydata', Ydata);            
        end
end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end


