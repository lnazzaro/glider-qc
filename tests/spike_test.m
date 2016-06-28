%% Spike Test

function [flag,thresholds]=spike_test(var,varargin)

% Checks data for single-data-point spikes.
%
% Checks whether data is within sensor limits defined by manufacturer
% (unless other limits are defined).
% 
% Outputs:
%     flag: vector the same size as var, with corresponding QARTOD flags
%         (1: pass, 2: not evaluated, 3: suspect, 4: fail, 9: no data)
%     thresholds: structured array describing thresholds used for test
%     
% Inputs:
%     var: 1-D vector with time-series glider data
%     varargin:
%         'spike_suspect': single-element maximum rate of change threshold
%             above which is flagged a suspect spike
%         'spike_fail': single-element maximum rate of change threshold
%             above which is a spike flagged as failing
%         'exclude_nans': logical indicating whether to exclude nan data
%             points from QC process (default: true)
%         'time': vector the same size as var including corresponding time
%             values (matlab time, or any day increments)
%         'time_gap': maximum amount of time (seconds) between data points
%             to count them as neighboring points (default: 300 = 5 min;
%             ignored if no time input)
%         'threshold_rate': rate of change units for the threshold
%             (default: persecond, or pertimestep if no time input)
%             options: persecond, pertimestep, perminute, perhour
%         'originalflag': vector the same size as var including flags already
%             in place; new flags will only be added where this is 2 or 9
%         'originalflag_replace': vector including flags in originalflag to
%             replace (default is 2 and 9; 1, 3, and 4 will not be changed)

caller = [mfilename '.m - Test 6: Spike Test'];

if nargin <2
    fprintf(2,...
        '%s E: not enough arguments.\n',...
        caller);
    return;
elseif ~isnumeric(var)
    fprintf(2,'%s E: First input must be numeric.\n',caller);
    return;
end


threshold_fail=nan;
threshold_suspect=nan;
flag=2*ones(size(var));
originalflag=flag;
originalflagempty=[2,9];
nonan=true;
times=nan*var;
consecutivetimes=5/60/24;
method='changepersecond';
depthvarying=false;
depthcats=nan;
conversion_factor=1;

if(iscell(varargin)&length(varargin)==1)
    varargin=varargin{1};
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    switch lower(name)
        case 'exclude_nans'
            if(~islogical(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be logical\n',caller,name);
                return;
            end
            nonan=value;
        case 'time'
            if(~isnumeric(value))
                fprintf(2,'%s E: Value for %s must be numeric\n',caller,name);
                return;
            end
            if(any(size(value)~=size(var)))
                fprintf(2,'%s E: Value for %s must be the same dimensions as the input variable data\n',caller,name);
                return;
            end
            times=value;
        case 'time_gap' % seconds
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a single element numeric\n',caller,name);
                return;
            end
            consecutivetimes=value/60/60/24;
        case 'spike_fail'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a numeric scalar\n',caller,name);
                return;
            end
            threshold_fail=value;
        case 'spike_suspect'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a numeric scalar\n',caller,name);
                return;
            end
            threshold_suspect=value;
        case 'threshold_rate'
            if(~ischar(value))
                fprintf(2,'%s E: Value for %s must be a string\n',caller,name);
                return;
            end
            if(strcmp(value,'persecond'))
                conversion_factor=1;
                method='changepersecond';
            elseif(strcmp(value,'perminute'))
                conversion_factor=1/60;
                method='changepersecond';
            elseif(strcmp(value,'perhour'))
                conversion_factor=1/60/60;
                method='changepersecond';
            elseif(strcmp(value,'pertimestep'))
                conversion_factor=1;
                method='changeperunit';
            else
                fprintf(2,'%s E: %s is not a recognized value for %s\n',caller,value,name);
                return;
            end
        case 'originalflag'
            if(~isnumeric(value))
                fprintf(2,'%s E: Value for %s must be numeric\n',caller,name);
                return;
            elseif(size(value)~=size(var))
                fprintf(2,'%s E: Value for %s must be the same size as test variable\n',caller,name);
                return;
            end
            originalflag=value;
        case 'originalflag_replace'
            if(~isnumeric(value))
                fprintf(2,'%s E: Value for %s must be numeric\n',caller,name);
                return;
            end
            originalflagempty=value;
        otherwise
            fprintf(2,...
                '%s E: Unknown option specified: %s\n',...
                caller,...
                name);
            return;
    end
end

if(~isnan(consecutivetimes)&all(isnan(times)))
    warning('No time values provided - ignoring defined time gap.');
end

if(all(isnan(times))&strcmp(method,'changepersecond'))
    warning('No time values provided - applying threshold to sampling resolution.');
    method='changeperunit';
    conversion_factor=1;
end

threshold_fail=threshold_fail*conversion_factor;
threshold_suspect=threshold_suspect*conversion_factor;

if(nonan)
    if(all(isnan(times)))
        inddata=find(~isnan(var));
    else
        inddata=find(~isnan(var)&~isnan(times));
    end
else
    inddata=1:length(var);
end

vardata=var(inddata);
timesdata=times(inddata);
flagdata=flag(inddata);

deltavar=diff(vardata);
deltatimes=diff(timesdata);

if(strcmp(method,'changepersecond'))
    delta=deltavar./(deltatimes*24*60*60);
elseif(strcmp(method,'changeperunit'))
    delta=deltavar;
end

ind=find(abs(delta)>=threshold_suspect);
indflag=find(diff(ind)==1);
for n=1:length(indflag)
    n1=ind(indflag(n));
    n2=ind(indflag(n)+1);
    if(delta(n1)/abs(delta(n1))==-delta(n2)/abs(delta(n2)))
        flagdata(n2)=3;
    end
end

ind=find(abs(delta)>=threshold_fail);
indflag=find(diff(ind)==1);
for n=1:length(indflag)
    n1=ind(indflag(n));
    n2=ind(indflag(n)+1);
    if(delta(n1)/abs(delta(n1))==-delta(n2)/abs(delta(n2)))
        flagdata(n2)=4;
    end
end

ind=find(deltatimes>=consecutivetimes);
flagdata(flagdata==2)=1;
flagdata(1)=2;
flagdata(end)=2;
flagdata(ind)=2;
flagdata(ind+1)=2;

flag(inddata)=flagdata;
flag(isnan(var))=9;

ind=find(~ismember(originalflag,originalflagempty)&~isnan(originalflag));
flag(ind)=originalflag(ind);

if(depthvarying)
    thresholds.depth_ranges=depthcats;
end
thresholds.suspect=threshold_suspect;
thresholds.fail=threshold_fail;
if(strcmp(method,'changepersecond'))
    thresholds.threshold_timestep='1 second';
elseif(strcmp(method,'changeperunit'))
    thresholds.threshold_timestep='sensor resolution';
end
