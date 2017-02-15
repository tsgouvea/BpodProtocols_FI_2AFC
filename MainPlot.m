function MainPlot(Action, varargin)
global nTrialsToShow %this is for convenience
global BpodSystem
global TaskParameters

switch Action
    case 'init'
        %% Outcome
        %initialize pokes plot
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin >=3  %custom number of trials
            nTrialsToShow =varargin{2};
        end
        
        %         Xdata = 1:numel(SideList); Ydata = SideList(Xdata);
        %plot in specified axes
        
        %%
        axes(BpodSystem.GUIHandles.Axes.OutcomePlot.MainHandle)
        BpodSystem.GUIHandles.Axes.OutcomePlot.CurrentTrialCircle = line(-1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.Axes.OutcomePlot.CurrentTrialCross = line(-1,0.5, 'LineStyle','none','Marker','+','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.Axes.OutcomePlot.Rewarded = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.Axes.OutcomePlot.EarlyCout = line(-1,0, 'LineStyle','none','Marker','d','MarkerEdge','none','MarkerFace','b', 'MarkerSize',6);
        BpodSystem.GUIHandles.Axes.OutcomePlot.EarlySout = line(-1,0, 'LineStyle','none','Marker','d','MarkerEdge','none','MarkerFace','b', 'MarkerSize',6);
        BpodSystem.GUIHandles.Axes.OutcomePlot.Jackpot = line(-1,0, 'LineStyle','none','Marker','x','MarkerEdge','r','MarkerFace','r', 'MarkerSize',7);
        BpodSystem.GUIHandles.Axes.OutcomePlot.CumRwd = text(1,1,'0mL','verticalalignment','bottom','horizontalalignment','center');
        set(BpodSystem.GUIHandles.Axes.OutcomePlot.MainHandle,'TickDir', 'out','YLim', [-1, 2],'XLim',[0,nTrialsToShow], 'YTick', [0 1],'YTickLabel', {'Right','Left'}, 'FontSize', 16);
        xlabel(BpodSystem.GUIHandles.Axes.OutcomePlot.MainHandle, 'Trial#', 'FontSize', 18);
        hold(BpodSystem.GUIHandles.Axes.OutcomePlot.MainHandle, 'on');
        %% Trial rate
        hold(BpodSystem.GUIHandles.Axes.TrialRate.MainHandle,'on')
        BpodSystem.GUIHandles.Axes.TrialRate.TrialRate = line(BpodSystem.GUIHandles.Axes.TrialRate.MainHandle,[0],[0], 'LineStyle','-','Color','k','Visible','on');
        BpodSystem.GUIHandles.Axes.TrialRate.MainHandle.XLabel.String = 'Time (min)';
        BpodSystem.GUIHandles.Axes.TrialRate.MainHandle.YLabel.String = 'nTrials';
        BpodSystem.GUIHandles.Axes.TrialRate.MainHandle.Title.String = 'Trial rate';
        %% ST histogram
        hold(BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle,'on')
        BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle.XLabel.String = 'Time (s)';
        BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle.YLabel.String = 'trial counts';
        BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle.Title.String = 'Center port WT';
        %% FT histogram
        hold(BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle,'on')
        BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle.XLabel.String = 'Time (s)';
        BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle.YLabel.String = 'trial counts';
        BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle.Title.String = 'Side port WT';
    case 'update'
        % Outcome
        iTrial = varargin{1};
        [mn, ~] = rescaleX(BpodSystem.GUIHandles.Axes.OutcomePlot.MainHandle,iTrial,nTrialsToShow); % recompute xlim
        
        set(BpodSystem.GUIHandles.Axes.OutcomePlot.CurrentTrialCircle, 'xdata', iTrial, 'ydata', 0.5);
        set(BpodSystem.GUIHandles.Axes.OutcomePlot.CurrentTrialCross, 'xdata', iTrial, 'ydata', 0.5);
        
        %Plot past trials
        ChoiceLeft = BpodSystem.Data.Custom.ChoiceLeft;
        Rewarded = BpodSystem.Data.Custom.Rewarded;
        if ~isempty(Rewarded)
            indxToPlot = mn:iTrial-1;
            ndxRwd = Rewarded(indxToPlot) == 1;
            Xdata = indxToPlot(ndxRwd);
            Ydata = ChoiceLeft(indxToPlot); Ydata = Ydata(ndxRwd);
            set(BpodSystem.GUIHandles.Axes.OutcomePlot.Rewarded, 'xdata', Xdata, 'ydata', Ydata);
        end
        if ~isempty(BpodSystem.Data.Custom.EarlyCout)
            indxToPlot = mn:iTrial-1;
            ndxEarly = BpodSystem.Data.Custom.EarlyCout(indxToPlot);
            XData = indxToPlot(ndxEarly);
            YData = 0.5*ones(1,sum(ndxEarly));
            set(BpodSystem.GUIHandles.Axes.OutcomePlot.EarlyCout, 'xdata', XData, 'ydata', YData);
        end
        if ~isempty(BpodSystem.Data.Custom.EarlySout)
            indxToPlot = mn:iTrial-1;
            ndxEarly = BpodSystem.Data.Custom.EarlySout(indxToPlot);
            XData = indxToPlot(ndxEarly);
            YData = ChoiceLeft(indxToPlot); YData = YData(ndxEarly);
            set(BpodSystem.GUIHandles.Axes.OutcomePlot.EarlySout, 'xdata', XData, 'ydata', YData);
        end
        if ~isempty(BpodSystem.Data.Custom.Jackpot)
            indxToPlot = mn:iTrial-1;
            ndxJackpot = BpodSystem.Data.Custom.Jackpot(indxToPlot);
            XData = indxToPlot(ndxJackpot);
            YData = 0.5*ones(1,sum(ndxJackpot));
            set(BpodSystem.GUIHandles.Axes.OutcomePlot.Jackpot, 'xdata', XData, 'ydata', YData);
        end
        %Cumulative Reward Amount
        R = BpodSystem.Data.Custom.RewardMagnitude;
        ndxRwd = BpodSystem.Data.Custom.Rewarded;
        C = zeros(size(R)); C(BpodSystem.Data.Custom.ChoiceLeft==1&ndxRwd,1) = 1; C(BpodSystem.Data.Custom.ChoiceLeft==0&ndxRwd,2) = 1;
        R = R.*C;
        set(BpodSystem.GUIHandles.Axes.OutcomePlot.CumRwd, 'position', [iTrial+1 1], 'string', ...
            [num2str(sum(R(:))/1000) ' mL']);
        clear R C
        
        %% Trial rate
        BpodSystem.GUIHandles.Axes.TrialRate.TrialRate.XData = (BpodSystem.Data.TrialStartTimestamp-min(BpodSystem.Data.TrialStartTimestamp))/60;
        BpodSystem.GUIHandles.Axes.TrialRate.TrialRate.YData = 1:numel(BpodSystem.GUIHandles.Axes.TrialRate.TrialRate.XData);
        
        %% Stimulus delay
        cla(BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle)
        BpodSystem.GUIHandles.Axes.SampleTimes.Hist = histogram(BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle,...
            BpodSystem.Data.Custom.SampleTime(~BpodSystem.Data.Custom.EarlyCout)*1000);
        BpodSystem.GUIHandles.Axes.SampleTimes.Hist.BinWidth = 50;
        BpodSystem.GUIHandles.Axes.SampleTimes.Hist.EdgeColor = 'none';
        BpodSystem.GUIHandles.Axes.SampleTimes.HistEarly = histogram(BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle,...
            BpodSystem.Data.Custom.SampleTime(BpodSystem.Data.Custom.EarlyCout)*1000);
        BpodSystem.GUIHandles.Axes.SampleTimes.HistEarly.BinWidth = 50;
        BpodSystem.GUIHandles.Axes.SampleTimes.HistEarly.EdgeColor = 'none';
        BpodSystem.GUIHandles.Axes.SampleTimes.CutOff = plot(BpodSystem.GUIHandles.Axes.SampleTimes.MainHandle,TaskParameters.GUI.SampleTime*1000,0,'^k');
        
        %% Feedback delay
        cla(BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle)
        BpodSystem.GUIHandles.Axes.FeedbackTimes.Hist = histogram(BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle,BpodSystem.Data.Custom.FeedbackTime*1000);
        BpodSystem.GUIHandles.Axes.FeedbackTimes.Hist.BinWidth = 50;
        BpodSystem.GUIHandles.Axes.FeedbackTimes.Hist.EdgeColor = 'none';
        BpodSystem.GUIHandles.Axes.FeedbackTimes.HistEarly = histogram(BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle,...
            BpodSystem.Data.Custom.FeedbackTime(BpodSystem.Data.Custom.EarlySout)*1000);
        BpodSystem.GUIHandles.Axes.FeedbackTimes.HistEarly.BinWidth = 50;
        BpodSystem.GUIHandles.Axes.FeedbackTimes.HistEarly.EdgeColor = 'none';
        BpodSystem.GUIHandles.Axes.FeedbackTimes.CutOff = plot(BpodSystem.GUIHandles.Axes.FeedbackTimes.MainHandle,TaskParameters.GUI.FeedbackTime*1000,0,'^k');
        
end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end


