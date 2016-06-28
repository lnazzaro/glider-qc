function [clim_minsuspect,clim_maxsuspect,spike_thres,spike_fail,roc_thres,depthcats,method]=...
    getVariableQCLimits(dgroup,field,varargin)

% Get non-manufacturer-defined thresholds for glider data, either from
% excel file containing thresholds or estimated based on data contained in
% the deployment.
% 
% Outputs:
%     clim_minsuspect: minimum suspect threshold for climatology test
%     clim_maxsuspect: maximum suspect threshold for climatology test
%     spike_thres: suspect rate threshold for spike test (per second)
%     spike_fail: failing rate threshold for spike test (per second)
%     roc_thres: rate of change threshold for rate of change test (per second)
%     depthcats: nx2 array of depth subdivisions for thresholds
%     method: method of obtaining thresholds (from file vs. from earlier data)
%     
% Inputs:
%     dgroup: entire dbd group
%     field: sensor to get thresholds for
%     varargin:
%         'region': string, region the glider is deployed in; by default is
%             derived from glider location and list of available regions,
%             if no specific region is supplied
%         'depthvarying': logical, whether or not thresholds should vary
%             with depth (default: false)
%         'method': 'file' or 'earlierdata'; whether to take thresholds
%             from existing excel file or to estimate them from data 
%             already in the dbd group (default: file, as long as necessary
%             info is present)
%         'file': string indicating filename of excel file containing
%             thresholds
%         'newdbds': array of indices of dbd segments in need of QC
%         'depthcategories': specific depth ranges to get thresholds for,
%             if different from depth ranges in excel file


caller = [mfilename '.m'];

if nargin <2
    fprintf(2,...
        '%s E: not enough arguments.\n',...
        caller);
    return;
elseif ~ischar(field)
    fprintf(2,'%s E: ''field'' input must be a string.\n',caller);
    return;
end

try
    if(~ismember(field,dgroup.sensors))
        fprintf(2,'%s E: field %s not a valid sensor in dgroup.\n',caller,field);
        return;
    end
catch err
    fprintf(2,[caller ' E: ' err.message]);
    return;
end


% defaults
clim_minsuspect=nan;
clim_maxsuspect=nan;
spike_thres=nan;
spike_fail=nan;
roc_thres=nan;
file='climatological_sensor_limits.xlsx';
method='file';
region=[];
depthvarying=false;
filedepth=true;
newdbds=[];
depthcats=[0 20;20 40;40 60;60 100;100 200;200 1000];

if(iscell(varargin)&length(varargin)==1)
    varargin=varargin{1};
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    switch lower(name)
        case 'region'
            if(~ischar(value))
                warning('%s E: Value for %s must be a string. Ignoring...\n',caller,name);
            else
                region=value;
            end
        case 'depthvarying' % whether thresholds should vary with depth
            if(~islogical(value)|length(value)>1)
                fprintf('%s E: Value for %s must be a single element logical.\n',caller,name);
                return;
            end
            depthvarying=value;
        case 'method' % obtain thresholds from excel file or estimate from earlier data
            if(~ischar(value))
                warning('%s E: Value for %s must be a string. Using default...\n',caller,name);
            elseif(~ismember(value,{'file','earlierdata'}))
                warning('%s E: %s not an available %s option. Using default...\n',caller,value,name);
            else
                method=value;
            end
        case 'file' % name of excel file containing thresholds
            file=value;
        case 'newdbds' % indices of new segments to QC
            if(~isnumeric(value))
                warning('%s E: Value for %s must be an array of integers. Defaulting to entire dbd group...\n',caller,name);
            else
                newdbds=value;
            end
        case 'depthcategories' % specific depth zones to get thresholds for
            if(~isnumeric(value))
                warning('%s E: Value for %s must be numeric. Using default...\n',caller,name)
            elseif(size(value,2)~=2)
                warning('%s E: Value for %s must be an nx2 matrix. Using default...\n',caller,name)
            else
                if(any(value(:)<0))
                    value=-value;
                end
                if(value(1,1)>value(1,2))
                    value=value(:,2:-1:1);
                end
                if(any(value(:)<0)|min(value(:,2)-value(:,1))<0)
                    warning('%s E: Value for %s is in an unrecognized format. Using default...\n',caller,name)
                else
                    depthcat=value;
                    filedepth=false;
                end
            end
        otherwise
            fprintf(2,...
                '%s E: Unknown option specified: %s\n',...
                caller,...
                name);
            return;
    end
end

torig=dgroup.timestampSensors;
dorig=dgroup.depthSensors;
dgroup.timestampSensors='drv_sci_m_present_time_datenum';
dgroup.depthSensors='drv_sci_water_pressure';

if(isempty(newdbds))
    [dataloc,~]=toArray(dgroup,'sensors',{'drv_longitude','drv_latitude'});
else
    dataloc=[];
    for n=1:length(newdbds)
        [dataloctemp,~]=toArray(dgroup.dbds(n),'sensors',{'drv_longitude','drv_latitude'});
        dataloc=[dataloc;dataloctemp];
    end
end
mintime=min(dataloc(:,1));
maxtime=max(dataloc(:,1));
meanlon=nanmean(dataloc(:,3));
meanlat=nanmean(dataloc(:,4));
meantime=nanmean([mintime maxtime]);


if(~depthvarying)
    depthcats=[];
end

if(strcmpi(method,'file'))
    if(~ischar(file))
        warning('%s E: Value for %s must be a valid file name string. Using earlier data to estimate thresholds...\n',caller,name);
        method='earlierdata';
    elseif(~exist(file,'file'))
        warning('%s E: File not found. Using earlier data to estimate thresholds...\n',caller,name);
        method='earlierdata';
    else
        indext=find(file=='.');
        if(isempty(indext))
            warning('%s E: Value for %s must be a valid file name. Using earlier data to estimate thresholds...\n',caller,name);
            method='earlierdata';
        else
            if(~strcmpi(file(indext(end)+1:indext(end)+3),'xls'))
                warning('%s E: %s must be an Excel spreadsheet. Using earlier data to estimate thresholds...\n',caller,name);
                method='earlierdata';
            end
        end
    end
end

if(strcmpi(method,'file'))
    [~,sheets]=xlsfinfo(file);
    fieldname='';
    unitname='';
    unitconversion=1;
    
    if(length(sheets)==1)
        [~,~,limits]=xlsread(file);
    elseif(~ismember('limits',sheets))
        warning('%s E: Worksheet ''limits'' not found in file %s. Using earlier data to estimate thresholds...\n.',caller,file);
        method='earlierdata';
    else
        [~,~,limits]=xlsread(file,'limits');
    end
    limits(strcmpi(limits,''))={'nan'};
end

if(strcmpi(method,'file'))
    regioncol=find(strcmpi('region',lower(limits(1,:))));
    if(isempty(regioncol))
        warning('%s Warning: No ''region'' section in %s. Assuming entire file applies to current region.\n',caller,file);
    else
        if(isempty(region))
            if(~exist('regional_defined_boundaries.txt','file'))
                warning('%s E: No region supplied and file ''regional_defined_boundaries.txt'' listing regions with defined boundaries not in path. Using earlier data to estimate thresholds...\n',caller);
                method='earlierdata';
            else
                fid=fopen('regional_defined_boundaries.txt');
                region_options=textscan(fid,'%s','delimiter',',');
                region_options=region_options{1};
                fclose(fid);
                n=1;
                while(n<=length(region_options)&isempty(region))
                    try
                        fid=fopen([region_options{n} '_boundary.txt']);
                        region_bounds=textscan(fid,'%s%s','delimiter',',');
                        fclose(fid);
                        eval([region_bounds{1}{1} '=str2num(char(region_bounds{1}(2:end)));'])
                        eval([region_bounds{2}{1} '=str2num(char(region_bounds{2}(2:end)));'])
                        if(LonBound(1)~=LonBound(end)|LatBound(1)~=LatBound(end))
                            LonBound(end+1)=LonBound(1);
                            LatBound(end+1)=LatBound(1);
                        end
                        if(all(LonBound>=0)&meanlon<0)
                            meanlon=meanlon+360;
                        elseif(all(LonBound<=0)&meanlon>0)
                            meanlon=meanlon-360;
                        end
                        if(inpolygon(meanlon,meanlat,LonBound,LatBound))
                            region=region_options{n};
                        end
                        clear region_bounds LonBound LatBound
                    end
                    n=n+1;
                end
                if(isempty(region))
                    warning('%s E: No region found for lon=%f, lat=%f. Using earlier data to estimate thresholds...\n',caller,meanlon,meanlat);
                    method='earlierdata';
                else
                    indregion=strcmpi(region,limits(:,regioncol));
                    if(isempty(indregion))
                        warning('%s E: Region %s not found in file %s. Using earlier data to estimate thresholds...\n',caller,region,file);
                        method='earlierdata';
                    else
                        indregion(1)=true;
                        limits=limits(indregion,:);
                    end
                end
            end
        end
    end
end


if(strcmpi(method,'file'))
    if(length(sheets)==1|~ismember('field_conversion',sheets))
        fieldcol=find(strcmpi('field',lower(limits(1,:))));
        fieldnames=unique(limits(2:end,fieldcol));
        for n=1:length(fieldnames)
            if(strfind(lower(field),lower(fieldnames{n})))
                fieldname=fieldnames{n};
                break;
            end
        end
    else
        [~,~,fieldnames]=xlsread(file,'field_conversion');
        fromcol=find(strcmpi('dbd_field',lower(fieldnames(1,:))));
        tocol=find(strcmpi('general_field',lower(fieldnames(1,:))));
        for n=2:size(fieldnames,1)
            if(strfind(lower(field),lower(fieldnames{n,fromcol})))
                fieldname=fieldnames{n,tocol};
            end
        end
    end
    if(isempty(fieldname))
        warning('%s E: Nothing matching field %s found in file %s. Using earlier data to estimate thresholds...\n',caller,field,file);
        method='earlierdata';
    end
end

if(strcmpi(method,'file'))
    if(length(sheets)==1|~ismember('unit_conversion',sheets))
        fieldcol=find(strcmpi('field',lower(limits(1,:))));
        unitcol=find(strcmpi('units',lower(limits(1,:))));
        fieldind=strcmpi(fieldname,limits(:,fieldcol));
        fieldunits=unique(lower(limits(fieldind,unitcol)));
        if(strcmpi(lower(dgroup.sensorUnits.(field)),'nodim')|isempty(dgroup.sensorUnits.(field)))
            if(length(fieldunits)>1)
                warning('%s E: No unit defined for %s and multiple units included in %s. Using earlier data to estimate thresholds...\n',caller,field,file);
                method='earlierdata';
            else
                unitname=fieldunits{1};
            end
        elseif(ismember(lower(dgroup.sensorUnits.(field)),fieldunits))
            unitname=lower(dgroup.sensorsUnits.(field));
        else
            warning('%s E: No unit matching %s for field %s in file %s. Using earlier data to estimate thresholds...\n',caller,dgroup.sensorUnits.(field),field,file);
            method='earlierdata';
        end
    else
        [~,~,unitnames]=xlsread(file,'unit_conversion');
        fieldcol=find(strcmpi('field',lower(unitnames(1,:))));
        unitcol=find(strcmpi('units',lower(limits(1,:))));
        fromcol=find(strcmpi('end_unit',lower(unitnames(1,:))));
        tocol=find(strcmpi('start_unit',lower(unitnames(1,:))));
        convcol=find(strcmpi('conversion',lower(unitnames(1,:))));
        fieldind=strcmpi(fieldname,unitnames(:,fieldcol));
        if(isempty(dgroup.sensorUnits.(field))|strcmpi(dgroup.sensorUnits.(field),'nodim'))
            allunits=unique(lower(unitnames(fieldind,tocol)));
            if(length(allunits)>1)
                warning('%s E: No unit defined for %s and multiple units included in %s. Using earlier data to estimate thresholds...\n',caller,field,file);
                method='earlierdata';
            else
                unitname=allunits{1};
            end
        else
            unitind=strcmpi(dgroup.sensorUnits.(field),unitnames(:,fromcol));
            unitind=find(fieldind&unitind);
            if(length(unitind)>1)
                warning('%s E: Multiple unit conversions from %s for %s in %s. Using earlier data to estimate thresholds...\n',caller,dgroup.sensorUnits.(field),field,file);
                method='earlierdata';
            elseif(isempty(unitind))
                warning('%s E: No unit conversion from %s for %s in %s. Using earlier data to estimate thresholds...\n',caller,dgroup.sensorUnits.(field),field,file);
                method='earlierdata';
            else
                unitname=lower(unitnames{unitind,tocol});
                unitconversion=unitnames{unitind,convcol};
            end
        end
    end
end

if(strcmpi(method,'file'))
    ind=find(strcmpi(fieldname,limits(:,fieldcol))&strcmpi(unitname,limits(:,unitcol)));
    ind=[1;ind];
    limits=limits(ind,:);
    starttcol=find(strcmpi('starttime',lower(limits(1,:))));
    endtcol=find(strcmpi('endtime',lower(limits(1,:))));
    [~,m,d]=datevec(meantime);
    t0=datenum(2012,m,d);
    ind=1;
    for n=2:size(limits,1)
        [~,m1,d1]=datevec(limits{n,starttcol});
        [~,m2,d2]=datevec(limits{n,endtcol});
        t1=datenum(2012,m1,d1);
        t2=datenum(2012,m2,d2);
        if(t2>t1)
            if(t2>=t0&t0>=t1)
                ind=[ind;n];
            end
        elseif(t2<t1)
            if(t1>=t0|t0>=t2)
                ind=[ind;n];
            end
        end
    end
    if(length(ind)==1)
        warning('%s E: No thresholds found for current time period in file %s. Using earlier data to estimate thresholds...\n',caller,file);
        method='earlierdata';
    else
        limits=limits(ind,:);
    end
end

if(strcmpi(method,'file'))
    col=find(strcmpi('shallow_depth',lower(limits(1,:))));
    filedepthcats=[];
    if(~isempty(col))
        filedepthcats=[filedepthcats,cell2mat(limits(2:end,col))];
    end
    col=find(strcmpi('deep_depth',lower(limits(1,:))));
    if(~isempty(col))
        filedepthcats=[filedepthcats,cell2mat(limits(2:end,col))];
    end
    filedepthcats=abs(filedepthcats);
    col=find(strcmpi('min_suspect',lower(limits(1,:))));
    if(~isempty(col))
        fileclim_minsuspect=cell2mat(limits(2:end,col));
    end
    col=find(strcmpi('max_suspect',lower(limits(1,:))));
    if(~isempty(col))
        fileclim_maxsuspect=cell2mat(limits(2:end,col));
    end
    col=find(strcmpi('spike_suspect',lower(limits(1,:))));
    if(~isempty(col))
        filespike_thres=cell2mat(limits(2:end,col));
    end
    col=find(strcmpi('spike_fail',lower(limits(1,:))));
    if(~isempty(col))
        filespike_fail=cell2mat(limits(2:end,col));
    end
    col=find(strcmpi('roc_suspect',lower(limits(1,:))));
    if(~isempty(col))
        fileroc_thres=cell2mat(limits(2:end,col));
    end
    checkthres=[fileclim_minsuspect;fileclim_maxsuspect;filespike_thres;...
        filespike_fail;fileroc_thres];
    if(isnan(nanmean(checkthres(:))))
        warning('%s E: No thresholds found for field %s at time %s in file %s. Using earlier data to estimate thresholds...\n',caller,field,datestr(meantime,'mmm dd yyyy'),file);
        method='earlierdata';
    elseif((isempty(filedepthcats)|isnan(nanmean(filedepthcats)))&depthvarying)
        warning('%s E: No depth categories for field %s at time %s in file %s. Ignoring depth variability...',caller,field,datestr(meantime,'mmm dd yyyy'),file);
        depthvarying=false;
    end
end

if(strcmpi(method,'file'))
    if(~depthvarying)
        depthcats=nan;
        clim_minsuspect=min(fileclim_minsuspect);
        clim_maxsuspect=max(fileclim_maxsuspect);
        spike_thres=max(filespike_thres);
        spike_fail=max(filespike_fail);
        roc_thres=max(fileroc_thres);
    elseif(filedepth)
        depthcats=filedepthcats;
        clim_minsuspect=fileclim_minsuspect;
        clim_maxsuspect=fileclim_maxsuspect;
        spike_thres=filespike_thres;
        spike_fail=filespike_fail;
        roc_thres=fileroc_thres;
    else
        clim_minsuspect=nan(size(depthcats,1),1);
        clim_maxsuspect=clim_minsuspect;
        spike_thres=clim_minsuspect;
        spike_fail=clim_minsuspect;
        roc_thres=clim_minsuspect;
        ind=find(isnan(depthcats(:,1)));
        depthcats(ind,1)=0;
        d1=filedepthcats(:,1);
        d1(isnan(d1))=0;
        d2=filedepthcats(:,2);
        if(any(isnan(d2))&any(isnan(depthcats(:,2))))
            maxd=max([d2;depthcats(:,2)])+max(depthcats(:,2)-depthcats(:,1));
        else
            maxd=max([d2;depthcats(:,2)]);
        end
        d2(isnan(d2))=maxd;
        for n=1:size(depthcats,1)
            ds=depthcats(n,1);
            dd=depthcats(n,2);
            if(isnan(ds))
                ds=0;
            end
            if(isnan(dd))
                dd=maxd;
            end
            ddf=dd2;
            dsf=dd1;
            ddf(ddf>dd)=dd;
            dsf(dsf<ds)=ds;
            w1=ddf-ds;
            w2=dd-dsf;
            w1(w1<0)=0;
            w2(w2<0)=0;
            w=w1+w2;
            w(d2<ds|d1>dd)=0;
            if(sum(w)==0)
                clim_minsuspect(n)=nan;
                clim_maxsuspect(n)=nan;
                spike_thres(n)=nan;
                spike_fail(n)=nan;
                roc_thres(n)=nan;
            else
                clim_minsuspect(n)=(fileclim_minsuspect.*w)/(ones(size(w)).*w);
                clim_maxsuspect(n)=(fileclim_maxsuspect.*w)/(ones(size(w)).*w);
                spike_thres(n)=(filespike_thres.*w)/(ones(size(w)).*w);
                spike_fail(n)=(filespike_fail.*w)/(ones(size(w)).*w);
                roc_thres(n)=(fileroc_thres.*w)/(ones(size(w)).*w);
            end
        end
    end
end


if(strcmpi(method,'earlierdata'))
    [data,~]=toArray(dgroup,'sensors',field,'t0',mintime-15,'t1',maxtime+15);
    ind=find(isnan(sum(data,2))|data(:,3)==0);
    data(ind,:)=[];
    data=sortrows(data,1);
    time=data(:,1);
    depth=data(:,2);
    var=data(:,3);
    timediff=diff(time)*24*60*60;
    vardiff=diff(var);
    depthdiff=depth(2:end);
    ind=find(timediff<5*60);
    timediff=timediff(ind);
    vardiff=vardiff(ind);
    depthdiff=depthdiff(ind);
    dxdt=vardiff./timediff;
    if(~depthvarying)
        depthcats=nan;
        iqr=quantile(var,.75)-quantile(var,.25);
        clim_minsuspect=quantile(var,.25)-1.5*iqr;
        clim_maxsuspect=quantile(var,.75)+1.5*iqr;
        iqr=quantile(abs(dxdt),.75)-quantile(abs(dxdt),.25);
        spike_thres=quantile(abs(dxdt),.75);
        spike_fail=quantile(abs(dxdt),.75)+1.5*iqr;
        roc_thres=spike_fail;
    else
        clim_minsuspect=nan(size(depthcats,1),1);
        clim_maxsuspect=clim_minsuspect;
        spike_thres=clim_minsuspect;
        spike_fail=clim_minsuspect;
        roc_thres=clim_minsuspect;
        for n=1:size(depthcats,1)
            d0=depthcats(n,1);
            d1=depthcats(n,2);
            if(isnan(d0))
                d0=0;
            end
            if(isnan(d1))
                d1=max(depth)+1;
            end
            ind=find(depth>=d0&depth<d1);
            if(~isempty(ind))
                iqr=quantile(var(ind),.75)-quantile(var(ind),.25);
                clim_minsuspect(n)=quantile(var(ind),.25)-1.5*iqr;
                clim_maxsuspect(n)=quantile(var(ind),.75)+1.5*iqr;
            end
            ind=find(depthdiff>=d0&depthdiff<d1);
            if(~isempty(ind))
                iqr=quantile(abs(dxdt(ind)),.75)-quantile(abs(dxdt(ind)),.25);
                spike_thres(n)=quantile(abs(dxdt(ind)),.75);
                spike_fail(n)=quantile(abs(dxdt(ind)),.75)+1.5*iqr;
                roc_thres(n)=spike_fail;
            end
        end
    end
end


dgroup.timestampSensors=torig;
dgroup.depthSensors=dorig;
