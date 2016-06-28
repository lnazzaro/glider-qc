function CheckDbdFlags(dbd,field,test)

% create plots to check flags for QARTOD tests
% 
% inputs:
%     dbd: single dbd instance/segment
%     field: string indicating the sensor being QC-tested
%     test: string indicating QARTOD test to view flags for
%         (options: 'gross range','climatological','spike',
%         'rate of change','flat line')

% each test will show a cross-section plot of the data from sensor 'field',
% with x's over non-passing data points indicating 'not
% evaluated', 'suspect', or 'failed' flags. additional plots specific to
% each test include:
%     gross range:
%         scatter plot of sensor values vs. time, with different markers
%         indicating flag status, plus lines showing test thresholds
%     climatological:
%         scatter plot of sensor values vs. time, with different markers
%         indicating flag status, plus lines showing test thresholds
%     spike:
%         separate figures for each profile in the segment,
%         with different colored markers for each flag; subplots for:
%             - depth vs. field
%             - depth vs. rate of change (with test thresholds)
%             - time vs. field
%             - time vs. rate of change (with test thresholds)
%     rate of change:
%         separate figures for each profile in the segment,
%         with different colored markers for each flag; subplots for:
%             - depth vs. field
%             - depth vs. rate of change (with test thresholds)
%             - time vs. field
%             - time vs. rate of change (with test thresholds)
%     flat line:
%         separate figures for each profile in the segment, thresholds in
%         title, with different colored markers for each flag;
%         subplots for:
%             - depth vs. field
%             - time vs. field
%         

test=lower(test);
test(test==' ')=[];
test(test=='_')=[];
test(test=='.')=[];
test(test=='-')=[];
if(strcmp(test(end-3:end),'test')|strcmp(test(end-3:end),'flag'))
    test=test(1:end-4);
end

switch test
    case 'grossrange'
        test='gross_range';
    case 'climatological'
    case 'climatology'
        test='climatological';
    case 'spike'
    case 'rateofchange'
        test='rate_of_change';
    case 'roc'
        test='rate_of_change';
    case 'flatline'
        test='flat_line';
    case 'stucksensor'
        test='flat_line';
    otherwise
        error(['Test ' test ' not a recognized option.'])
        return;
end

if(~ismember(field,dbd.sensors))
    error([field ' is not a sensor in the dbd segment'])
    return;
end
if(~ismember([field '_' test '_flag'],dbd.sensors))
    error([test ' does not have flag values in the dbd segment for field ' field])
    return;
end

data=dbd.toArray('sensors',{'drv_sci_m_present_time_datenum','drv_sci_water_pressure',field,[field '_' test '_flag']});
data=data(:,3:end);

filldot=max(data(:))+range(data(:))/5;

figure
scatter(data(:,1),data(:,2),50,data(:,3),'filled')
set(gca,'ydir','reverse')
caxis(quantile(data(:,3),[.025 .975]))
colorbar
hold on

ind1=find(data(:,4)==1);
ind2=find(data(:,4)==2);
ind3=find(data(:,4)==3);
ind4=find(data(:,4)==4);
ind9=find(data(:,4)==9);

s=[scatter([filldot;data(ind2,1)],[filldot;data(ind2,2)],150,'markeredgecolor','k','marker','x','linewidth',1.6),...
    scatter([filldot;data(ind3,1)],[filldot;data(ind3,2)],150,'markeredgecolor','m','marker','x','linewidth',1.6),...
    scatter([filldot;data(ind4,1)],[filldot;data(ind4,2)],150,'markeredgecolor','r','marker','x','linewidth',1.6),...
    scatter([filldot;data(ind9,1)],[filldot;data(ind9,2)],150,'linewidth',1.6,'marker','x','markeredgecolor',[.5 .5 .5])];

legend(s,{['Not Evaluated: ' int2str(length(ind2))],['Suspect: ' int2str(length(ind3))],...
    ['Fail: ' int2str(length(ind4))],['No Data: ' int2str(length(ind9))]})

xlim([min(data(:,1)) max(data(:,1))]+range(data(:,1))/10*[-1 1])
ylim([min(data(:,2)) max(data(:,2))]+range(data(:,2))/10*[-1 1])

datetick('x','HH:MM','keepticks','keeplimits')

xlabel('Time')
ylabel('Depth')
title([field ': ' test],'interpreter','none')
set(gcf,'windowstyle','docked')



switch test
    case 'gross_range'
        figure
        hold on
        s=[scatter([filldot;data(ind1,1)],[filldot;data(ind1,3)],'b','marker','.'),...
            scatter([filldot;data(ind2,1)],[filldot;data(ind2,3)],'k.'),...
            scatter([filldot;data(ind3,1)],[filldot;data(ind3,3)],'m.'),...
            scatter([filldot;data(ind4,1)],[filldot;data(ind4,3)],'r.'),...
            plot([min(data(:,1)) max(data(:,1))],...
            dbd.scratch.thresholds.(field).(test).suspect(1)*[1 1],'m'),...
            plot([min(data(:,1)) max(data(:,1))],...
            dbd.scratch.thresholds.(field).(test).fail(1)*[1 1],'r')];
        plot([min(data(:,1)) max(data(:,1))],...
            dbd.scratch.thresholds.(field).(test).fail(2)*[1 1],'r');
        plot([min(data(:,1)) max(data(:,1))],...
            dbd.scratch.thresholds.(field).(test).suspect(2)*[1 1],'m');
        xlabel('Time')
        xlim([min(data(:,1)) max(data(:,1))]+range(data(:,1))/10*[-1 1])
        ylim([min([data(:,3);dbd.scratch.thresholds.(field).(test).fail']) max([data(:,3);dbd.scratch.thresholds.(field).(test).fail'])]+range(data(:,3))/10*[-1 1])
        datetick('x','HH:MM','keepticks','keeplimits')
        ylabel(field,'interpreter','none')
        title('Gross Range Test')
        legend(s,{'Pass','Not Evaluated','Suspect','Fail','Suspect Threshold','Fail Threshold'})
        set(gcf,'windowstyle','docked')
    case 'climatological'
        figure
        hold on
        s=[scatter([filldot;data(ind1,1)],[filldot;data(ind1,3)],'b','marker','.'),...
            scatter([filldot;data(ind2,1)],[filldot;data(ind2,3)],'k.'),...
            scatter([filldot;data(ind3,1)],[filldot;data(ind3,3)],'m.'),...
            plot([min(data(:,1)) max(data(:,1))],...
            dbd.scratch.thresholds.(field).(test).suspect(1)*[1 1],'m')];
        plot([min(data(:,1)) max(data(:,1))],...
            dbd.scratch.thresholds.(field).(test).suspect(2)*[1 1],'m');
        xlabel('Time')
        xlim([min(data(:,1)) max(data(:,1))]+range(data(:,1))/10*[-1 1])
        ylim([min([data(:,3);dbd.scratch.thresholds.(field).(test).suspect']) max([data(:,3);dbd.scratch.thresholds.(field).(test).suspect'])]+range(data(:,3))/10*[-1 1])
        datetick('x','keepticks','keeplimits')
        ylabel(field,'interpreter','none')
        title('Climatological Test')
        legend(s,{'Pass','Not Evaluated','Suspect','Suspect Threshold'})
        set(gcf,'windowstyle','docked')
    case 'spike'
        for k=1:dbd.numProfiles
            proData=data(dbd.profileInds(k,1):dbd.profileInds(k,2),:);
            ind=find(~isnan(proData(:,3)));
            proData=proData(ind,:);
            proDir=diff(proData(:,2))./diff(proData(:,1));
            proDir=mode(proDir./abs(proDir));
            ind2=find(proData(:,4)==2);
            ind3=find(proData(:,4)==3);
            ind4=find(proData(:,4)==4);
            if(strcmp(dbd.scratch.thresholds.(field).(test).threshold_timestep,'1 second'))
                proData(2:end,end+1)=diff(proData(:,3))./(diff(proData(:,1))*24*60*60);
            elseif(strcmp(dbd.scratch.thresholds.(field).(test).threshold_timestep,'sensor resolution'))
                proData(2:end,end+1)=diff(proData(:,3));
            end
            figure
            subplot(1,4,1)
            xc=3;
            yc=2;
            plot(proData(:,xc),proData(:,yc),'b','marker','.')
            set(gca,'ydir','reverse')
            hold on
            s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled'),...
                scatter([filldot;proData(ind4,xc)],[filldot;proData(ind4,yc)],'r','filled')];
            legend(s,{'N/A','Suspect','Fail'})
            xlabel(field,'interpreter','none')
            ylabel('Depth')
            title('Spike Test')
            xlim([min(proData(:,xc)) max(proData(:,xc))]+range(proData(:,xc))/10*[-1 1])
            ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
            subplot(1,4,3)
            xc=3;
            yc=1;
            plot(proData(:,xc),proData(:,yc),'b','marker','.')
            if(proDir>0)
                set(gca,'ydir','reverse')
            end
            hold on
            s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled'),...
                scatter([filldot;proData(ind4,xc)],[filldot;proData(ind4,yc)],'r','filled')];
            legend(s,{'N/A','Suspect','Fail'})
            xlabel(field,'interpreter','none')
            ylabel('Time')
            xlim([min(proData(:,xc)) max(proData(:,xc))]+range(proData(:,xc))/10*[-1 1])
            ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
            datetick('y','HH:MM','keepticks','keeplimits')
            title('Spike Test')
            if(size(proData,2)==5)
                subplot(1,4,2)
                xc=5;
                yc=2;
                plot(proData(:,xc),proData(:,yc),'b','marker','.')
                set(gca,'ydir','reverse')
                hold on
                s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                    scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled'),...
                    scatter([filldot;proData(ind4,xc)],[filldot;proData(ind4,yc)],'r','filled')];
                plot([1 1]*dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                plot([1 1]*-dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                plot([1 1]*dbd.scratch.thresholds.(field).(test).fail,...
                    [min(proData(:,yc)) max(proData(:,yc))],'r');
                plot([1 1]*-dbd.scratch.thresholds.(field).(test).fail,...
                    [min(proData(:,yc)) max(proData(:,yc))],'r');
                legend(s,{'N/A','Suspect','Fail'})
                xlabel({field;['diff per ' dbd.scratch.thresholds.(field).(test).threshold_timestep]},'interpreter','none')
                ylabel('Depth')
                title('Spike Test')
                xlim([min([proData(:,xc);-dbd.scratch.thresholds.(field).(test).fail]) max([proData(:,xc);dbd.scratch.thresholds.(field).(test).fail])]+range(proData(:,xc))/10*[-1 1])
                ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
                subplot(1,4,4)
                xc=5;
                yc=1;
                plot(proData(:,xc),proData(:,yc),'b','marker','.')
                if(proDir>0)
                    set(gca,'ydir','reverse')
                end
                hold on
                s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                    scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled'),...
                    scatter([filldot;proData(ind4,xc)],[filldot;proData(ind4,yc)],'r','filled')];
                plot([1 1]*dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                plot([1 1]*-dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                plot([1 1]*dbd.scratch.thresholds.(field).(test).fail,...
                    [min(proData(:,yc)) max(proData(:,yc))],'r');
                plot([1 1]*-dbd.scratch.thresholds.(field).(test).fail,...
                    [min(proData(:,yc)) max(proData(:,yc))],'r');
                legend(s,{'N/A','Suspect','Fail'})
                xlabel({field;['diff per ' dbd.scratch.thresholds.(field).(test).threshold_timestep]},'interpreter','none')
                ylabel('Time')
                xlim([min([proData(:,xc);-dbd.scratch.thresholds.(field).(test).fail]) max([proData(:,xc);dbd.scratch.thresholds.(field).(test).fail])]+range(proData(:,xc))/10*[-1 1])
                ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
                datetick('y','HH:MM','keepticks','keeplimits')
                title('Spike Test')
            end
            set(gcf,'windowstyle','docked')
        end
    case 'rate_of_change'
        for k=1:dbd.numProfiles
            proData=data(dbd.profileInds(k,1):dbd.profileInds(k,2),:);
            ind=find(~isnan(proData(:,3)));
            proData=proData(ind,:);
            proDir=diff(proData(:,2))./diff(proData(:,1));
            proDir=mode(proDir./abs(proDir));
            ind2=find(proData(:,4)==2);
            ind3=find(proData(:,4)==3);
            if(strcmp(dbd.scratch.thresholds.(field).(test).threshold_timestep,'1 second'))
                proData(2:end,end+1)=diff(proData(:,3))./(diff(proData(:,1))*24*60*60);
            elseif(strcmp(dbd.scratch.thresholds.(field).(test).threshold_timestep,'sensor resolution'))
                proData(2:end,end+1)=diff(proData(:,3));
            end
            figure
            subplot(1,4,1)
            xc=3;
            yc=2;
            plot(proData(:,xc),proData(:,yc),'b','marker','.')
            set(gca,'ydir','reverse')
            hold on
            s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled')];
            legend(s,{'N/A','Suspect'})
            xlabel(field,'interpreter','none')
            ylabel('Depth')
            title('ROC Test')
            xlim([min(proData(:,xc)) max(proData(:,xc))]+range(proData(:,xc))/10*[-1 1])
            ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
            subplot(1,4,3)
            xc=3;
            yc=1;
            plot(proData(:,xc),proData(:,yc),'b','marker','.')
            if(proDir>0)
                set(gca,'ydir','reverse')
            end
            hold on
            s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled')];
            legend(s,{'N/A','Suspect'})
            xlabel(field,'interpreter','none')
            ylabel('Time')
            xlim([min(proData(:,xc)) max(proData(:,xc))]+range(proData(:,xc))/10*[-1 1])
            ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
            datetick('y','HH:MM','keepticks','keeplimits')
            title('ROC Test')
            if(size(proData,2)==5)
                subplot(1,4,2)
                xc=5;
                yc=2;
                plot(proData(:,xc),proData(:,yc),'b','marker','.')
                set(gca,'ydir','reverse')
                hold on
                s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                    scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled')];
                plot([1 1]*dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                plot([1 1]*-dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                legend(s,{'N/A','Suspect'})
                xlabel({field;['diff per ' dbd.scratch.thresholds.(field).(test).threshold_timestep]},'interpreter','none')
                ylabel('Depth')
                title('ROC Test')
                xlim([min([proData(:,xc);-dbd.scratch.thresholds.(field).(test).suspect]) max([proData(:,xc);dbd.scratch.thresholds.(field).(test).suspect])]+range(proData(:,xc))/10*[-1 1])
                ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
                subplot(1,4,4)
                xc=5;
                yc=1;
                plot(proData(:,xc),proData(:,yc),'b','marker','.')
                if(proDir>0)
                    set(gca,'ydir','reverse')
                end
                hold on
                s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                    scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled')];
                plot([1 1]*dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                plot([1 1]*-dbd.scratch.thresholds.(field).(test).suspect,...
                    [min(proData(:,yc)) max(proData(:,yc))],'m');
                legend(s,{'N/A','Suspect'})
                xlabel({field;['diff per ' dbd.scratch.thresholds.(field).(test).threshold_timestep]},'interpreter','none')
                ylabel('Time')
                xlim([min([proData(:,xc);-dbd.scratch.thresholds.(field).(test).suspect]) max([proData(:,xc);dbd.scratch.thresholds.(field).(test).suspect])]+range(proData(:,xc))/10*[-1 1])
                ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
                datetick('y','HH:MM','keepticks','keeplimits')
                title('ROC Test')
            end
            set(gcf,'windowstyle','docked')
        end
    case 'flat_line'
        for k=1:dbd.numProfiles
            proData=data(dbd.profileInds(k,1):dbd.profileInds(k,2),:);
            ind=find(~isnan(proData(:,3)));
            proData=proData(ind,:);
            proDir=diff(proData(:,2))./diff(proData(:,1));
            proDir=mode(proDir./abs(proDir));
            ind2=find(proData(:,4)==2);
            ind3=find(proData(:,4)==3);
            ind4=find(proData(:,4)==4);
            figure
            subplot(1,2,1)
            xc=3;
            yc=2;
            plot(proData(:,xc),proData(:,yc),'b','marker','.')
            set(gca,'ydir','reverse')
            hold on
            s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled'),...
                scatter([filldot;proData(ind4,xc)],[filldot;proData(ind4,yc)],'r','filled')];
            legend(s,{'N/A','Suspect','Fail'})
            xlabel(field,'interpreter','none')
            ylabel('Depth')
            title({'Flat Line Test';['eps=' num2str(dbd.scratch.thresholds.(field).(test).flat_line_range)];...
                ['suspect_ct=' int2str(dbd.scratch.thresholds.(field).(test).suspect_count),...
                '; fail_ct=' int2str(dbd.scratch.thresholds.(field).(test).fail_count)]},'interpreter','none')
            xlim([min(proData(:,xc)) max(proData(:,xc))]+range(proData(:,xc))/10*[-1 1])
            ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
            subplot(1,2,2)
            xc=3;
            yc=1;
            plot(proData(:,xc),proData(:,yc),'b','marker','.')
            if(proDir>0)
                set(gca,'ydir','reverse')
            end
            hold on
            s=[scatter([filldot;proData(ind2,xc)],[filldot;proData(ind2,yc)],'k','filled'),...
                scatter([filldot;proData(ind3,xc)],[filldot;proData(ind3,yc)],'m','filled'),...
                scatter([filldot;proData(ind4,xc)],[filldot;proData(ind4,yc)],'r','filled')];
            legend(s,{'N/A','Suspect','Fail'})
            xlabel(field,'interpreter','none')
            ylabel('Time')
            xlim([min(proData(:,xc)) max(proData(:,xc))]+range(proData(:,xc))/10*[-1 1])
            ylim([min(proData(:,yc)) max(proData(:,yc))]+range(proData(:,yc))/10*[-1 1])
            datetick('y','HH:MM','keepticks','keeplimits')
            title({'Flat Line Test';['eps=' num2str(dbd.scratch.thresholds.(field).(test).flat_line_range)];...
                ['suspect_ct=' int2str(dbd.scratch.thresholds.(field).(test).suspect_count),...
                '; fail_ct=' int2str(dbd.scratch.thresholds.(field).(test).fail_count)]},'interpreter','none')
            set(gcf,'windowstyle','docked')
        end
end

