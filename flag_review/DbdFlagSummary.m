function dbdsummary=DbdFlagSummary(dgroup,field,test)

% create a structured array with information on flags for 'test' in sensor
% 'field' in each individual segment; output includes start and end time of
% each segment, number profiles in each segment, total number of points in
% each segment, and number of points with each different flag value for
% 'test' in 'field'.
% 
% inputs:
%     dgroup: dbd group
%     field: string indicating the sensor being QC-tested
%     test: string indicating QARTOD test to view flags for
%         (options: 'gross range','climatological','spike',
%         'rate of change','flat line')
%     


test=lower(test);
test(test==' ')=[];
test(test=='_')=[];
test(test=='.')=[];
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

if(~ismember(field,dgroup.sensors))
    error([field ' is not a sensor in the dbd group'])
    return;
end
if(~ismember([field '_' test '_flag'],group.sensors))
    error([test ' does not have flag values in the dbd group for field ' field])
    return;
end

fillval=nan(length(dgroup.dbds),1);

dbdsummary.field=field;
dbdsummary.test=test;
dbdsummary.starttime=fillval;
dbdsummary.endtime=fillval;
dbdsummary.numprofiles=fillval;
dbdsummary.totalpts=fillval;
dbdsummary.flag1=fillval;
dbdsummary.flag2=fillval;
dbdsummary.flag3=fillval;
dbdsummary.flag4=fillval;
dbdsummary.flag9=fillval;

switch test
    case 'gross_range'
        dbdsummary.suspect=[fillval fillval];
        dbdsummary.fail=[fillval fillval];
    case 'climatological'
        dbdsummary.suspect=[fillval fillval];
    case 'spike'
        dbdsummary.suspect=fillval;
        dbdsummary.fail=fillval;
    case 'rate_of_change'
        dbdsummary.suspect=fillval;
    case 'flat_line'
        dbdsummary.eps=fillval;
        dbdsummary.suspect_count=fillval;
        dbdsummary.fail_count=fillval;
end


for n=1:length(dgroup.dbds)
    dbdsummary.starttime(n)=dgroup.dbds(n).startDatenum;
    dbdsummary.endtime(n)=dgroup.dbds(n).endDatenum;
    dbdsummary.numprofiles(n)=dgroup.dbds(n).numProfiles;
    data=dgroup.dbds(n).toArray('sensors',{field,[field '_' test '_flag']});
    dbdsummary.totalpts(n)=size(data,1);
    dbdsummary.flag1(n)=sum(data(:,4)==1);
    dbdsummary.flag2(n)=sum(data(:,4)==2);
    dbdsummary.flag3(n)=sum(data(:,4)==3);
    dbdsummary.flag4(n)=sum(data(:,4)==4);
    dbdsummary.flag9(n)=sum(data(:,4)==9);
    
    switch test
        case 'gross_range'
            dbdsummary.suspect(n,:)=dgroup.dbds(n).scratch.thresholds.(field).(test).suspect;
            dbdsummary.fail(n,:)=dgroup.dbds(n).scratch.thresholds.(field).(test).fail;
        case 'climatological'
            dbdsummary.suspect(n,:)=dgroup.dbds(n).scratch.thresholds.(field).(test).suspect;
        case 'spike'
            dbdsummary.suspect(n)=dgroup.dbds(n).scratch.thresholds.(field).(test).suspect;
            dbdsummary.fail(n)=dgroup.dbds(n).scratch.thresholds.(field).(test).fail;
        case 'rate_of_change'
            dbdsummary.suspect(n)=dgroup.dbds(n).scratch.thresholds.(field).(test).suspect;
        case 'flat_line'
            dbdsummary.eps(n)=dgroup.dbds(n).scratch.thresholds.(field).(test).flat_line_range;
            dbdsummary.suspect_count(n,:)=dgroup.dbds(n).scratch.thresholds.(field).(test).suspect_count;
            dbdsummary.fail_count(n,:)=dgroup.dbds(n).scratch.thresholds.(field).(test).fail_count;
    end
end

