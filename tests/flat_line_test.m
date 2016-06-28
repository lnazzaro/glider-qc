%% Flat Line Test

function [flag,thresholds]=flat_line_test(var,varargin)

% Checks that data is not stuck at a single value for too long.
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
%         'zero_range': single-element data range to count as "no change in
%             data" (default: eps)
%         'exclude_nans': logical indicating whether to exclude nan data
%             points from QC process (default: true)
%         'suspect_count': integer indicating how many data points in a row
%             need to be within zero_range to be flagged as suspect
%             (default: 3)
%         'fail_count': integer indicating how many data points in a row
%             need to be within zero_range to be flagged as a fail
%             (default: 5)
%         'originalflag': vector the same size as var including flags already
%             in place; new flags will only be added where this is 2 or 9
%         'originalflag_replace': vector including flags in originalflag to
%             replace (default is 2 and 9; 1, 3, and 4 will not be changed)
%         'file': name of excel file containing manufacturer thresholds
%             - if using this option, varname and varunits must also be provided
%         'varname': string with name of variable as shown in either the
%             dbd group or the excel thresholds file
%         'varunits': string indicating the sensor units used in var
%         'spectype': string indicating type of manufacturer spec to use in
%             place of 'zero_range' (accuracy or resolution; default:
%             resolution)

caller = [mfilename '.m - Test 8: Flat Line Test'];

if nargin <0
    fprintf(2,...
        '%s E: not enough arguments.\n',...
        caller);
    return;
elseif ~isnumeric(var)
    fprintf(2,'%s E: First input must be numeric.\n',caller);
    return;
end


countas0=eps;
flag=2*ones(size(var));
originalflag=flag;
originalflagempty=[2,9];
nonan=true;
spectype='resolution';
fileinfo=[false false];
fail_num=5;
suspect_num=3;

if(iscell(varargin)&length(varargin)==1)
    varargin=varargin{1};
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    switch lower(name)
        case 'zero_range'
            if(~isnumeric(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be a single numeric\n',caller,name);
                return;
            end
            countas0=value;
        case 'suspect_count'
            if(length(value)~=1|~isnumeric(value)|mod(value,1)~=0|value<2)
                fprintf(2,'%s E: Value for %s must be a single-element integer >2\n',caller,name);
                return;
            end
            suspect_num=value;
        case 'fail_count'
            if(length(value)~=1|~isnumeric(value)|mod(value,1)~=0|value<2)
                fprintf(2,'%s E: Value for %s must be a single-element integer >2\n',caller,name);
                return;
            end
            fail_num=value;
        case 'varname'
            if(~ischar(value))
                fprintf(2,'%s E: Value for %s must be a string indicating the variable name\n',caller,name);
                return;
            end
            varstring=value;
            fileinfo(1)=true;
        case 'varunits'
            if(~ischar(value))
                fprintf(2,'%s E: Value for %s must be a string indicating the variable units\n',caller,name);
                return;
            end
            varunit=value;
            fileinfo(2)=true;
        case 'spectype'
            if(~ischar(value))
                fprintf(2,'%s E: Value for %s must be a string\n',caller,name);
                return;
            end
            if(~strcmp(lower(value),'resolution')&~strcmp(lower(value,'accuracy')))
                fprintf(2,'%s E: Value for %s must be either ''accuracy'' or ''resolution''\n',caller,name);
                return;
            end
            spectype=value;
        case 'exclude_nans'
            if(~islogical(value)|length(value)>1)
                fprintf(2,'%s E: Value for %s must be logical\n',caller,name);
                return;
            end
            nonan=value;
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
        case 'file'
        otherwise
            fprintf(2,...
                '%s E: Unknown option specified: %s\n',...
                caller,...
                name);
            return;
    end
end

for x=1:2:length(varargin)
    name=varargin{x};
    value=varargin{x+1};
    if(strcmp(lower(name),'file'))
        if(~all(fileinfo))
            fprintf(2,'%s E: Must provide variable name and units in order to read limits from file. Using %f as flat-line range.\n',caller,name,countas0);
            break;
        end
        if(~ischar(value)|~exist(value,'file'))
            fprintf(2,'%s E: Value for %s must be a valid file name. Using %f as flat-line range.\n',caller,name,countas0);
            break;
        end
        indext=find(value=='.');
        if(isempty(indext))
            fprintf(2,'%s E: Value for %s must be a valid file name. Using %f as flat-line range.\n',caller,name,countas0);
            break;
        end
        if(~strcmp(value(indext(end)+1:indext(end)+3),'xls'))
            fprintf(2,'%s E: %s must be an Excel spreadsheet. Using %f as flat-line range.\n',caller,name,countas0);
            break;
        end
        [~,~,limits]=xlsread(value);
        indunits=find(strcmp('units',limits(1,:)));
        found=false;
        for n=2:size(limits,1)
            indfield=strfind(varstring,limits{n,1});
            if(~isempty(indfield))
                if(strcmp(lower(limits{n,indunits}),lower(varunit)))
                    found=true;
                    break;
                end
            end
        end
        if(~found)
            fprintf(2,'%s E: Specs for %s not found in %s. Using %f as flat-line range.\n',caller,varstring,value,countas0);
            break;
        end
        ind=find(strcmp(spectype,limits(1,:)));
        countas0=limits{n,ind};
    end
end


if(nonan)
        inddata=find(~isnan(var));
else
    inddata=1:length(var);
end

vardata=var(inddata);
flagdata=flag(inddata);

if(length(vardata)<fail_num)
    warning('%s E: Must have at least %d valid data points for flat line test\n',caller,fail_num);
    flagdata(:)=2;
else

t_grid=nan(length(vardata),fail_num);
for n=1:fail_num
    t_grid(n:end,n)=vardata(1:end-(n-1));
end

minlim=min(t_grid(:,1:suspect_num),[],2);
maxlim=max(t_grid(:,1:suspect_num),[],2);
valrange=maxlim-minlim;
s=sum(t_grid(:,1:suspect_num),2);
flagdata(valrange<=countas0&~isnan(s))=3;

minlim=min(t_grid(:,1:fail_num),[],2);
maxlim=max(t_grid(:,1:fail_num),[],2);
valrange=maxlim-minlim;
s=sum(t_grid(:,1:fail_num),2);
flagdata(valrange<=countas0&~isnan(s))=4;

% t0=vardata;
% t1=nan(size(vardata));
% t1(2:end)=vardata(1:end-1);
% t2=nan(size(vardata));
% t2(3:end)=vardata(1:end-2);
% minlim=min(t0,t1);
% minlim=min(minlim,t2);
% maxlim=max(t0,t1);
% maxlim=max(maxlim,t2);
% valrange=maxlim-minlim;
% s=t0+t1+t2;
% flagdata(valrange<=countas0&~isnan(s))=3;
% 
% t3=nan(size(vardata));
% t3(4:end)=vardata(1:end-3);
% t4=nan(size(vardata));
% t4(5:end)=vardata(1:end-4);
% minlim=min(minlim,t3);
% minlim=min(minlim,t4);
% maxlim=max(maxlim,t3);
% maxlim=max(maxlim,t4);
% valrange=maxlim-minlim;
% s=s+t3+t4;
% flagdata(valrange<=countas0&~isnan(s))=4;

flagdata(flagdata==2)=1;
flagdata(1:fail_num-1)=2;
end

flag(inddata)=flagdata;
flag(isnan(var))=9;

ind=find(~ismember(originalflag,originalflagempty)&~isnan(originalflag));
flag(ind)=originalflag(ind);

thresholds.flat_line_range=countas0;
thresholds.fail_count=fail_num;
thresholds.suspect_count=suspect_num;

